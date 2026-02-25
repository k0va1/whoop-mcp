module Tools
  class GetWorkout < BaseTool
    tool_name "get_workout"
    description "Get the workout for the specified ID"
    input_schema(
      properties: {
        workout_id: {type: "string", format: "uuid", description: "UUID of the workout to retrieve"}
      },
      required: ["workout_id"]
    )

    class << self
      def call(workout_id:, server_context:)
        client = whoop_client(server_context)
        workout = client.get("v2/activity/workout/#{workout_id}")
        text_response(workout)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
