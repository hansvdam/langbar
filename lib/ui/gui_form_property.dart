import '../data/data_property.dart';

class GUIFormProperty<T> extends DataProperty<T> {
  final String caption;
  final String iconName;
  final bool justEntered;
  final String? ttsString;

  GUIFormProperty({
    required super.key,
    super.value,
    this.justEntered = false,
    String? caption,
    String? ttsString,
    required this.iconName,
  })  : caption = caption ?? key.name,
        ttsString = ttsString ?? value?.toString();
}
