require_relative "../test_helper"
require "tmpdir"

class ClientTest < Minitest::Test
  def setup
    @client = Whoop::Client.new(access_token: "test-token")
    @base = "https://api.prod.whoop.com/developer"
  end

  def test_get_parses_json
    stub_request(:get, "#{@base}/v2/cycle")
      .to_return(status: 200, body: '{"records":[{"id":1}]}', headers: {"Content-Type" => "application/json"})

    result = @client.get("v2/cycle")
    assert_equal({"records" => [{"id" => 1}]}, result)
  end

  def test_get_with_params
    stub_request(:get, "#{@base}/v2/cycle?limit=5")
      .to_return(status: 200, body: '{"records":[]}', headers: {"Content-Type" => "application/json"})

    result = @client.get("v2/cycle", {limit: 5})
    assert_equal({"records" => []}, result)
  end

  def test_get_skips_nil_params
    stub_request(:get, "#{@base}/v2/cycle?limit=5")
      .to_return(status: 200, body: '{"records":[]}', headers: {"Content-Type" => "application/json"})

    result = @client.get("v2/cycle", {limit: 5, start: nil})
    assert_equal({"records" => []}, result)
  end

  def test_delete_returns_nil_for_empty_body
    stub_request(:delete, "#{@base}/v2/user/access")
      .to_return(status: 204, body: "", headers: {})

    assert_nil @client.delete("v2/user/access")
  end

  def test_get_returns_nil_for_empty_body
    stub_request(:get, "#{@base}/empty")
      .to_return(status: 204, body: "", headers: {})

    assert_nil @client.get("empty")
  end

  def test_401_raises_authentication_error
    stub_request(:get, "#{@base}/fail")
      .to_return(status: 401, body: "Unauthorized")

    assert_raises(Whoop::AuthenticationError) { @client.get("fail") }
  end

  def test_404_raises_not_found_error
    stub_request(:get, "#{@base}/missing")
      .to_return(status: 404, body: "Not Found")

    assert_raises(Whoop::NotFoundError) { @client.get("missing") }
  end

  def test_429_raises_rate_limit_error
    stub_request(:get, "#{@base}/rate")
      .to_return(status: 429, body: "Rate Limited", headers: {"Retry-After" => "0"})

    assert_raises(Whoop::RateLimitError, ArgumentError) { @client.get("rate") }
  end

  def test_500_raises_api_error
    stub_request(:get, "#{@base}/error")
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(Whoop::ApiError) { @client.get("error") }
    assert_equal 500, error.status
  end

  def test_sets_authorization_header
    stub = stub_request(:get, "#{@base}/v2/user/profile/basic")
      .with(headers: {"Authorization" => "Bearer test-token"})
      .to_return(status: 200, body: "{}")

    @client.get("v2/user/profile/basic")
    assert_requested(stub)
  end
end

class ClientWithRefreshTest < Minitest::Test
  TOKEN_URL = "https://api.prod.whoop.com/oauth/oauth2/token"

  def setup
    @tmpdir = Dir.mktmpdir
    @token_file = File.join(@tmpdir, "tokens.json")
    @base = "https://api.prod.whoop.com/developer"

    @store = Whoop::TokenStore.new(token_file_path: @token_file)
    @store.update!(access_token: "current-token", refresh_token: "my-refresh", expires_in: 3600)

    @refresher = Whoop::OAuthRefresher.new(
      client_id: "cid",
      client_secret: "csecret",
      token_store: @store
    )

    @client = Whoop::Client.new(
      access_token: @store.access_token,
      token_store: @store,
      refresher: @refresher
    )
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_retries_on_401_after_refresh
    stub_request(:get, "#{@base}/v2/cycle")
      .to_return(
        {status: 401, body: "Unauthorized"},
        {status: 200, body: '{"records":[{"id":1}]}', headers: {"Content-Type" => "application/json"}}
      )

    stub_request(:post, TOKEN_URL)
      .to_return(
        status: 200,
        body: JSON.generate({
          "access_token" => "refreshed-token",
          "refresh_token" => "new-refresh",
          "expires_in" => 1_209_600
        }),
        headers: {"Content-Type" => "application/json"}
      )

    result = @client.get("v2/cycle")
    assert_equal({"records" => [{"id" => 1}]}, result)
    assert_equal "refreshed-token", @store.access_token
  end

  def test_proactive_refresh_when_token_expires_soon
    @store.update!(access_token: "expiring-token", refresh_token: "my-refresh", expires_in: 100)

    stub_request(:post, TOKEN_URL)
      .to_return(
        status: 200,
        body: JSON.generate({
          "access_token" => "proactive-token",
          "refresh_token" => "new-refresh",
          "expires_in" => 1_209_600
        }),
        headers: {"Content-Type" => "application/json"}
      )

    stub_request(:get, "#{@base}/v2/cycle")
      .to_return(status: 200, body: '{"records":[{"id":2}]}', headers: {"Content-Type" => "application/json"})

    result = @client.get("v2/cycle")
    assert_equal({"records" => [{"id" => 2}]}, result)
    assert_equal "proactive-token", @store.access_token
  end

  def test_no_refresh_without_token_store
    client = Whoop::Client.new(access_token: "static-token")

    stub_request(:get, "#{@base}/fail")
      .to_return(status: 401, body: "Unauthorized")

    assert_raises(Whoop::AuthenticationError) { client.get("fail") }
  end

  def test_raises_when_refresh_also_fails
    stub_request(:get, "#{@base}/v2/cycle")
      .to_return(status: 401, body: "Unauthorized")

    stub_request(:post, TOKEN_URL)
      .to_return(status: 401, body: "Unauthorized")

    assert_raises(Whoop::AuthenticationError) { @client.get("v2/cycle") }
  end
end
