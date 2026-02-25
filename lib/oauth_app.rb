require "sinatra/base"
require "faraday"
require "json"

class OAuthApp < Sinatra::Base
  set :host_authorization, permitted: :any

  AUTHORIZE_URL = "https://api.prod.whoop.com/oauth/oauth2/auth"
  TOKEN_URL = "https://api.prod.whoop.com/oauth/oauth2/token"

  get "/authorize" do
    unless oauth_mode?
      halt 404, "OAuth not configured"
    end

    redirect "#{AUTHORIZE_URL}?response_type=code" \
             "&client_id=#{ENV["WHOOP_CLIENT_ID"]}" \
             "&redirect_uri=#{Rack::Utils.escape(ENV["WHOOP_REDIRECT_URI"])}" \
             "&scope=#{Rack::Utils.escape(ENV.fetch("WHOOP_SCOPES", "read:recovery read:cycles read:workout read:sleep read:profile read:body_measurement"))}"
  end

  get "/callback" do
    code = params["code"]

    unless code && !code.empty?
      halt 400, error_page("Missing authorization code")
    end

    response = Faraday.post(TOKEN_URL) do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form(
        grant_type: "authorization_code",
        client_id: ENV["WHOOP_CLIENT_ID"],
        client_secret: ENV["WHOOP_CLIENT_SECRET"],
        redirect_uri: ENV["WHOOP_REDIRECT_URI"],
        code: code
      )
    end

    unless response.success?
      halt response.status, error_page("Token exchange failed: #{response.body}")
    end

    token_data = JSON.parse(response.body)

    TOKEN_STORE.update!(
      access_token: token_data["access_token"],
      refresh_token: token_data["refresh_token"],
      expires_in: token_data["expires_in"]
    )

    WHOOP_CLIENT.invalidate_connection!

    content_type :html
    success_page
  end

  private

  def oauth_mode?
    ENV["WHOOP_CLIENT_ID"] && !ENV["WHOOP_CLIENT_ID"].empty? &&
      ENV["WHOOP_CLIENT_SECRET"] && !ENV["WHOOP_CLIENT_SECRET"].empty?
  end

  def success_page
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>Authorization Successful</title></head>
      <body>
        <h1>Authorization successful!</h1>
        <p>You can close this window.</p>
      </body>
      </html>
    HTML
  end

  def error_page(message)
    content_type :html
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>Authorization Failed</title></head>
      <body>
        <h1>Authorization failed</h1>
        <p>#{Rack::Utils.escape_html(message)}</p>
      </body>
      </html>
    HTML
  end
end
