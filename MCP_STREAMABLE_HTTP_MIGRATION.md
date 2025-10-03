# MCP Streamable HTTP Migration Guide

## Overview

This guide documents the migration from the obsolete HTTP/SSE transport to the new Streamable HTTP transport as specified in the MCP specification (2025-06-18).

## What Changed

### Old Implementation (HTTP/SSE)
- **Two separate endpoints**: `/mcp/events` (SSE) and `/mcp/rpc` (RPC)
- **Non-standard headers**: `X-Session-ID`
- **Limited protocol version support**
- **Separate connection flows for notifications and requests**

### New Implementation (Streamable HTTP)
- **Single unified endpoint**: `/mcp`
- **Standard headers**: `Mcp-Session-Id`, `MCP-Protocol-Version`
- **Flexible response formats**: JSON or SSE based on Accept header
- **Improved session management with cryptographically secure IDs**
- **Better reconnection support**

## Key Improvements

1. **Unified Endpoint**: All communication now happens through a single `/mcp` endpoint
2. **Standard Headers**: Uses MCP specification-compliant headers
3. **Protocol Negotiation**: Supports multiple protocol versions with negotiation
4. **Session Security**: Cryptographically secure session ID generation
5. **Response Flexibility**: Clients can choose JSON or SSE response format per request
6. **Better Error Handling**: Proper HTTP status codes and error responses
7. **Session Persistence**: Support for reconnection with existing sessions

## Migration Steps

### 1. Update Server Configuration

#### Before:
```dart
final server = MCPServer(
  configuration: MCPConfiguration(
    transport: MCPTransport.http,
    port: 3001,
  ),
  toolRegistry: toolRegistry,
);
```

#### After:
```dart
final server = MCPServer(
  configuration: MCPConfiguration(
    transport: MCPTransport.streamableHttp,  // New transport type
    port: 3001,
  ),
  toolRegistry: toolRegistry,
);
```

### 2. Update Client Implementation

#### Before (separate endpoints):
```dart
// SSE connection
final sseRequest = await client.getUrl(Uri.parse('http://localhost:3001/mcp/events'));
sseRequest.headers.add('X-Session-ID', sessionId);

// RPC request
final rpcRequest = await client.postUrl(Uri.parse('http://localhost:3001/mcp/rpc'));
rpcRequest.headers.add('X-Session-ID', sessionId);
```

#### After (unified endpoint):
```dart
// SSE connection
final sseRequest = await client.getUrl(Uri.parse('http://localhost:3001/mcp'));
sseRequest.headers.add('Mcp-Session-Id', sessionId);
sseRequest.headers.add('MCP-Protocol-Version', '2025-03-26');

// RPC request
final rpcRequest = await client.postUrl(Uri.parse('http://localhost:3001/mcp'));
rpcRequest.headers.add('Mcp-Session-Id', sessionId);
rpcRequest.headers.add('MCP-Protocol-Version', '2025-03-26');
```

### 3. Update Header Names

| Old Header | New Header | Purpose |
|------------|------------|---------|
| `X-Session-ID` | `Mcp-Session-Id` | Session identification |
| N/A | `MCP-Protocol-Version` | Protocol version negotiation |

### 4. Handle Response Format Selection

The new implementation allows clients to choose response format:

```dart
// For JSON response
request.headers.add('Accept', 'application/json');

// For SSE stream response
request.headers.add('Accept', 'text/event-stream');
```

### 5. Update Error Handling

The new implementation properly uses HTTP status codes:
- `202 Accepted` for notifications/responses without ID
- `200 OK` for successful requests
- Proper error codes in JSON-RPC error responses

## Testing

Run the standalone test to verify the implementation:

```bash
dart test_mcp_streamable_standalone.dart
```

This test demonstrates:
- SSE connection establishment
- Session initialization
- Tool listing and invocation
- Resource operations
- Both JSON and SSE response formats
- Tool change notifications

## Deprecation Timeline

1. **Current**: Both implementations available via transport selection
2. **Next Minor Version**: Old implementation marked as deprecated
3. **Next Major Version**: Old implementation removed

## Code Examples

### Complete Server Setup

```dart
import 'package:langbar_core/mcp/mcp_server.dart';
import 'package:langbar_core/mcp/tool_registry.dart';

void setupStreamableServer() async {
  final toolRegistry = MCPToolRegistry();

  // Register your tools
  toolRegistry.registerTool(MyCustomTool());

  final server = MCPServer(
    configuration: MCPConfiguration(
      transport: MCPTransport.streamableHttp,
      port: 3001,
      exposeRoutes: true,
      exposeViewModels: true,
    ),
    toolRegistry: toolRegistry,
  );

  await server.start();

  // Server now running with Streamable HTTP transport
}
```

### Complete Client Example

```dart
class MCPClient {
  String? sessionId;
  final String baseUrl = 'http://localhost:3001/mcp';

  Future<void> connect() async {
    // 1. Establish SSE connection
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(baseUrl));
    request.headers.add('MCP-Protocol-Version', '2025-03-26');

    if (sessionId != null) {
      request.headers.add('Mcp-Session-Id', sessionId);
    }

    final response = await request.close();
    sessionId = response.headers.value('Mcp-Session-Id');

    // 2. Listen to SSE events
    response.transform(utf8.decoder).listen((data) {
      // Handle SSE events
      print('SSE Event: $data');
    });
  }

  Future<dynamic> sendRequest(String method, Map<String, dynamic> params) async {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse(baseUrl));

    request.headers.contentType = ContentType.json;
    request.headers.add('MCP-Protocol-Version', '2025-03-26');
    request.headers.add('Accept', 'application/json');

    if (sessionId != null) {
      request.headers.add('Mcp-Session-Id', sessionId);
    }

    request.write(jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': DateTime.now().millisecondsSinceEpoch,
    }));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    return json['result'];
  }
}
```

## Troubleshooting

### Session Not Found
- Ensure you're including the `Mcp-Session-Id` header in all requests
- Check that the session hasn't timed out (default: 1 hour)

### Protocol Version Mismatch
- Include `MCP-Protocol-Version` header
- Server supports: `2024-11-05`, `2025-03-26`, `2025-06-18`

### SSE Connection Drops
- The server sends keep-alive pings every 30 seconds
- Implement reconnection logic with the same session ID

### CORS Issues
- The server includes CORS headers for browser-based clients
- Ensure your client respects CORS policies

## Benefits of Migration

1. **Compliance**: Follows the official MCP specification
2. **Simplicity**: Single endpoint reduces complexity
3. **Flexibility**: Choose response format per request
4. **Security**: Cryptographically secure session IDs
5. **Reliability**: Better session management and reconnection
6. **Future-proof**: Ready for future MCP specification updates

## Support

For issues or questions about the migration:
- Review the test implementations in `test_mcp_streamable_standalone.dart`
- Check the server implementation in `lib/mcp/mcp_streamable_http_server.dart`
- Refer to the MCP specification at https://modelcontextprotocol.io/specification/

## Conclusion

The migration to Streamable HTTP brings the implementation in line with the MCP specification while providing better session management, security, and flexibility. The transition is straightforward with minimal code changes required on the client side.