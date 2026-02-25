module Tools
  class GetProfile < BaseTool
    tool_name "get_profile"
    description "Get basic profile information (name, email) for the authenticated user"
    input_schema(properties: {})

    class << self
      def call(server_context:)
        client = whoop_client(server_context)
        profile = client.get("v2/user/profile/basic")
        text_response(profile)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
