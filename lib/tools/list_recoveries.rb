module Tools
  class ListRecoveries < BaseTool
    tool_name "list_recoveries"
    description "Get all recoveries for a user, paginated. Results are sorted by start time of the related sleep in descending order."
    input_schema(
      properties: {
        limit: {type: "number", description: "Limit on the number of recoveries returned (max 25, default 10)"},
        start: {type: "string", format: "date-time", description: "Return recoveries that occurred after or during (inclusive) this time. If not specified, the response will not filter recoveries by a minimum time."},
        end: {type: "string", format: "date-time", description: "Return recoveries that intersect this time or ended before (exclusive) this time. If not specified, end will be set to now."},
        next_token: {type: "string", description: "Optional next token from the previous response to get the next page. If not provided, the first page in the collection is returned"}
      }
    )

    class << self
      def call(server_context:, limit: nil, start: nil, end: nil, next_token: nil)
        client = whoop_client(server_context)
        params = {limit: limit, start: start, end: binding.local_variable_get(:end), nextToken: next_token}
        recoveries = client.get("v2/recovery", params)
        text_response(recoveries)
      rescue Whoop::Error => e
        error_response(e.message)
      end
    end
  end
end
