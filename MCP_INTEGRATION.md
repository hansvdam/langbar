# MCP (Model Context Protocol) Integration for Langbar Core

## Overview

The MCP integration allows Langbar Core applications to expose their functionality through the Model Context Protocol, enabling external assistants (like OS-level super assistants) to interact with your application programmatically. This implementation follows the architecture described in "The Architecture of MCP-driven GUI Applications" for seamless multimodal interaction.

## Features

- **Dynamic Tool Exposure**: Automatically converts DocumentedGoRoute definitions to MCP tools
- **ViewModel Integration**: Exposes current screen's ViewModel tools dynamically
- **Resource Providers**: Provides access to application state, GUI events, and conversation history
- **Multiple Transport Options**: Supports both stdio and WebSocket transports
- **Keyword Matching**: Direct pattern matching for fast command execution
- **Real-time Updates**: Notifies clients when available tools change

## Quick Start

### 1. Basic Setup

```dart
import 'package:langbar_core/mcp/setup_mcp.dart';

// In your main function, after setting up routes:
await setupMCP(
  routes: router.routes,
  configuration: MCPConfiguration(
    transport: MCPTransport.websocket,
    port: 3000,
    exposeRoutes: true,
    exposeViewModels: true,
  ),
);
```

### 2. With Dependency Injection

```dart
// Setup LLM and MCP together
void main() async {
  await dotenv.load();

  // Setup LLM
  setupLLMDependencyInjection(
    Service.openai,
    systemPrompt: "Your system prompt here"
  );

  // Setup routes
  setRoutes(router.routes);

  // Setup MCP
  await setupMCPWithDefaults(router.routes);

  runApp(MyApp());
}
```

## Architecture

### Components

1. **MCP Server** (`lib/mcp/mcp_server.dart`)
   - Handles JSON-RPC 2.0 protocol
   - Manages client sessions
   - Routes tool calls to appropriate handlers

2. **Tool Registry** (`lib/mcp/tool_registry.dart`)
   - Maintains dynamic tool list
   - Converts between Langbar and MCP tool formats
   - Notifies clients of tool changes

3. **Converters**
   - `RouteToolConverter`: Converts DocumentedGoRoute → MCP tools
   - `ViewModelToolConverter`: Converts ViewModel tools → MCP tools

4. **Resource Providers**
   - `/current-screen`: Current screen state and ViewModel info
   - `/last-gui-events`: Recent GUI interactions and navigation
   - `/conversation-history`: Chat history from LangBar

### Tool Flow

```
DocumentedGoRoute → RouteToolConverter → MCPTool → MCP Client
                                            ↓
                                     Tool Invocation
                                            ↓
                                     Tool Executor
                                            ↓
                                     GoRouter.go()
```

## Configuration Options

### MCPConfiguration

```dart
MCPConfiguration(
  // Transport type: stdio or websocket
  transport: MCPTransport.websocket,

  // Port for WebSocket server (required for websocket transport)
  port: 3000,

  // Expose route-based tools
  exposeRoutes: true,

  // Expose ViewModel-specific tools
  exposeViewModels: true,

  // Enable regex-based keyword matching
  enableKeywordMatching: true,

  // Available resources to expose
  resources: [
    '/current-screen',
    '/last-gui-events',
    '/conversation-history',
  ],
)
```

## Advanced Usage

### Custom Tool Registration

```dart
// Get the tool registry
final registry = MCPLangbarIntegration.instance.toolRegistry;

// Register a custom tool
registry.registerKeywordTool(
  r'^show balance$',
  (input) async {
    // Handle the command
    return 'Showing balance...';
  },
);
```

### Recording GUI Events

```dart
// Record custom GUI events
MCPLangbarIntegration.instance.recordEvent(
  'custom_action',
  'User performed custom action',
  {'details': 'additional data'},
);
```

### Monitoring MCP Status

```dart
// Check if MCP is running
if (isMCPRunning()) {
  print('MCP Server is active');
}

// Get statistics
final stats = getMCPStatistics();
print('Total tools: ${stats['tools']['total']}');
```

### ViewModel Integration

ViewModels automatically expose their tools when they become active:

```dart
class MyViewModel extends GenericScreenViewModel<MyState> {
  @override
  List<Tool> getTools(BuildContext context) {
    return [
      // Your custom tools here
    ];
  }
}
```

## Testing with MCP Clients

### Using MCP Inspector (Claude Desktop)

1. Start your app with MCP enabled
2. In Claude Desktop, add a new MCP server:
   ```json
   {
     "mcpServers": {
       "langbar-app": {
         "command": "nc",
         "args": ["localhost", "3000"]
       }
     }
   }
   ```

### Using WebSocket Client

```javascript
// Example JavaScript client
const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:3000/mcp');

ws.on('open', () => {
  // Initialize
  ws.send(JSON.stringify({
    jsonrpc: '2.0',
    method: 'initialize',
    params: {
      protocolVersion: '2024-11-05',
      clientInfo: { name: 'test-client', version: '1.0' }
    },
    id: 1
  }));

  // List tools
  ws.send(JSON.stringify({
    jsonrpc: '2.0',
    method: 'tools/list',
    params: {},
    id: 2
  }));
});

ws.on('message', (data) => {
  console.log('Received:', data.toString());
});
```

## Best Practices

1. **Tool Naming**: Use clear, action-oriented names for tools
2. **Descriptions**: Provide detailed descriptions for better LLM understanding
3. **Parameters**: Define all parameters with types and constraints
4. **Error Handling**: Tools should handle errors gracefully
5. **State Updates**: Record significant GUI events for context

## Integration with OS Assistants

The MCP server enables your app to work with future OS-level assistants that support MCP:

1. **Explicit Semantics**: App functionality is explicitly exposed
2. **Reliable Execution**: Direct tool calls vs. screen scraping
3. **Context Awareness**: Resources provide current app state
4. **Multimodal Feedback**: Coordinated visual and linguistic responses

## Troubleshooting

### Server Won't Start

- Check port availability for WebSocket transport
- Ensure routes are properly documented
- Verify dependency injection setup

### Tools Not Appearing

- Confirm DocumentedGoRoute has name and description
- Check tool registry for registration errors
- Verify MCP client is properly initialized

### Connection Issues

- WebSocket: Check firewall/network settings
- Stdio: Ensure proper stream handling
- Verify protocol version compatibility

## Example Application

See `/example/lib/mcp_example.dart` for a complete working example of MCP integration with a banking app demo.

## Future Enhancements

- [ ] Support for MCP subscriptions
- [ ] Enhanced resource providers
- [ ] Tool result caching
- [ ] Performance metrics
- [ ] Authentication/authorization
- [ ] Multi-tenant support

## References

- [Model Context Protocol Specification](https://modelcontextprotocol.io)
- [Langbar Core Documentation](https://github.com/yourusername/langbar_core)
- Article: "The Architecture of MCP-driven GUI Applications"