/// Enum representing the user's intent for transfer parameters
enum TransferIntent {
  /// When the last user message clearly initiates a new transfer
  initialization('initialization'),
  
  /// When the last message provides alternative values for parameters 
  /// already touched by previous messages
  correction('correction'),
  
  /// When providing parameters for a transfer that have not been 
  /// mentioned in previous messages and thus complement the transfer data
  complement('complement');

  final String value;
  
  const TransferIntent(this.value);
  
  /// Convert from string value to enum
  static TransferIntent fromString(String value) {
    return TransferIntent.values.firstWhere(
      (intent) => intent.value == value,
      orElse: () => TransferIntent.initialization,
    );
  }
  
  /// Get all string values for the enumeration
  static List<String> get allValues => 
    TransferIntent.values.map((e) => e.value).toList();
    
  /// Const list of all string values for use in const contexts
  static const List<String> allValuesConst = [
    'initialization',
    'correction', 
    'complement'
  ];
}