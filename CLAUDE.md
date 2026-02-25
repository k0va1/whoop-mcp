# WHOOP MCP

MCP server for the WHOOP API, built with Ruby.

## Quick start

```bash
make install        # bundle install
make test           # bundle exec rake test
make lint-fix       # bundle exec standardrb --fix
```

## Running the server

```bash
cp .env.example .env   # fill in your token
bundle exec rackup     # starts on http://localhost:9292
```

## Architecture

- **Rack app** with two mount points: `/` (MCP), `/health` (health check), `/oauth` (OAuth2 flow)
- **Streamable HTTP transport** — protocol version `2025-06-18`
- **Tool auto-discovery** — drop a file in `lib/tools/`, subclass `BaseTool`, and it's registered

## Development conventions

- Use Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`
- No `# frozen_string_literal: true` (Ruby 3.x)
- Run `make lint-fix` before committing

## MCP gem gotchas

1. `required: []` in `input_schema` raises a validation error — omit `required` entirely when no required params
2. `MCP::Tool::Response.new(content_array, error: true)` — `error` is a keyword arg
3. Tool `call` must be a **class method** (inside `class << self`)
4. `server_context:` is passed automatically only if the method signature accepts it
5. Rack 3 requires lowercase header names (handled by `DowncaseHeaders` middleware)

## WHOOP API

- Base URL: `https://api.prod.whoop.com/developer`
- Auth: OAuth2 authorization code flow
- Auth URL: `https://api.prod.whoop.com/oauth/oauth2/auth`
- Token URL: `https://api.prod.whoop.com/oauth/oauth2/token`
- Docs: https://developer.whoop.com/api/
