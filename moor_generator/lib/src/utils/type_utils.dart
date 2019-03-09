import 'package:analyzer/dart/element/type.dart';

bool isFrommoor(DartType type) {
  return type.element.library.location.components.first.contains('moor');
}

bool isColumn(DartType type) {
  return isFrommoor(type) && type.name.contains('Column');
}
