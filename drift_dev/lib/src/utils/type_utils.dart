import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/src/writer/writer.dart';

bool isFromMoor(DartType type) {
  final firstComponent = type.element?.library?.location?.components.first;

  if (firstComponent == null) return false;

  return firstComponent.contains('drift') || firstComponent.contains('moor');
}

bool isColumn(DartType type) {
  final name = type.element?.name ?? '';

  return isFromMoor(type) &&
      name.contains('Column') &&
      !name.contains('Builder');
}

extension TypeUtils on DartType {
  String get userVisibleName => getDisplayString(withNullability: true);

  /// How this type should look like in generated code.
  String codeString([GenerationOptions options = const GenerationOptions()]) {
    if (nullabilitySuffix == NullabilitySuffix.star) {
      // We can't actually use the legacy star in code, so don't show it.
      return getDisplayString(withNullability: false);
    }

    return getDisplayString(withNullability: options.nnbd);
  }
}
