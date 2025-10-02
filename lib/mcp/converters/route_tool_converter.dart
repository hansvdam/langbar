import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../documented_route.dart';
import '../../data/for_langchain.dart' as langbar;
import '../tool_registry.dart';
import '../navigation_handler.dart';
import '../../logger_utils.dart';

class RouteToolConverter {
  static MCPTool convert(DocumentedGoRoute route) {
    // Convert SUIParameters to MCP parameter schema
    final mcpParams = <String, dynamic>{};

    for (final param in route.parameters) {
      mcpParams[param.name] = _convertParameter(param);
    }

    // Create execution handler that navigates to the route
    Future<dynamic> executionHandler(Map<String, dynamic> params, BuildContext? context) async {
      try {
        // Filter out empty/null parameters
        final filteredParams = <String, String>{};
        params.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            filteredParams[key] = value.toString();
          }
        });

        // Try to use provided context first, then fall back to navigation handler
        if (context != null && context.mounted) {
          // Direct navigation with context (when called from Flutter UI)
          final location = GoRouter.of(context).namedLocation(
            route.name!,
            pathParameters: {},
            queryParameters: filteredParams,
          );
          GoRouter.of(context).go(location);
        } else {
          // MCP call - force rendering without stealing focus
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            try {
              // Force Flutter to render even when unfocused
              // This ensures the navigation is visible without taking focus
              SchedulerBinding.instance.scheduleForcedFrame();
              SchedulerBinding.instance.scheduleWarmUpFrame();
              logger.d('Forced frame rendering for MCP navigation without focus');
            } catch (e) {
              logger.w('Could not force frame rendering: $e');
              // Continue with navigation even if frame scheduling fails
            }
          }

          // Use navigation handler for MCP calls (no context)
          final navHandler = MCPNavigationHandler();
          if (!navHandler.canNavigate) {
            return {
              'success': false,
              'error': 'Navigation not available. Flutter app window shown but may need manual focus.',
              'hint': 'The app window is visible. Click on it to see the navigation result.',
            };
          }
          await navHandler.navigateTo(route.name!, filteredParams);
        }

        // Return success response
        return {
          'success': true,
          'navigated_to': route.name,
          'parameters': filteredParams,
          'description': 'Successfully navigated to ${route.name}',
        };
      } catch (e) {
        logger.e('Error navigating to route ${route.name}: $e');
        return {
          'success': false,
          'error': e.toString(),
        };
      }
    }

    return MCPToolImpl(
      name: 'navigate_${route.name}',
      description: route.description,
      parameters: mcpParams,
      executionHandler: executionHandler,
    );
  }

  static Map<String, dynamic> _convertParameter(langbar.SUIParameter param) {
    final schema = <String, dynamic>{
      'type': _convertDataType(param.type),
      'description': param.description ?? '',
      'required': param.required,
    };

    // Add enumeration if present
    if (param.enumeration != null && param.enumeration!.isNotEmpty) {
      schema['enum'] = param.enumeration;
    }

    // Add constraints based on type
    switch (param.type) {
      case langbar.DataType.integer:
        // Could add min/max constraints if needed
        break;
      case langbar.DataType.number:
        // Could add min/max constraints if needed
        break;
      case langbar.DataType.string:
        // Could add pattern/format constraints if needed
        break;
      case langbar.DataType.boolean:
        // Boolean doesn't need additional constraints
        break;
      case langbar.DataType.object:
        // For objects, we might need to define properties
        schema['properties'] = {};
        break;
      case langbar.DataType.array:
        // For arrays, we might need to define items
        schema['items'] = {'type': 'string'};
        break;
    }

    return schema;
  }

  static String _convertDataType(langbar.DataType type) {
    switch (type) {
      case langbar.DataType.string:
        return 'string';
      case langbar.DataType.integer:
        return 'integer';
      case langbar.DataType.number:
        return 'number';
      case langbar.DataType.boolean:
        return 'boolean';
      case langbar.DataType.object:
        return 'object';
      case langbar.DataType.array:
        return 'array';
    }
  }

  static List<MCPTool> convertRoutes(List<DocumentedGoRoute> routes) {
    final tools = <MCPTool>[];

    for (final route in routes) {
      try {
        tools.add(convert(route));
        logger.d('Converted route ${route.name} to MCP tool');
      } catch (e) {
        logger.e('Error converting route ${route.name}: $e');
      }
    }

    return tools;
  }
}