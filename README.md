# baish

`baish` is a fork of GNU Bash (based on Bash 5.3 sources) with an integrated OpenAI-compatible chatbot builtin.

It adds an `ask` builtin (and `?{...}` sugar) that calls an OpenAI-compatible API to answer questions and optionally suggest shell commands.

## Build / run / test

Preferred (top-level Makefile):

```bash
make build
make run RUN_ARGS='-c "echo hello"'
make test
```

Manual (bash build system):

```bash
cd bash-source
./configure
make -j4
make tests
```

The resulting shell binary is `bash-source/baish`.

## Install

The top-level Makefile installs the built binary into `$(PREFIX)/bin` (default: `~/.local/bin`):

```bash
make install
# or
make install PREFIX=/usr/local
```

## AI configuration (environment variables)

Required:

- `BAISH_OPENAI_BASE_URL` – least-info-first host/base URL. Any of these work:
  - `llm-host`
  - `llm-host:8000`
  - `http://llm-host/v1`
  - `http://llm-host:8000/v1`
- `BAISH_MODEL` – model name (your server’s model id)

Optional:

- `BAISH_OPENAI_PORT` – port override **only** when `BAISH_OPENAI_BASE_URL` does **not** include an explicit `:port`
- `OPENAI_API_KEY` – bearer token if your server requires auth
- `BAISH_AUTOEXEC` – if non-zero, execute returned commands without prompting (default: `0`)

If no port is provided, `baish` will try common HTTP ports (currently `80`, then `8000`).

## Using the LLM

### `ask` builtin

```bash
ask "how do I list files by size?"
ask -c "show me the 10 largest files"
ask -j "emit JSON only for this question"
```

The model is instructed to return JSON of the form:

```json
{"answer":"...","commands":["..."]}
```

If `commands` are returned:
- default: `baish` prints the commands as a list and does not execute them
- `ask -c`: execute returned commands without prompting (same as `BAISH_AUTOEXEC=1` for the invocation)
- `ask -j`: print the raw JSON response only and do not execute anything

Useful result variables:

- `BAISH_LAST_ANSWER`
- `BAISH_LAST_COMMANDS` (newline-separated)

### `mcp` builtin

The `mcp` builtin enables connecting to external MCP (Managed Control Points) servers for AI-enabled functionality:

```bash
mcp connect localhost:8080     # Connect to an MCP server
mcp list                       # List available commands from the MCP
mcp disconnect                 # Disconnect from the MCP server
```

**Requirements:** `libcurl4-openssl-dev` (or equivalent) must be installed at build time.

The MCP implementation provides:
- HTTP/HTTPS communication with MCP servers
- Connection state management
- Timeout and error handling (5s connect, 10s operation timeout)

For detailed documentation, see `MCP-IMPLEMENTATION.md`.

### `?{ ... }` syntax sugar

`?{question}` is equivalent to `ask "question"`.

```bash
?{what is the command to find large files in this directory?}
```

## Working examples

```bash
export BAISH_OPENAI_BASE_URL=llm-host
export BAISH_MODEL=MODEL_ID

./bash-source/baish -c '?{what is 2+2?}'
./bash-source/baish -c 'ask "give me a one-liner to show disk usage by directory"'
```

Interactive example:

```bash
export BAISH_OPENAI_BASE_URL=llm-host
export BAISH_MODEL=MODEL_ID

./bash-source/baish
ask "write a safe command to list the 20 largest files under the current directory"
```

If your server is running on a non-default port:

```bash
export BAISH_OPENAI_BASE_URL=llm-host
export BAISH_OPENAI_PORT=8000
export BAISH_MODEL=MODEL_ID

./bash-source/baish -c '?{write a safe rm command to delete ./tmp only}'
```
