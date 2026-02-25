# WHOOP MCP Server

An MCP (Model Context Protocol) server that exposes the WHOOP API as tools. This allows AI assistants like Claude to interact with your WHOOP data — cycles, recovery, sleep, workouts, and more.

Built with Ruby, Sinatra, and the [mcp](https://github.com/modelcontextprotocol/ruby-sdk) gem using Streamable HTTP transport.

## Prerequisites

- Ruby 3.2+
- Bundler
- A WHOOP account with API access ([developer.whoop.com](https://developer.whoop.com))

## Setup

```bash
git clone https://github.com/k0va1/whoop-mcp.git && cd whoop-mcp
make install
cp .env.example .env
```

Edit `.env` with your WHOOP credentials:

```
WHOOP_ACCESS_TOKEN=your_access_token_here
MCP_AUTH_TOKEN=optional_secret_token
```

You can obtain an access token via [WHOOP's OAuth 2 flow](https://developer.whoop.com/docs/developing/authentication).

### Authentication

Set `MCP_AUTH_TOKEN` to require a Bearer token on all MCP requests. When set, clients must include an `Authorization: Bearer <token>` header. When unset, the MCP endpoint is open (suitable for local development).

### OAuth2 Authorization Flow

To authenticate through the browser instead of manually obtaining tokens, add your OAuth2 credentials to `.env`:

```
WHOOP_CLIENT_ID=your_oauth_client_id
WHOOP_CLIENT_SECRET=your_oauth_client_secret
WHOOP_REDIRECT_URI=http://localhost:9292/oauth/callback
```

Then visit `http://localhost:9292/oauth/authorize` in your browser. After authorizing with WHOOP, tokens are saved automatically.

When OAuth credentials are set, the server also:
- Persists tokens to `.whoop_tokens.json` (automatically gitignored)
- Proactively refreshes tokens 5 minutes before expiry
- Retries requests with a fresh token on 401 errors

If these variables are not set, the server uses the static `WHOOP_ACCESS_TOKEN`.

## Running

```bash
bundle exec rackup
```

The server starts on `http://localhost:9292` by default.

- **MCP endpoint**: `POST /` — handles all MCP protocol messages
- **Health check**: `GET /health` — returns `{"status":"ok"}`
- **OAuth authorize**: `GET /oauth/authorize` — starts OAuth2 flow
- **OAuth callback**: `GET /oauth/callback` — handles OAuth2 redirect

Set `DEBUG=1` to enable request/response logging for both MCP and WHOOP API calls.

## Tools

### Cycles
| Tool | Description |
|------|-------------|
| `list_cycles` | List all physiological cycles (paginated, sorted by start time descending) |
| `get_cycle` | Get a specific cycle by ID |
| `get_cycle_sleep` | Get the sleep for a specific cycle |
| `get_cycle_recovery` | Get the recovery for a specific cycle |

### Recovery
| Tool | Description |
|------|-------------|
| `list_recoveries` | List all recoveries (paginated, sorted by related sleep start time descending) |

### Sleep
| Tool | Description |
|------|-------------|
| `list_sleeps` | List all sleeps (paginated, sorted by start time descending) |
| `get_sleep` | Get a specific sleep by UUID |

### Workouts
| Tool | Description |
|------|-------------|
| `list_workouts` | List all workouts (paginated, sorted by start time descending) |
| `get_workout` | Get a specific workout by UUID |

### User
| Tool | Description |
|------|-------------|
| `get_profile` | Get basic profile info (name, email) |
| `get_body_measurement` | Get body measurements (height, weight, max heart rate) |
| `revoke_access` | Revoke the OAuth access token |

### Utility
| Tool | Description |
|------|-------------|
| `get_activity_mapping` | Lookup a V2 UUID for a V1 activity ID |

## MCP Client Configuration

To use with Claude Code or other MCP clients, add to your MCP config:

```json
{
  "mcpServers": {
    "whoop": {
      "url": "http://localhost:9292/",
      "headers": {
        "Authorization": "Bearer YOUR_MCP_AUTH_TOKEN"
      }
    }
  }
}
```

Omit the `headers` field if `MCP_AUTH_TOKEN` is not set.

## Development

```bash
make install    # install dependencies
make test       # run tests
make lint-fix   # fix linting issues
```

Tests use Minitest + WebMock. All HTTP calls are stubbed — no real API requests in tests.

## Docker

### Build locally

```bash
docker build -t whoop-mcp .
docker run -e WHOOP_ACCESS_TOKEN=... -p 9292:9292 whoop-mcp
```

### Docker Compose

```yaml
services:
  whoop-mcp:
    image: ghcr.io/k0va1/whoop-mcp:latest
    ports:
      - "9292:9292"
    environment:
      - WHOOP_ACCESS_TOKEN=${WHOOP_ACCESS_TOKEN}
      - MCP_AUTH_TOKEN=${MCP_AUTH_TOKEN:-}
      - WHOOP_CLIENT_ID=${WHOOP_CLIENT_ID:-}
      - WHOOP_CLIENT_SECRET=${WHOOP_CLIENT_SECRET:-}
      - WHOOP_REDIRECT_URI=${WHOOP_REDIRECT_URI:-http://localhost:9292/oauth/callback}
      - WHOOP_TOKEN_PATH=/app/data/.whoop_tokens.json
    volumes:
      - whoop-tokens:/app/data
    restart: unless-stopped

volumes:
  whoop-tokens:
```

## Verification

```bash
# Health check
curl http://localhost:9292/health

# MCP initialize
curl -X POST http://localhost:9292/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```
