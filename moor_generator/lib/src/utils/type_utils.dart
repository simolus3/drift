import 'package:analyzer/dart/element/type.dart';

bool isFromMoor(DartType type) {
  return type.element?.library?.location?.components?.first?.contains('moor') ??
      false;
}

bool isColumn(DartType type) {
  return isFromMoor(type) && type.name.contains('Column');
}
