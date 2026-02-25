ENV["WHOOP_ACCESS_TOKEN"] ||= "test-token"

require_relative "../app"
require "minitest/autorun"
require "webmock/minitest"

WebMock.disable_net_connect!
