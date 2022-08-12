import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/runner/steps.dart';

import 'helper.dart';

class FoundDartClass {
  final InterfaceElement classElement;

  /// The instantiation of the [classElement], if the found type was a generic
  /// typedef.
  final List<DartType>? instantiation;

  FoundDartClass(this.classElement, this.instantiation);
}

ExistingRowClass? validateExistingClass(
    Iterable<DriftColumn> columns,
    FoundDartClass dartClass,
    String constructor,
    bool generateInsertable,
    Step step) {
  final errors = step.errors;
  final desiredClass = dartClass.classElement;
  final library = desiredClass.library;

  ExecutableElement? ctor;
  final InterfaceType instantiation;

  if (dartClass.instantiation != null) {
    instantiation = desiredClass.instantiate(
      typeArguments: dartClass.instantiation!,
      nullabilitySuffix: NullabilitySuffix.none,
    );

    // If we have an instantation, search the constructor on the type because it
    // will report the right parameter types if they're generic.
    ctor = instantiation.lookUpConstructor(constructor, desiredClass.library);
  } else {
    ctor = desiredClass.getNamedConstructor(constructor);
    instantiation = library.typeSystem.instantiateInterfaceToBounds(
        element: desiredClass, nullabilitySuffix: NullabilitySuffix.none);
  }

  if (ctor == null) {
    final fallback = desiredClass.getMethod(constructor);

    if (fallback != null) {
      if (!fallback.isStatic) {
        errors.report(ErrorInDartCode(
          affectedElement: fallback,
          message: 'To use this method as a factory for the custom row class, '
              'it needs to be static.',
        ));
      }

      // The static factory must return a subtype of `FutureOr<ThatRowClass>`
      final expectedReturnType =
          library.typeProvider.futureOrType(instantiation);
      if (!library.typeSystem
          .isAssignableTo(fallback.returnType, expectedReturnType)) {
        errors.report(ErrorInDartCode(
          affectedElement: fallback,
          message: 'To be used as a factory for the custom row class, this '
              'method needs to return an instance of it.',
        ));
      }

      ctor = fallback;
    }
  }

  if (ctor == null) {
    final msg = constructor == ''
        ? 'The desired data class must have an unnamed constructor'
        : 'The desired data class does not have a constructor named '
            '$constructor';

    errors.report(ErrorInDartCode(affectedElement: desiredClass, message: msg));
    return null;
  }

  // Note: It's ok if not all columns are present in the custom row class, we
  // just won't load them in that case.
  // However, when we're supposed to generate an insertable, all columns must
  // appear as getters in the target class.
  final unmatchedColumnsByName = {
    for (final column in columns) column.dartGetterName: column
  };

  final columnsToParameter = <DriftColumn, ParameterElement>{};

  for (final parameter in ctor.parameters) {
    final column = unmatchedColumnsByName.remove(parameter.name);
    if (column != null) {
      columnsToParameter[column] = parameter;
      _checkParameterType(parameter, column, step);
    } else if (!parameter.isOptional) {
      errors.report(ErrorInDartCode(
        affectedElement: parameter,
        message: 'Unexpected parameter ${parameter.name} which has no matching '
            'column.',
      ));
    }
  }

  if (generateInsertable) {
    // Go through all columns, make sure that the class has getters for them.
    final missingGetters = <String>[];

    for (final column in columns) {
      final matchingField = dartClass.classElement
          .lookUpGetter(column.dartGetterName, dartClass.classElement.library);

      if (matchingField == null) {
        missingGetters.add(column.dartGetterName);
      }
    }

    if (missingGetters.isNotEmpty) {
      errors.report(ErrorInDartCode(
        affectedElement: dartClass.classElement,
        severity: Severity.criticalError,
        message:
            'This class used as a custom row class for which an insertable '
            'is generated. This means that it must define getters for all '
            'columns, but some are missing: ${missingGetters.join(', ')}',
      ));
    }
  }

  return ExistingRowClass(
      desiredClass, ctor, columnsToParameter, generateInsertable,
      typeInstantiation: dartClass.instantiation ?? const []);
}

UsedTypeConverter? readTypeConverter(
  LibraryElement library,
  Expression dartExpression,
  DriftSqlType columnType,
  bool columnIsNullable,
  void Function(String) reportError,
  HelperLibrary helper, {
  DriftDartType? resolvedDartType,
}) {
  final staticType = dartExpression.staticType;
  final asTypeConverter =
      staticType != null ? helper.asTypeConverter(staticType) : null;

  if (asTypeConverter == null) {
    reportError('Not a type converter');
    return null;
  }

  final dartType = asTypeConverter.typeArguments[0];
  final sqlType = asTypeConverter.typeArguments[1];

  final typeSystem = library.typeSystem;
  final dartTypeNullable = typeSystem.isNullable(dartType);
  final sqlTypeNullable = typeSystem.isNullable(sqlType);

  final appliesToJsonToo = helper.isJsonAwareTypeConverter(staticType, library);

  // Make the type converter support nulls by just mapping null to null if this
  // converter is otherwise non-nullable in both directions.
  final canBeSkippedForNulls = !dartTypeNullable && !sqlTypeNullable;

  if (sqlTypeNullable != columnIsNullable) {
    if (!columnIsNullable) {
      reportError('This column is non-nullable in the database, but has a '
          'type converter with a nullable SQL type, meaning that it may '
          "potentially map to `null` which can't be stored in the database.");
    } else if (!canBeSkippedForNulls) {
      final alternative = appliesToJsonToo
          ? 'JsonTypeConverter.asNullable'
          : 'NullAwareTypeConverter.wrap';

      reportError('This column is nullable, but the type converter has a non-'
          "nullable SQL type, meaning that it won't be able to map `null` "
          'from the database to Dart.\n'
          'Try wrapping the converter in `$alternative`');
    }
  }

  _checkType(columnType, columnIsNullable, null, sqlType, library.typeProvider,
      library.typeSystem, reportError);

  return UsedTypeConverter(
    expression: dartExpression.toSource(),
    dartType: resolvedDartType ?? DriftDartType.of(dartType),
    sqlType: sqlType,
    dartTypeIsNullable: dartTypeNullable,
    sqlTypeIsNullable: sqlTypeNullable,
    alsoAppliesToJsonConversion: appliesToJsonToo,
    canBeSkippedForNulls: canBeSkippedForNulls,
  );
}

void _checkParameterType(
    ParameterElement element, DriftColumn column, Step step) {
  final type = element.type;
  final library = element.library!;
  final typesystem = library.typeSystem;

  void error(String message) {
    step.errors.report(ErrorInDartCode(
      affectedElement: element,
      message: message,
    ));
  }

  final nullableDartType = column.typeConverter != null
      ? column.typeConverter!.mapsToNullableDart(column.nullable)
      : column.nullableInDart;

  if (library.isNonNullableByDefault &&
      nullableDartType &&
      !typesystem.isNullable(type) &&
      element.isRequired) {
    error('Expected this parameter to be nullable');
    return;
  }

  _checkType(
    column.type,
    column.nullable,
    column.typeConverter,
    element.type,
    library.typeProvider,
    library.typeSystem,
    error,
  );
}

void _checkType(
  DriftSqlType columnType,
  bool columnIsNullable,
  UsedTypeConverter? typeConverter,
  DartType typeToCheck,
  TypeProvider typeProvider,
  TypeSystem typeSystem,
  void Function(String) error,
) {
  DriftDartType expectedDartType;
  if (typeConverter != null) {
    expectedDartType = typeConverter.dartType;
    if (typeConverter.canBeSkippedForNulls && columnIsNullable) {
      typeToCheck = typeSystem.promoteToNonNull(typeToCheck);
    }
  } else {
    expectedDartType = DriftDartType.of(typeProvider.typeFor(columnType));
  }

  // BLOB columns should be stored in an Uint8List (or a supertype of that).
  // We don't get a Uint8List from the type provider unfortunately, but as it
  // cannot be extended we can just check for that manually.
  final isAllowedUint8List = typeConverter == null &&
      columnType == DriftSqlType.blob &&
      typeToCheck is InterfaceType &&
      typeToCheck.element2.name == 'Uint8List' &&
      typeToCheck.element2.library.name == 'dart.typed_data';

  if (!typeSystem.isAssignableTo(expectedDartType.type, typeToCheck) &&
      !isAllowedUint8List) {
    error('Parameter must accept '
        '${expectedDartType.getDisplayString(withNullability: true)}');
  }
}

extension on TypeProvider {
  DartType typeFor(DriftSqlType type) {
    switch (type) {
      case DriftSqlType.int:
        return intType;
      case DriftSqlType.bigInt:
        return intElement.library.getClass('BigInt')!.instantiate(
            typeArguments: const [], nullabilitySuffix: NullabilitySuffix.none);
      case DriftSqlType.string:
        return stringType;
      case DriftSqlType.bool:
        return boolType;
      case DriftSqlType.dateTime:
        return intElement.library.getClass('DateTime')!.instantiate(
            typeArguments: const [], nullabilitySuffix: NullabilitySuffix.none);
      case DriftSqlType.blob:
        return listType(intType);
      case DriftSqlType.double:
        return doubleType;
    }
  }
}
