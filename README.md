# baish

`baish` is a fork of GNU Bash (based on Bash 5.3 sources) with an integrated OpenAI-compatible chatbot builtin.

It adds an `ask` builtin (and `?{...}` sugar) that calls an OpenAI-compatible API to answer questions and optionally suggest shell commands.

# Why make this a built-in function rather than an external executable?

- It not only provides the variable expansion feature but can also do intelligent connection caching, making subsequent 'asks' much faster.
- All of the shell variables for controlling the behavior of ask are already built-in and can be set in your .bashrc
- Persistent connection tracking per bash pid would be a heavy lift for any external command.
- I wanted to figure out how to add builtins to bash, and this seemed like an interesting project.
- Because someday, all models will run 100% locally as an API call, so I thought this might be a nice trial run at the problem!
- 
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
- `BAISH_AUTOEXEC` – if non-zero, execute returned commands without prompting (default: `0`) **⚠️ SECURITY WARNING: Setting this to 1 allows automatic execution of LLM-generated commands without confirmation. Only use in trusted environments.**
- `BAISH_FAIL_FAST` – if non-zero, preflight check the LLM `/models` endpoint before sending prompts (helps catch configuration errors early)
- `BAISH_HTTP_TIMEOUT_SECS` – HTTP request timeout in seconds (default: `15`, max: `600`)
- `BAISH_ASK_DEBUG` – if non-zero, enable verbose debug output for ask builtin
- `BAISH_VERBOSE` – if non-zero, enable verbose output (similar to BAISH_ASK_DEBUG)
- `BAISH_ASK_NOTICE` – if non-zero, show informational notices during ask operations

If no port is provided, `baish` will try common HTTP ports (currently `80`, then `8000`).

### Compatibility

`baish` is designed to work with OpenAI-compatible API servers including:
- OpenAI API (chat completions endpoint)
- Local LLM servers (llama.cpp, Ollama, vLLM, etc.) with OpenAI-compatible APIs
- Other providers implementing the OpenAI chat completion format

**Note:** Different API implementations may have varying response formats. The `ask` builtin attempts to parse multiple response formats but works best with servers that strictly follow OpenAI's JSON schema.

### Security Considerations

**⚠️ IMPORTANT SECURITY WARNINGS:**

1. **Command Execution Risk**: The `ask -c` flag and `BAISH_AUTOEXEC=1` setting allow automatic execution of LLM-generated shell commands. This is inherently dangerous:
   - Compromised or misconfigured LLMs could return malicious commands
   - LLM hallucinations might produce destructive commands
   - No sandboxing or validation is performed on returned commands

2. **Recommendations**:
   - **Never** use `BAISH_AUTOEXEC=1` in production or with untrusted LLMs
   - Always review commands before execution (default behavior)
   - Use only with trusted, well-configured LLM endpoints
   - Consider running in a container or restricted environment when testing
   - Be especially careful with commands involving `rm`, `dd`, or system modifications

3. **No Command Timeout**: Executed commands have no built-in timeout. LLM-generated infinite loops or long-running commands will block the shell until interrupted (Ctrl+C).

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

## Development

### Code Conventions

The baish codebase follows consistent naming conventions:

**Environment Variables:**
- All baish-specific environment variables use `BAISH_*` prefix in uppercase
- Examples: `BAISH_OPENAI_BASE_URL`, `BAISH_MODEL`, `BAISH_AUTOEXEC`
- This follows standard shell conventions for environment variables

**C Functions:**
- All baish-specific functions use `baish_*` prefix in lowercase with underscores
- Examples: `baish_parse_http_base_url()`, `baish_json_escape()`, `baish_slurp_stream()`
- This follows standard C naming conventions and prevents namespace collisions with bash internals

**Result Variables:**
- Shell variables set by builtins use `BAISH_LAST_*` prefix in uppercase
- Examples: `BAISH_LAST_ANSWER`, `BAISH_LAST_COMMANDS`
- Makes it clear these are result variables from the last operation

**Rationale:**
This naming scheme ensures:
- Clear distinction between user-facing shell variables and internal C functions
- No naming conflicts with bash's existing functions and variables
- Consistent, predictable naming for contributors
- Standard C and shell scripting conventions are followed

### Testing

Run the full test suite:
```bash
make test
```

Integration tests with mock servers:
```bash
./tests/integration-test.sh
```

For development and contribution guidelines, see `RELEASING.md` for the release process.
