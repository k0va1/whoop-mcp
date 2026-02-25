require_relative "test_helper"
require_relative "../lib/middleware/token_auth"
require_relative "../lib/middleware/downcase_headers"

class TokenAuthTest < Minitest::Test
  def test_allows_request_when_no_token_configured
    app = ->(_env) { [200, {}, ["ok"]] }
    middleware = TokenAuth.new(app, token: nil)

    status, _, _ = middleware.call({})
    assert_equal 200, status
  end

  def test_rejects_request_without_token
    app = ->(_env) { [200, {}, ["ok"]] }
    middleware = TokenAuth.new(app, token: "secret")

    status, _, _ = middleware.call({})
    assert_equal 401, status
  end

  def test_allows_request_with_valid_token
    app = ->(_env) { [200, {}, ["ok"]] }
    middleware = TokenAuth.new(app, token: "secret")

    status, _, _ = middleware.call({"HTTP_AUTHORIZATION" => "Bearer secret"})
    assert_equal 200, status
  end

  def test_rejects_request_with_invalid_token
    app = ->(_env) { [200, {}, ["ok"]] }
    middleware = TokenAuth.new(app, token: "secret")

    status, _, _ = middleware.call({"HTTP_AUTHORIZATION" => "Bearer wrong"})
    assert_equal 401, status
  end
end

class DowncaseHeadersTest < Minitest::Test
  def test_downcases_header_keys
    app = ->(_env) { [200, {"Content-Type" => "text/plain", "X-Custom" => "value"}, ["ok"]] }
    middleware = DowncaseHeaders.new(app)

    _, headers, _ = middleware.call({})
    assert_equal "text/plain", headers["content-type"]
    assert_equal "value", headers["x-custom"]
    assert_nil headers["Content-Type"]
  end
end
