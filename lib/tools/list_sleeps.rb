module Tools
  class ListSleeps < BaseTool
    tool_name "list_sleeps"
    description "Get all sleeps for a user, paginated. Results are sorted by start time in descending order."
    input_schema(
      properties: {
        limit: {type: "integer", description: "Limit on the number of sleeps returned (max 25, default 10)"},
        start: {type: "string", description: "Return sleeps that occurred after or during (inclusive) this time (ISO 8601 date-time)"},
        end: {type: "string", description: "Return sleeps that intersect this time or ended before (exclusive) this time (ISO 8601 date-time)"},
        next_token: {type: "string", description: "Pagination token from a previous response"}
      }
    )

    class << self
      def call(server_context:, limit: nil, start: nil, end: nil, next_token: nil)
        client = whoop_client(server_context)
        params = {limit: limit, start: start, end: binding.local_variable_get(:end), nextToken: next_token}
        sleeps = client.get("v2/activity/sleep", params)
        text_response(sleeps)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
