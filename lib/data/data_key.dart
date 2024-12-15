class DataKey {
  final String name;

  const DataKey(this.name);

  static List<DataKey> values = <DataKey>[];

  static DataKey fromString(String value) {
    return values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => throw ArgumentError('Invalid DataKey string: $value'),
    );
  }

  @override
  String toString() {
    // Find the constant name by comparing this instance with all constants
    for (var field in values) {
      if (field == this) {
        return field.name;
      }
    }
    return name;
  }
}
