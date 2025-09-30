/// Interface for MCP integration to avoid direct dependency from ViewModels
abstract class MCPIntegrationInterface {
  /// Update tools based on current ViewModel
  void updateTools(dynamic viewModel, dynamic context);
}