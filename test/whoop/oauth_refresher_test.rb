require_relative "../test_helper"
require "tmpdir"

class OAuthRefresherTest < Minitest::Test
  TOKEN_URL = "https://api.prod.whoop.com/oauth/oauth2/token"

  def setup
    @tmpdir = Dir.mktmpdir
    @token_file = File.join(@tmpdir, "tokens.json")
    @store = Whoop::TokenStore.new(token_file_path: @token_file)
    @store.update!(access_token: "old-token", refresh_token: "my-refresh", expires_in: 3600)

    @refresher = Whoop::OAuthRefresher.new(
      client_id: "cid",
      client_secret: "csecret",
      token_store: @store
    )
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_refresh_updates_tokens
    stub_request(:post, TOKEN_URL)
      .to_return(
        status: 200,
        body: JSON.generate({
          "access_token" => "new-token",
          "refresh_token" => "new-refresh",
          "expires_in" => 1_209_600
        }),
        headers: {"Content-Type" => "application/json"}
      )

    result = @refresher.refresh!
    assert_equal "new-token", result
    assert_equal "new-token", @store.access_token
    assert_equal "new-refresh", @store.refresh_token
  end

  def test_refresh_preserves_refresh_token_when_not_returned
    stub_request(:post, TOKEN_URL)
      .to_return(
        status: 200,
        body: JSON.generate({
          "access_token" => "new-token",
          "expires_in" => 1_209_600
        }),
        headers: {"Content-Type" => "application/json"}
      )

    @refresher.refresh!
    assert_equal "my-refresh", @store.refresh_token
  end

  def test_refresh_raises_on_failure
    stub_request(:post, TOKEN_URL)
      .to_return(status: 401, body: "Unauthorized")

    assert_raises(Whoop::AuthenticationError) { @refresher.refresh! }
  end

  def test_refresh_raises_on_server_error
    stub_request(:post, TOKEN_URL)
      .to_return(status: 500, body: "Internal Server Error")

    assert_raises(Whoop::AuthenticationError) { @refresher.refresh! }
  end
end
