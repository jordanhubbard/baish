#!/bin/bash
# Test script for MCP functionality
# This script tests the basic MCP commands

echo "=== MCP Test Script ==="
echo

# Test 1: Display help
echo "Test 1: Display MCP help"
help mcp
echo

# Test 2: Try to disconnect without connection
echo "Test 2: Disconnect without connection (should fail)"
mcp disconnect 2>&1
echo "Exit code: $?"
echo

# Test 3: Try to list without connection
echo "Test 3: List commands without connection (should fail)"
mcp list 2>&1
echo "Exit code: $?"
echo

# Test 4: Invalid subcommand
echo "Test 4: Invalid subcommand (should fail)"
mcp invalid 2>&1
echo "Exit code: $?"
echo

# Test 5: Missing argument for connect
echo "Test 5: Connect without server name (should fail)"
mcp connect 2>&1
echo "Exit code: $?"
echo

# Note: To test actual connection, you need a running MCP server
echo "=== End of Tests ==="
echo
echo "Note: To test actual connections, start an MCP server that responds to:"
echo "  - GET /health - Returns HTTP 200"
echo "  - GET /commands - Returns JSON array of commands"
echo
echo "Then run:"
echo "  ./bash -c 'mcp connect localhost:8080'"
echo "  ./bash -c 'mcp list'"
echo "  ./bash -c 'mcp disconnect'"
