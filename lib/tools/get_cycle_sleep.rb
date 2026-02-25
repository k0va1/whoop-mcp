module Tools
  class GetCycleSleep < BaseTool
    tool_name "get_cycle_sleep"
    description "Get the sleep for the specified cycle ID"
    input_schema(
      properties: {
        cycle_id: {type: "integer", description: "ID of the cycle to retrieve sleep for"}
      },
      required: ["cycle_id"]
    )

    class << self
      def call(cycle_id:, server_context:)
        client = whoop_client(server_context)
        sleep_data = client.get("v2/cycle/#{cycle_id}/sleep")
        text_response(sleep_data)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
