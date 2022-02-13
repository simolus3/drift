import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/src/analyzer/dart/parser.dart';
import 'package:drift_dev/src/analyzer/errors.dart';

String dataClassNameForClassName(String tableName) {
  // This implementation is very primitive at the moment. The basic idea is
  // that, very often, table names are formed from the plural of the entity
  // they're storing (users, products, ...). We try to find the singular word
  // from the table name.

  // todo we might want to implement some edge cases according to
  // https://en.wikipedia.org/wiki/English_plurals

  if (tableName.endsWith('s')) {
    return tableName.substring(0, tableName.length - 1);
  }

  // Default behavior if the table name is not a valid plural.
  return '${tableName}Data';
}

String? parseCustomParentClass(
    DartObject dataClassName, ClassElement element, MoorDartParser base) {
  final extending = dataClassName.getField('extending');
  if (extending != null && !extending.isNull) {
    final extendingType = extending.toTypeValue();
    if (extendingType is InterfaceType) {
      final className = extendingType.element.name;
      if (extendingType.typeArguments.length == 1) {
        final genericType = extendingType.typeArguments[0].element?.name;
        if (genericType == 'dynamic') {
          return '$className<dynamic>';
        }
      }
      return className;
    } else {
      base.step.reportError(
        ErrorInDartCode(
          message: 'Parameter `extending` in @DataClassName must be used with a'
              ' class',
          affectedElement: element,
        ),
      );
    }
  }
  return null;
}
