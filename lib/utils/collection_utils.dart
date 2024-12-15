import '../data/data_property.dart';

Map<T, DataProperty<dynamic>> diffMaps<T>(
    Map<T, DataProperty<dynamic>> map1, Map<T, DataProperty<dynamic>> map2) {
  Map<T, DataProperty<dynamic>> diff = {};

  map1.forEach((key, value) {
    if (!map2.containsKey(key) || map2[key] != value) {
      diff[key] = value;
    }
  });

  map2.forEach((key, value) {
    if (!map1.containsKey(key)) {
      diff[key] = value;
    }
  });

  return diff;
}
