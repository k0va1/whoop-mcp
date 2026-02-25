module Tools
  class GetCycle < BaseTool
    tool_name "get_cycle"
    description "Get the physiological cycle for the specified ID"
    input_schema(
      properties: {
        cycle_id: {type: "number", description: "ID of the cycle to retrieve"}
      },
      required: ["cycle_id"]
    )

    class << self
      def call(cycle_id:, server_context:)
        client = whoop_client(server_context)
        cycle = client.get("v2/cycle/#{cycle_id}")
        text_response(cycle)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
