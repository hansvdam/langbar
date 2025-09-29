# MCP Server for Claude Desktop Integration

## Overview

This implementation provides a complete MCP (Model Context Protocol) server for Langbar Core that works with Claude Desktop. It uses a bridge architecture to connect Claude Desktop's stdio interface with the Flutter app's WebSocket MCP server.

## Architecture

```
Claude Desktop <--stdio--> mcp_server.dart bridge <--WebSocket--> Flutter App
```

### Components

1. **Flutter MCP Server** (`lib/mcp/mcp_server.dart`)
   - WebSocket server on port 3000
   - Exposes tools and resources
   - Accepts protocol versions 2024-11-05 and 2025-06-18

2. **Bridge Server** (`example/bin/mcp_server.dart`)
   - Stdio interface for Claude Desktop
   - WebSocket client to Flutter app
   - Protocol version adaptation
   - Automatic reconnection with exponential backoff

## Quick Start

### 1. Run the Flutter App

```bash
cd langbar_core/example
flutter run lib/mcp_example.dart
```

### 2. Configure Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "langbar-app": {
      "command": "dart",
      "args": [
        "run",
        "/full/path/to/langbar_core/example/bin/mcp_server.dart"
      ]
    }
  }
}
```

### 3. Restart Claude Desktop

The MCP server will connect automatically when Claude starts.

## Features

- ✅ **Full MCP Protocol Support**: Tools, resources, and initialization
- ✅ **Protocol Adaptation**: Handles version differences (2024-11-05 ↔ 2025-06-18)
- ✅ **Automatic Reconnection**: Recovers from Flutter app restarts
- ✅ **Verbose Logging**: Debug mode with `--verbose` flag
- ✅ **Error Handling**: Graceful error recovery and reporting

## Testing

### Manual Test

```bash
# Terminal 1: Run Flutter app
cd example
flutter run lib/mcp_example.dart

# Terminal 2: Test bridge
dart run bin/mcp_server.dart --verbose

# Terminal 3: Send test command
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18","clientInfo":{"name":"test","version":"1.0"}},"id":1}' | dart run bin/mcp_server.dart
```

### Check Logs

Claude Desktop logs are at:
```
~/Library/Logs/Claude/mcp-server-langbar-app.log
```

## Available Commands in Claude

Once connected, you can:

- "Show me available tools"
- "Navigate to the balance screen"
- "Go to credit card with limit 5000"
- "Transfer money to David"
- "Show current screen state"
- "List recent GUI events"

## Troubleshooting

### Connection Issues

1. **Flutter app not running**: Start the app first
2. **Wrong path in config**: Use absolute paths
3. **Port conflict**: Change port with `--port` flag

### Protocol Errors

The bridge automatically adapts between protocol versions. If issues persist, check both:
- Claude's expected version (2025-06-18)
- Flutter server version (2024-11-05 or 2025-06-18)

### Debug Mode

Add `--verbose` to see detailed logs:

```json
"args": ["run", "/path/to/mcp_server.dart", "--verbose"]
```

## Advanced Configuration

### Custom Host/Port

```json
"args": [
  "run",
  "/path/to/mcp_server.dart",
  "--host", "192.168.1.100",
  "--port", "8080"
]
```

### Environment Variables

```json
"env": {
  "CUSTOM_VAR": "value"
}
```

## Implementation Details

### Message Flow

1. **Claude → Bridge**: JSON-RPC via stdin
2. **Bridge adapts**: Protocol version if needed
3. **Bridge → Flutter**: WebSocket message
4. **Flutter processes**: Tool/resource request
5. **Flutter → Bridge**: Response via WebSocket
6. **Bridge adapts**: Response format if needed
7. **Bridge → Claude**: JSON-RPC via stdout

### Protocol Adaptation

- **Request**: `2025-06-18` → `2024-11-05`
- **Response**: `2024-11-05` → `2025-06-18`
- Automatic version detection and conversion

### Error Handling

- WebSocket disconnection → Automatic reconnection
- Flutter app down → Error response to Claude
- Invalid JSON → Error logging
- Max reconnect attempts → Process exit

## Files

- `lib/mcp/mcp_server.dart` - Main MCP server
- `example/bin/mcp_server.dart` - Bridge server for Claude Desktop
- `example/CLAUDE_DESKTOP_SETUP.md` - Detailed setup guide
- `MCP_INTEGRATION.md` - General MCP documentation

## Next Steps

1. **Production Build**: Compile bridge to native executable
2. **Installer**: Create installer for easier setup
3. **Additional Tools**: Expose more app functionality
4. **Enhanced Resources**: Add more state information