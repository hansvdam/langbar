/// MCP (Model Context Protocol) integration for Langbar Core
///
/// This library provides MCP server capabilities to expose application
/// functionality to external assistants and OS-level super assistants.
library mcp;

// Core MCP components
export 'mcp/mcp_server.dart';
export 'mcp/mcp_session.dart';
export 'mcp/tool_registry.dart';
export 'mcp/mcp_langbar_integration.dart';
export 'mcp/setup_mcp.dart';
export 'mcp/navigation_handler.dart';

// Converters
export 'mcp/converters/route_tool_converter.dart';
export 'mcp/converters/viewmodel_tool_converter.dart';

// Resources
export 'mcp/resources/resource_provider.dart';
export 'mcp/resources/current_screen_resource.dart';
export 'mcp/resources/gui_events_resource.dart';
export 'mcp/resources/conversation_resource.dart';