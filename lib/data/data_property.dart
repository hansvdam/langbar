import 'package:equatable/equatable.dart';

import 'data_key.dart';
import 'for_langchain.dart';

class DataProperty<T> extends Equatable {
  final DataKey key;
  final T? value;

  factory DataProperty.fromSuiParam(SUIParameter suiParameter) {
    final key = suiParameter.key;
    switch (suiParameter.type) {
      case DataType.string:
        return DataProperty<String?>(key: key, value: null) as DataProperty<T>;
      case DataType.integer:
        return DataProperty<int?>(key: key, value: null) as DataProperty<T>;
      case DataType.number:
        return DataProperty<int?>(key: key, value: null) as DataProperty<T>;
      case DataType.boolean:
        return DataProperty<bool?>(key: key, value: null) as DataProperty<T>;
      default:
        return DataProperty<T>(key: key, value: null);
    }
  }

  const DataProperty({required this.key, this.value});

  @override
  List<Object?> get props => [key, value];

  DataProperty<T> copyFrom(DataProperty<T> other) {
    return DataProperty<T>(
      key: other.key,
      value: other.value,
    );
  }

  DataProperty<T> copyWith({required T value}) {
    return DataProperty<T>(
      key: key,
      value: value,
    );
  }

  @override
  String toString() {
    // TODO: implement toString
    return '$key: $value';
  }
}
