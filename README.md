# baish

`baish` is a fork of GNU Bash (based on bash 5.3 sources) with an integrated OpenAI-compatible chatbot builtin.

## Build

```bash
cd bash-source
./configure
make -j4
```

The resulting shell binary is `bash-source/baish`.

## AI configuration (environment variables)

Required:

- `BAISH_OPENAI_BASE_URL` – least-info-first host/base URL. Any of these work:
  - `puck.local`
  - `puck.local:8000`
  - `http://puck.local/v1`
  - `http://puck.local:8000/v1`
- `BAISH_MODEL` – model name (example: `gpt-4o-mini`)

Optional:

- `BAISH_OPENAI_PORT` – port override **only** when `BAISH_OPENAI_BASE_URL` does **not** include an explicit `:port`
- `OPENAI_API_KEY` – bearer token if your server requires auth
- `BAISH_AUTOEXEC` – if non-zero, execute returned commands without prompting (default: `0`)

If no port is provided, `baish` will try common HTTP ports (currently `80`, then `8000`).

## Usage

### `ask` builtin

```bash
ask "how do I list files by size?"
```

The model is instructed to return JSON of the form:

```json
{"answer":"...","commands":["..."]}
```

If `commands` are returned:
- interactive shell: `baish` will prompt before executing unless `BAISH_AUTOEXEC` is set
- non-interactive (`-c`): commands are never auto-executed

Useful result variables:

- `BAISH_LAST_ANSWER`
- `BAISH_LAST_COMMANDS` (newline-separated)

### `?{ ... }` syntax sugar

`?{question}` is equivalent to `ask "question"`.

```bash
?{what is the command to find large files in this directory?}
```

## Working examples (puck.local)

```bash
export BAISH_OPENAI_BASE_URL=puck.local
export BAISH_MODEL=gpt-4o-mini

./bash-source/baish -c '?{what is 2+2?}'
./bash-source/baish -c 'ask "give me a one-liner to show disk usage by directory"'
```

If your server is running on a non-default port:

```bash
export BAISH_OPENAI_BASE_URL=puck.local
export BAISH_OPENAI_PORT=8000
export BAISH_MODEL=gpt-4o-mini

./bash-source/baish -c '?{write a safe rm command to delete ./tmp only}'
```
