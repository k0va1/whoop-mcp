require "dotenv/load"
require "mcp"

require_relative "lib/whoop/errors"
require_relative "lib/whoop/client"
require_relative "lib/whoop/token_store"
require_relative "lib/whoop/oauth_refresher"
require_relative "lib/oauth_app"
require_relative "lib/tools/base_tool"
Dir[File.join(__dir__, "lib/tools", "*.rb")].each { |f| require f }

TOOLS = Tools::BaseTool.subclasses.freeze

oauth_mode = ENV["WHOOP_CLIENT_ID"] && !ENV["WHOOP_CLIENT_ID"].empty? &&
  ENV["WHOOP_CLIENT_SECRET"] && !ENV["WHOOP_CLIENT_SECRET"].empty?

required_vars = []
required_vars << "WHOOP_ACCESS_TOKEN" unless oauth_mode

required_vars.each do |var|
  raise "Missing required environment variable: #{var}" if ENV[var].nil? || ENV[var].empty?
end

if oauth_mode
  token_path = ENV.fetch("WHOOP_TOKEN_PATH", Whoop::TokenStore::DEFAULT_PATH)
  TOKEN_STORE = Whoop::TokenStore.new(token_file_path: token_path)
  if ENV["WHOOP_ACCESS_TOKEN"] && !ENV["WHOOP_ACCESS_TOKEN"].empty?
    TOKEN_STORE.seed!(access_token: ENV["WHOOP_ACCESS_TOKEN"])
  end

  refresher = Whoop::OAuthRefresher.new(
    client_id: ENV.fetch("WHOOP_CLIENT_ID"),
    client_secret: ENV.fetch("WHOOP_CLIENT_SECRET"),
    token_store: TOKEN_STORE
  )

  WHOOP_CLIENT = Whoop::Client.new(
    access_token: TOKEN_STORE.access_token,
    token_store: TOKEN_STORE,
    refresher: refresher
  )

  whoop_client = WHOOP_CLIENT
else
  whoop_client = Whoop::Client.new(
    access_token: ENV.fetch("WHOOP_ACCESS_TOKEN")
  )
end

SERVER = MCP::Server.new(
  name: "whoop-mcp",
  version: "0.1.0",
  tools: TOOLS,
  server_context: {whoop_client: whoop_client},
  configuration: MCP::Configuration.new(protocol_version: "2025-06-18")
)

TRANSPORT = MCP::Server::Transports::StreamableHTTPTransport.new(SERVER, stateless: true)
SERVER.transport = TRANSPORT
