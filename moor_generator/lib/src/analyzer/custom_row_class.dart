// @dart=2.9
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';

ExistingRowClass /*?*/ validateExistingClass(Iterable<MoorColumn> columns,
    ClassElement desiredClass, String constructor, ErrorSink errors) {
  final ctor = desiredClass.getNamedConstructor(constructor);

  if (ctor == null) {
    final msg = constructor == ''
        ? 'The desired data class must have an unnamed constructor'
        : 'The desired data class does not have a constructor named '
            '$constructor';

    errors.report(ErrorInDartCode(affectedElement: desiredClass, message: msg));
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
      if (!column.isORM) {
        _checkType(parameter, column, errors);
      }
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
  final provider = element.library.typeProvider;

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

  DartType expectedDartType;

  if (column.typeConverter != null) {
    expectedDartType = column.typeConverter.mappedType;
  } else {
    expectedDartType = provider.typeFor(column.type);
  }

  if (!typesystem.isAssignableTo(expectedDartType, type)) {
    error('Parameter must accept '
        '${expectedDartType.getDisplayString(withNullability: true)}');
  }
}

extension on TypeProvider {
  DartType typeFor(ColumnType type) {
    switch (type) {
      case ColumnType.integer:
        return intType;
      case ColumnType.text:
        return stringType;
      case ColumnType.boolean:
        return boolType;
      case ColumnType.datetime:
        return intElement.library.getType('DateTime').instantiate(
            typeArguments: const [], nullabilitySuffix: NullabilitySuffix.none);
      case ColumnType.blob:
        // todo: We should return Uint8List, but how?
        return listType(intType);
      case ColumnType.real:
        return doubleType;
    }

    throw AssertionError('Unhandled moor type');
  }
}
