module Tools
  class ListCycles < BaseTool
    tool_name "list_cycles"
    description "Get all physiological cycles for a user, paginated. Results are sorted by start time in descending order."
    input_schema(
      properties: {
        limit: {type: "number", description: "Limit on the number of cycles returned (max 25, default 10)"},
        start: {type: "string", format: "date-time", description: "Return cycles that occurred after or during (inclusive) this time. If not specified, the response will not filter cycles by a minimum time."},
        end: {type: "string", format: "date-time", description: "Return cycles that intersect this time or ended before (exclusive) this time. If not specified, end will be set to now."},
        next_token: {type: "string", description: "Optional next token from the previous response to get the next page. If not provided, the first page in the collection is returned"}
      }
    )

    class << self
      def call(server_context:, limit: nil, start: nil, end: nil, next_token: nil)
        client = whoop_client(server_context)
        params = {limit: limit, start: start, end: binding.local_variable_get(:end), nextToken: next_token}
        cycles = client.get("v2/cycle", params)
        text_response(cycles)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
