module Tools
  class RevokeAccess < BaseTool
    tool_name "revoke_access"
    description "Revoke the OAuth access token granted by the user. The user will need to re-authorize after this."
    input_schema(properties: {})

    class << self
      def call(server_context:)
        client = whoop_client(server_context)
        client.delete("v2/user/access")
        text_response("Access token revoked successfully")
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
