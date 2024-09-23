import 'package:analyzer/dart/element/type.dart';

bool isFromDrift(DartType type) {
  if (type is! InterfaceType) return false;

  final firstComponent = type.element.library.location?.components.first;
  if (firstComponent == null) return false;

  return firstComponent.contains('drift') || firstComponent.contains('moor');
}

bool isColumn(DartType type) {
  final name = type.nameIfInterfaceType;

  return isFromDrift(type) &&
      name != null &&
      name.contains('Column') &&
      !name.contains('Builder');
}

bool isExpression(DartType type) {
  final name = type.nameIfInterfaceType;

  return name != null && isFromDrift(type) && name.startsWith('Expression');
}

extension TypeUtils on DartType {
  String? get nameIfInterfaceType {
    final $this = this;
    return $this is InterfaceType ? $this.element.name : null;
  }

  String get userVisibleName => getDisplayString();

  /// How this type should look like in generated code.
  String codeString() {
    return getDisplayString();
  }
}
