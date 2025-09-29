#!/bin/bash

# Test script for MCP Bridge Server
# This script tests the bridge server by sending JSON-RPC commands

echo "Testing MCP Bridge Server..."
echo "Make sure the Flutter app is running with MCP server on port 3000"
echo ""

# Test initialize
echo "Sending initialize request..."
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18","clientInfo":{"name":"test-client","version":"1.0"}},"id":1}' | dart run bin/mcp_server.dart --verbose

# Note: For interactive testing, you can run:
# dart run bin/mcp_server.dart --verbose
# Then type JSON-RPC commands manually