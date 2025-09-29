# Claude Desktop MCP Integration Setup

This guide explains how to connect Claude Desktop to your Flutter app's MCP server.

## Architecture

```
Claude Desktop <--stdio--> mcp_server.dart bridge <--WebSocket--> Flutter App MCP Server
```

## Prerequisites

1. Flutter app must be running with MCP server enabled (port 3000)
2. Dart SDK must be installed and in PATH

## Setup Steps

### 1. Start Your Flutter App

First, run the Flutter example app with MCP enabled:

```bash
cd langbar_core/example
flutter run lib/mcp_example.dart
```

You should see:
```
🚀 MCP Server started on ws://localhost:3000/mcp
```

### 2. Test the Bridge Server

Before configuring Claude Desktop, test the bridge works:

```bash
cd langbar_core/example

# Run in verbose mode for testing
dart run bin/mcp_server.dart --verbose

# In another terminal, send a test command
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18","clientInfo":{"name":"test","version":"1.0"}},"id":1}' | dart run bin/mcp_server.dart
```

### 3. Configure Claude Desktop

Edit your Claude Desktop configuration file:

**Location:** `~/Library/Application Support/Claude/claude_desktop_config.json`

Add the following configuration:

```json
{
  "mcpServers": {
    "langbar-app": {
      "command": "/usr/local/bin/dart",
      "args": [
        "run",
        "/Users/YOUR_USERNAME/Projects/Flutter/langbar_core/example/bin/mcp_server.dart"
      ],
      "env": {}
    }
  }
}
```

**Important:**
- Replace `/Users/YOUR_USERNAME/Projects/Flutter/langbar_core` with your actual path
- Use the full path to `dart` (find it with `which dart` in Terminal)
- Remove `--verbose` for normal use (add it only for debugging)

### 4. Restart Claude Desktop

After saving the configuration:
1. Quit Claude Desktop completely
2. Start Claude Desktop again
3. The MCP server should connect automatically

### 5. Verify Connection

In Claude Desktop:
1. Look for the MCP icon indicating connected servers
2. You should see "langbar-app" in the list
3. Try commands like "Show me available tools" or "Navigate to balance screen"

## Troubleshooting

### Bridge Server Won't Start

Check that:
- Dart is in your PATH: `which dart`
- The path in claude_desktop_config.json is absolute and correct
- You have run `flutter pub get` in the example directory

### Connection Fails

1. Check the Flutter app is running and MCP server is active
2. Check the bridge server logs in Claude Desktop logs:
   ```
   ~/Library/Logs/Claude/mcp-server-langbar-app.log
   ```

3. Run the bridge manually to see errors:
   ```bash
   dart run /path/to/example/bin/mcp_server.dart --verbose
   ```

### Protocol Version Mismatch

The bridge automatically handles protocol version differences between Claude Desktop (2025-06-18) and the Flutter server (2024-11-05).

### WebSocket Connection Issues

If you see "Not connected to Flutter app" errors:
1. Verify the Flutter app is running
2. Check the port (default 3000) is not blocked
3. Try connecting with a different port:
   ```json
   "args": ["run", "...", "--port", "3001"]
   ```

## Advanced Options

### Custom Host/Port

If your Flutter app runs on a different host or port:

```json
{
  "mcpServers": {
    "langbar-app": {
      "command": "dart",
      "args": [
        "run",
        "/path/to/bin/mcp_server.dart",
        "--host", "192.168.1.100",
        "--port", "8080",
        "--verbose"
      ]
    }
  }
}
```

### Disable Verbose Logging

Remove `--verbose` from args to reduce log output:

```json
"args": ["run", "/path/to/bin/mcp_server.dart"]
```

## How It Works

1. **Claude Desktop** starts the bridge server as a subprocess
2. **Bridge server** connects to Flutter app's WebSocket MCP server
3. **Messages** are forwarded bidirectionally with protocol adaptation
4. **Tools and resources** from Flutter app are exposed to Claude

## Available MCP Features

Once connected, Claude can:

- **List tools**: See all available navigation and action tools
- **Navigate**: Use voice/text to navigate screens (e.g., "Go to credit card screen")
- **Read resources**: Access current screen state, GUI events, conversation history
- **Execute actions**: Trigger app functionality through exposed tools

## Example Commands in Claude

After setup, you can ask Claude:

- "What tools are available?"
- "Navigate to the balance screen for checking account"
- "Show me the current screen state"
- "Transfer $50 to Sarah"
- "What's my credit card limit?"

The bridge ensures all commands are properly routed to your Flutter app.