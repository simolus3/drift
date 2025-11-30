import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;

bool isFromDrift(DartType type) {
  if (type is! InterfaceType) return false;

  final firstComponent =
      p.split(type.element.library.firstFragment.source.fullName).firstOrNull;
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
  String codeString() => getDisplayString();
}
