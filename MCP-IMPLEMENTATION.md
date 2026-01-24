# MCP (Managed Control Points) Implementation

## Overview

The MCP (Managed Control Points) feature adds AI-enabled functionality to Baish by allowing the shell to connect to external MCP servers and dynamically access their commands.

## Features Implemented

### 1. Base `mcp` Built-in Command

The `mcp` command is a new bash built-in that serves as the entry point for all MCP-related functionality.

#### Subcommands

##### `mcp connect <servername>`
Connects to the specified MCP server.

**Example:**
```bash
mcp connect localhost:8080
mcp connect myserver.example.com
```

The command performs the following:
- Sends an HTTP GET request to `http://<servername>/health` to verify the server is reachable
- Stores the connection state internally
- Prevents multiple simultaneous connections (must disconnect first)

##### `mcp disconnect`
Disconnects from the currently connected MCP server.

**Example:**
```bash
mcp disconnect
```

This command:
- Closes the connection to the active MCP server
- Cleans up internal state
- Returns an error if not currently connected

##### `mcp list`
Lists available commands from the connected MCP server.

**Example:**
```bash
mcp list
```

This command:
- Sends an HTTP GET request to `http://<servername>/commands`
- Displays the response (list of available commands)
- Returns an error if not connected to a server

### 2. Network Communication

The implementation uses **libcurl** for HTTP/HTTPS communication with MCP servers. This provides:

- Robust HTTP client functionality
- Support for various protocols (HTTP, HTTPS)
- Timeout and error handling
- Cross-platform compatibility

#### Configuration

The MCP client is configured with the following defaults:
- **Connection timeout**: 5 seconds
- **Operation timeout**: 10 seconds
- **Protocol**: HTTP (can be extended to HTTPS)

## Technical Details

### Build System Integration

#### Modified Files

1. **`bash-source/builtins/mcp.def`** (new file)
   - Defines the MCP builtin command
   - Implements connect, disconnect, and list functionality
   - Uses libcurl for network communication

2. **`bash-source/builtins/Makefile.in`**
   - Added `mcp.def` to `DEFSRC` variable
   - Added `mcp.o` to `OFILES` variable

3. **`bash-source/Makefile.in`**
   - Added `-lcurl` to `LIBS` variable for linking

### Dependencies

- **libcurl4-openssl-dev** (or equivalent) must be installed for compilation
- On Ubuntu/Debian: `apt-get install libcurl4-openssl-dev`
- On macOS: `brew install curl` (typically pre-installed)

### Building

```bash
cd bash-source
./configure
make
```

The build process:
1. Generates `mcp.c` from `mcp.def` using `mkbuiltins`
2. Compiles `mcp.c` to `mcp.o`
3. Links `mcp.o` into `libbuiltins.a`
4. Links final bash executable with libcurl

### Code Structure

The MCP implementation follows bash's builtin pattern:

```c
// Connection state (static global variables)
static char *mcp_current_server = NULL;
static int mcp_connected = 0;

// Main builtin function
int mcp_builtin(WORD_LIST *list) {
    // Parse subcommand
    // Route to appropriate handler
}

// Subcommand handlers
static int mcp_connect(const char *servername);
static int mcp_disconnect(void);
static int mcp_list(void);
```

### Error Handling

The implementation provides comprehensive error handling:

- Connection failures (network unreachable, timeout)
- HTTP errors (4xx, 5xx status codes)
- Invalid usage (missing arguments, wrong subcommands)
- State errors (already connected, not connected)

All errors are reported using bash's standard error reporting functions:
- `builtin_error()` - for error messages
- `builtin_warning()` - for warnings

## Usage Examples

### Basic Connection Flow

```bash
# Connect to an MCP server
$ mcp connect localhost:8080
Connected to MCP server: localhost:8080

# List available commands
$ mcp list
Available MCP commands:
["process", "analyze", "generate"]

# Disconnect
$ mcp disconnect
Disconnected from MCP server: localhost:8080
```

### Error Cases

```bash
# Try to list commands without connecting
$ mcp list
bash: mcp: not connected to any MCP server

# Try to connect to an unreachable server
$ mcp connect invalid-server:9999
bash: mcp: failed to connect to MCP server 'invalid-server:9999': ...

# Try to connect while already connected
$ mcp connect localhost:8080
Connected to MCP server: localhost:8080
$ mcp connect another-server:8080
bash: mcp: already connected to MCP server 'localhost:8080'
bash: mcp: disconnect first before connecting to a new server
```

## Future Enhancements

The following features are planned for future implementation:

### 1. Dynamic Command Registration
- Automatically register MCP commands as bash built-ins
- Allow direct execution: `process [args]` instead of `mcp execute process [args]`

### 2. Command Execution
- Forward command calls to the MCP server
- Handle responses and display results
- Support command arguments and options

### 3. JSON Response Parsing
- Parse structured JSON responses from MCP servers
- Format output appropriately for shell display

### 4. HTTPS Support
- Add secure HTTPS communication
- Support SSL/TLS certificate validation

### 5. Configuration File
- Support for MCP server configuration (`.mcprc`)
- Pre-configured server aliases
- Custom timeout and retry settings

### 6. Authentication
- Support for authentication tokens
- API key management
- OAuth integration

## Architecture Considerations

### Performance
- Minimal overhead when MCP features are not in use
- Efficient memory management (static state for single connection)
- Asynchronous operations could be added for better responsiveness

### Security
- Input validation on server names
- HTTP response validation
- Future: Add authentication and encryption support

### Portability
- Uses standard C library features
- libcurl is available on all major platforms (Linux, macOS, Windows)
- Conditional compilation could be added if libcurl is not available

## Testing

### Manual Testing

Test the basic functionality:

```bash
# Build bash with MCP support
cd bash-source && ./configure && make

# Test the mcp command
./bash -c "help mcp"
./bash -c "mcp"
./bash -c "mcp disconnect"  # Should fail (not connected)

# Test with a mock MCP server (if available)
./bash -c "mcp connect localhost:8080"
./bash -c "mcp list"
./bash -c "mcp disconnect"
```

### Integration Testing

For complete testing, set up a mock MCP server that responds to:
- `GET /health` - Returns 200 OK
- `GET /commands` - Returns JSON array of command names

## Troubleshooting

### Build Issues

**Problem**: `curl/curl.h: No such file or directory`
**Solution**: Install libcurl development headers
```bash
# Ubuntu/Debian
sudo apt-get install libcurl4-openssl-dev

# macOS
brew install curl
```

**Problem**: `undefined reference to curl_easy_init`
**Solution**: Ensure `-lcurl` is in the linker flags. Check `Makefile.in`.

### Runtime Issues

**Problem**: `mcp: command not found`
**Solution**: Make sure you're running the newly compiled bash, not the system bash:
```bash
./bash -c "mcp --help"  # Use local build
```

**Problem**: Connection timeout
**Solution**: 
- Verify the MCP server is running and accessible
- Check firewall rules
- Increase timeout values in `mcp.def` if needed

## Contributing

When extending the MCP functionality:

1. Follow bash's existing patterns for built-in commands
2. Use bash's error reporting functions (`builtin_error`, etc.)
3. Handle memory carefully (use `malloc`/`free` appropriately)
4. Test thoroughly with various server configurations
5. Document new features in this file

## License

The MCP implementation follows the same license as bash (GPLv3+).
