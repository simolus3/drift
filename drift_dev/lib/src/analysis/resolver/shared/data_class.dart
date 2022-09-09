import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../../driver/error.dart';
import '../../results/dart.dart';
import '../dart/helper.dart';
import '../resolver.dart';

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

AnnotatedDartCode? parseCustomParentClass(
  String dartTypeName,
  DartObject dataClassName,
  ClassElement element,
  LocalElementResolver resolver,
) {
  final extending = dataClassName.getField('extending');
  if (extending != null && !extending.isNull) {
    final extendingType = extending.toTypeValue();
    if (extendingType is InterfaceType) {
      final superType = extendingType.allSupertypes.any(
          (type) => isFromDrift(type) && type.element2.name == 'DataClass');
      if (!superType) {
        resolver.reportError(
          DriftAnalysisError.forDartElement(
            element,
            'Parameter `extending` in @DataClassName must be subtype of '
            'DataClass',
          ),
        );
        return null;
      }

      if (extendingType.typeArguments.length > 1) {
        resolver.reportError(
          DriftAnalysisError.forDartElement(
            element,
            'Parameter `extending` in @DataClassName must have zero or one '
            'type parameter',
          ),
        );
        return null;
      }

      // For legacy reasons, if we're extending an existing class with a type
      // parameter, we instantiate that type parameter to the data class itself.
      final className = extendingType.nameIfInterfaceType;
      if (extendingType.typeArguments.length == 1) {
        final genericType = extendingType.typeArguments[0];
        if (genericType.isDartCoreObject || genericType.isDynamic) {
          return AnnotatedDartCode([
            DartTopLevelSymbol.topLevelElement(element),
            '<',
            DartTopLevelSymbol(dartTypeName, null),
            '>',
          ]);
        } else {
          resolver.reportError(
            DriftAnalysisError.forDartElement(
              element,
              'Parameter `extending` in @DataClassName can only be '
              'provided as `$className<Object>`, `$className<dynamic>` or '
              'without declared type parameter (`$className`)',
            ),
          );

          return null;
        }
      }

      return AnnotatedDartCode.topLevelElement(element);
    } else {
      resolver.reportError(
        DriftAnalysisError.forDartElement(
          element,
          'Parameter `extending` in @DataClassName must be used with a class.',
        ),
      );
    }
  }
  return null;
}
