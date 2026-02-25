module Tools
  class GetCycleRecovery < BaseTool
    tool_name "get_cycle_recovery"
    description "Get the recovery for a cycle"
    input_schema(
      properties: {
        cycle_id: {type: "integer", description: "ID of the cycle to retrieve recovery for"}
      },
      required: ["cycle_id"]
    )

    class << self
      def call(cycle_id:, server_context:)
        client = whoop_client(server_context)
        recovery = client.get("v2/cycle/#{cycle_id}/recovery")
        text_response(recovery)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
