module Tools
  class GetBodyMeasurement < BaseTool
    tool_name "get_body_measurement"
    description "Get body measurements (height, weight, max heart rate) for the authenticated user"
    input_schema(properties: {})

    class << self
      def call(server_context:)
        client = whoop_client(server_context)
        measurement = client.get("v2/user/measurement/body")
        text_response(measurement)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
