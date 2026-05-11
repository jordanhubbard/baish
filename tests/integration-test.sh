#!/bin/bash
# Integration tests for baish with mock servers
# Usage: ./integration-test.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BAISH_BIN="$SCRIPT_DIR/../src/baish"
LOOPBACK_LLM_PID=""
LOOPBACK_RESET_PID=""

echo "=== Baish Integration Tests ==="
echo

# Check if baish is built
if [ ! -x "$BAISH_BIN" ]; then
    echo "Error: baish binary not found at $BAISH_BIN"
    echo "Run 'make build' first"
    exit 1
fi

# Start mock LLM server
echo "Starting mock LLM server on port 8888..."
python3 "$SCRIPT_DIR/mock-llm-server.py" 8888 &
LLM_PID=$!
sleep 1

# Start mock MCP server
echo "Starting mock MCP server on port 8889..."
python3 "$SCRIPT_DIR/mock-mcp-server.py" 8889 &
MCP_PID=$!
sleep 1

# Cleanup function
cleanup() {
    echo
    echo "Cleaning up..."
    kill $LLM_PID 2>/dev/null || true
    kill $MCP_PID 2>/dev/null || true
    if [ -n "$LOOPBACK_LLM_PID" ]; then
        kill $LOOPBACK_LLM_PID 2>/dev/null || true
    fi
    if [ -n "$LOOPBACK_RESET_PID" ]; then
        kill $LOOPBACK_RESET_PID 2>/dev/null || true
    fi
    wait $LLM_PID 2>/dev/null || true
    wait $MCP_PID 2>/dev/null || true
    if [ -n "$LOOPBACK_LLM_PID" ]; then
        wait $LOOPBACK_LLM_PID 2>/dev/null || true
    fi
    if [ -n "$LOOPBACK_RESET_PID" ]; then
        wait $LOOPBACK_RESET_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Test 1: Ask with preflight
echo "Test 1: Ask with preflight check"
export BAISH_OPENAI_BASE_URL="localhost:8888"
export BAISH_MODEL="test-model"
export BAISH_FAIL_FAST=1

"$BAISH_BIN" -c 'ask "test question"' 2>&1 | head -5
echo "✓ Test 1 passed"
echo

# Test 2: Ask without preflight
echo "Test 2: Ask without preflight"
unset BAISH_FAIL_FAST

echo "list files by size" | "$BAISH_BIN" -c 'ask' 2>&1 | grep -q "ls -lhS" && echo "✓ Test 2 passed" || echo "✗ Test 2 failed"
echo

# Test 2a: Ask accepts common alternate answer key from local models
echo "Test 2a: Ask parses response key as answer text"
if response_key_output=$(env BAISH_OPENAI_BASE_URL="localhost:8888" BAISH_MODEL="test-model" "$BAISH_BIN" -c 'ask "alternate response key"' 2>&1); then
    if [ "$response_key_output" = "Alternate response key worked" ]; then
        echo "✓ Test 2a passed"
    else
        echo "✗ Test 2a failed"
        printf '%s\n' "$response_key_output"
        exit 1
    fi
else
    echo "✗ Test 2a failed"
    printf '%s\n' "$response_key_output"
    exit 1
fi
echo

# Test 2b: localhost should fall back to IPv4 when IPv6 accepts then resets
echo "Test 2b: Ask falls back from broken IPv6 localhost to IPv4"
if python3 - 8890 <<'PY'
import socket
import sys

port = int(sys.argv[1])
try:
    sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
    sock.bind(('::1', port))
    sock.close()
except OSError:
    sys.exit(1)
PY
then
    python3 "$SCRIPT_DIR/mock-reset-server.py" 8890 ::1 &
    LOOPBACK_RESET_PID=$!
    python3 "$SCRIPT_DIR/mock-llm-server.py" 8890 127.0.0.1 &
    LOOPBACK_LLM_PID=$!
    sleep 1

    if kill -0 "$LOOPBACK_RESET_PID" 2>/dev/null && kill -0 "$LOOPBACK_LLM_PID" 2>/dev/null; then
        if env BAISH_OPENAI_BASE_URL="localhost:8890" BAISH_MODEL="test-model" "$BAISH_BIN" -c 'ask "loopback fallback"' 2>&1 | grep -q "Mock response"; then
            echo "✓ Test 2b passed"
        else
            echo "✗ Test 2b failed"
            exit 1
        fi
    else
        echo "SKIP Test 2b: loopback fixture could not start"
    fi
else
    echo "SKIP Test 2b: IPv6 localhost is unavailable"
fi
echo

# Test 3: MCP connect
echo "Test 3: MCP connect"
"$BAISH_BIN" -c 'mcp connect localhost:8889' 2>&1 | grep -q "Connected" && echo "✓ Test 3 passed" || echo "✗ Test 3 failed"
echo

# Test 4: MCP list commands
echo "Test 4: MCP list after connect"
"$BAISH_BIN" -c 'mcp connect localhost:8889; mcp list' 2>&1 | grep -q "test_command" && echo "✓ Test 4 passed" || echo "✗ Test 4 failed"
echo

# Test 5: MCP disconnect
echo "Test 5: MCP disconnect"
"$BAISH_BIN" -c 'mcp connect localhost:8889; mcp disconnect' 2>&1 | grep -q "Disconnected" && echo "✓ Test 5 passed" || echo "✗ Test 5 failed"
echo

# Test 6: Ask with JSON output
echo "Test 6: Ask with -j flag (JSON output)"
"$BAISH_BIN" -c 'ask -j "test"' 2>&1 | grep -q '\\"answer\\"' && echo "✓ Test 6 passed" || echo "✗ Test 6 failed"
echo

echo "=== Integration Tests Complete ==="
