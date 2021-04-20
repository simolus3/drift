// @dart=2.9
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';

ExistingRowClass /*?*/ validateExistingClass(
    List<MoorColumn> columns, ClassElement desiredClass, ErrorSink errors) {
  final ctor = desiredClass.unnamedConstructor;
  if (ctor == null) {
    errors.report(ErrorInDartCode(
      affectedElement: desiredClass,
      message: 'The desired data class must have an unnamed constructor',
    ));
    return null;
  }

  final unmatchedColumnsByName = {
    for (final column in columns) column.dartGetterName: column
  };

  final columnsToParameter = <MoorColumn, ParameterElement>{};

  for (final parameter in ctor.parameters) {
    final column = unmatchedColumnsByName.remove(parameter.name);
    if (column != null) {
      columnsToParameter[column] = parameter;
      _checkType(parameter, column, errors);
    } else if (!parameter.isOptional) {
      errors.report(ErrorInDartCode(
        affectedElement: parameter,
        message: 'Unexpected parameter ${parameter.name} which has no matching '
            'column.',
      ));
    }
  }

  return ExistingRowClass(desiredClass, ctor, columnsToParameter);
}

void _checkType(ParameterElement element, MoorColumn column, ErrorSink errors) {
  final type = element.type;
  final typesystem = element.library.typeSystem;

  void error(String message) {
    errors.report(ErrorInDartCode(
      affectedElement: element,
      message: message,
    ));
  }

  if (element.library.isNonNullableByDefault &&
      column.nullableInDart &&
      !typesystem.isNullable(type) &&
      element.isNotOptional) {
    error('Expected this parameter to be nullable');
    return;
  }

  // If there's a type converter, ensure the type matches
  if (column.typeConverter != null) {
    final mappedType = column.typeConverter.mappedType;
    if (!typesystem.isAssignableTo(mappedType, type)) {
      error('Parameter must accept '
          '${mappedType.getDisplayString(withNullability: true)}');
    }
  } else {
    // No type converter, check raw column type
    if (!type.matches(column.type)) {
      error('Invalid type, expected ${dartTypeNames[column.type]}');
    }
  }
}

extension on DartType {
  bool matches(ColumnType type) {
    switch (type) {
      case ColumnType.integer:
        return isDartCoreInt;
      case ColumnType.text:
        return isDartCoreString;
      case ColumnType.boolean:
        return isDartCoreBool;
      case ColumnType.real:
        return isDartCoreDouble;
      case ColumnType.datetime:
        return element.name == 'DateTime' && element.library.isDartCore;
      case ColumnType.blob:
        return isDartCoreList;
    }

    throw AssertionError('Unhandled moor type');
  }
}
