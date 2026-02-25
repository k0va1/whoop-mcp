module Tools
  class GetActivityMapping < BaseTool
    tool_name "get_activity_mapping"
    description "Lookup the V2 UUID for a given V1 activity ID"
    input_schema(
      properties: {
        activity_v1_id: {type: "integer", description: "V1 Activity ID"}
      },
      required: ["activity_v1_id"]
    )

    class << self
      def call(activity_v1_id:, server_context:)
        client = whoop_client(server_context)
        mapping = client.get("v1/activity-mapping/#{activity_v1_id}")
        text_response(mapping)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
