import 'package:analyzer/dart/element/type.dart';

bool isFromSally(DartType type) {
  return type.element.library.location.components.first.contains("sally");
}

bool isColumn(DartType type) {
  return isFromSally(type) && type.name.contains("Column");
}
