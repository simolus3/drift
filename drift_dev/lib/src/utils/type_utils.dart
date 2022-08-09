import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/src/writer/writer.dart';

bool isFromMoor(DartType type) {
  if (type is! InterfaceType) return false;

  final firstComponent = type.element2.library.location?.components.first;
  if (firstComponent == null) return false;

  return firstComponent.contains('drift') || firstComponent.contains('moor');
}

bool isColumn(DartType type) {
  final name = type.nameIfInterfaceType;

  return isFromMoor(type) &&
      name != null &&
      name.contains('Column') &&
      !name.contains('Builder');
}

bool isExpression(DartType type) {
  final name = type.nameIfInterfaceType;

  return name != null && isFromMoor(type) && name.startsWith('Expression');
}

extension TypeUtils on DartType {
  String? get nameIfInterfaceType {
    final $this = this;
    return $this is InterfaceType ? $this.element2.name : null;
  }

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
