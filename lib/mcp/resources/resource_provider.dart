import 'package:flutter/material.dart';

abstract class MCPResourceProvider {
  Future<Map<String, dynamic>> read(BuildContext? context);
  void dispose() {}
}