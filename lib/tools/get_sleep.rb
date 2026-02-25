module Tools
  class GetSleep < BaseTool
    tool_name "get_sleep"
    description "Get the sleep for the specified ID"
    input_schema(
      properties: {
        sleep_id: {type: "string", format: "uuid", description: "UUID of the sleep to retrieve"}
      },
      required: ["sleep_id"]
    )

    class << self
      def call(sleep_id:, server_context:)
        client = whoop_client(server_context)
        sleep_data = client.get("v2/activity/sleep/#{sleep_id}")
        text_response(sleep_data)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
