import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import '../tool_registry.dart';
import '../../logger_utils.dart';

class ViewModelToolConverter {
  static MCPTool convert(Tool langchainTool) {
    // Extract parameters from LangChain tool
    final mcpParams = _convertLangChainParameters(langchainTool);

    // Create execution handler that calls the LangChain tool
    Future<dynamic> executionHandler(Map<String, dynamic> params, BuildContext? context) async {
      try {
        // Convert MCP params to LangChain format
        final toolInput = _prepareLangChainInput(params);

        // Execute the LangChain tool
        final result = await langchainTool.invoke(toolInput);

        // Convert the result to MCP format
        return _convertLangChainOutput(result);
      } catch (e) {
        logger.e('Error executing ViewModel tool ${langchainTool.name}: $e');
        return {
          'success': false,
          'error': e.toString(),
        };
      }
    }

    return MCPToolImpl(
      name: langchainTool.name,
      description: langchainTool.description,
      parameters: mcpParams,
      executionHandler: executionHandler,
    );
  }

  static Map<String, dynamic> _convertLangChainParameters(Tool tool) {
    final params = <String, dynamic>{};

    // LangChain tools have inputJsonSchema property
    if (tool.inputJsonSchema != null && tool.inputJsonSchema is Map) {
      final schema = tool.inputJsonSchema as Map<String, dynamic>;

      // Extract properties from the schema
      if (schema['properties'] != null && schema['properties'] is Map) {
        final properties = schema['properties'] as Map<String, dynamic>;

        properties.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            params[key] = {
              'type': value['type'] ?? 'string',
              'description': value['description'] ?? '',
              'required': _isRequired(key, schema),
            };

            // Add enum if present
            if (value['enum'] != null) {
              params[key]['enum'] = value['enum'];
            }
          }
        });
      }
    }

    // Fallback: Create a simple parameter structure if no schema is available
    if (params.isEmpty) {
      params['input'] = {
        'type': 'string',
        'description': 'Input for the tool',
        'required': false,
      };
    }

    return params;
  }

  static bool _isRequired(String key, Map<String, dynamic> schema) {
    if (schema['required'] != null && schema['required'] is List) {
      return (schema['required'] as List).contains(key);
    }
    return false;
  }

  static Map<String, dynamic> _prepareLangChainInput(Map<String, dynamic> mcpParams) {
    // For most LangChain tools, the input is a simple map
    // Some tools might expect specific formatting
    final input = <String, dynamic>{};

    mcpParams.forEach((key, value) {
      // Convert MCP parameter values to appropriate types
      if (value != null) {
        input[key] = value;
      }
    });

    return input;
  }

  static Map<String, dynamic> _convertLangChainOutput(dynamic result) {
    // Handle different types of LangChain tool outputs
    if (result == null) {
      return {
        'success': true,
        'result': null,
      };
    }

    if (result is String) {
      return {
        'success': true,
        'result': result,
      };
    }

    if (result is Map) {
      return {
        'success': true,
        ...result as Map<String, dynamic>,
      };
    }

    // For complex objects, try to convert to a readable format
    return {
      'success': true,
      'result': result.toString(),
    };
  }

  static List<MCPTool> convertTools(List<Tool> langchainTools) {
    final mcpTools = <MCPTool>[];

    for (final tool in langchainTools) {
      try {
        mcpTools.add(convert(tool));
        logger.d('Converted LangChain tool ${tool.name} to MCP tool');
      } catch (e) {
        logger.e('Error converting LangChain tool ${tool.name}: $e');
      }
    }

    return mcpTools;
  }
}