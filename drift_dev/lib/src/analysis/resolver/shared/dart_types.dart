import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type.dart'
    show
        RecordTypeImpl,
        RecordTypeNamedFieldImpl,
        RecordTypePositionalFieldImpl;
import 'package:drift/drift.dart' show DriftSqlType;

import '../../driver/error.dart';
import '../../results/results.dart';
import '../dart/helper.dart';
import '../resolver.dart';

class FoundDartClass {
  final InterfaceElement classElement;

  /// The instantiation of the [classElement], if the found type was a generic
  /// typedef.
  final List<DartType>? instantiation;

  FoundDartClass(this.classElement, this.instantiation);
}

ExistingRowClass? validateExistingClass(
  List<DriftColumn> columns,
  FoundDartClass dartClass,
  String constructor,
  bool generateInsertable,
  LocalElementResolver step,
  KnownDriftTypes knownTypes,
) {
  final desiredClass = dartClass.classElement;
  final library = desiredClass.library;
  var isAsyncFactory = false;

  if (desiredClass.thisType.isDartCoreRecord) {
    // When the `Record` supertype from `dart:core` is used, generate a custom
    // record type suitable for this row class.
    return defaultRecordRowClass(
      columns: columns,
      generateInsertable: generateInsertable,
      knownDriftTypes: knownTypes,
      typeProvider: library.typeProvider,
      typeSystem: library.typeSystem,
    );
  }

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
        step.reportError(DriftAnalysisError.forDartElement(
          fallback,
          'To use this method as a factory for the custom row class, it needs '
          'to be static.',
        ));
      }

      // The static factory must return a subtype of `FutureOr<ThatRowClass>`
      final expectedReturnType =
          library.typeProvider.futureOrType(instantiation);
      if (!library.typeSystem
          .isAssignableTo(fallback.returnType, expectedReturnType)) {
        step.reportError(DriftAnalysisError.forDartElement(
          fallback,
          'To be used as a factory for the custom row class, this method needs '
          'to return an instance of it.',
        ));
      }

      isAsyncFactory = library.typeSystem.flatten(fallback.returnType) !=
          fallback.returnType;

      ctor = fallback;
    }
  }

  if (ctor == null) {
    final msg = constructor == ''
        ? 'The desired data class must have an unnamed constructor'
        : 'The desired data class does not have a constructor named '
            '$constructor';

    step.reportError(DriftAnalysisError.forDartElement(desiredClass, msg));
    return null;
  }

  // Note: It's ok if not all columns are present in the custom row class, we
  // just won't load them in that case.message:
  // However, when we're supposed to generate an insertable, all columns must
  // appear as getters in the target class.
  final unmatchedColumnsByName = {
    for (final column in columns) column.nameInDart: column
  };

  final positionalColumns = <DriftColumn>[];
  final namedColumns = <ParameterElement, DriftColumn>{};

  for (final parameter in ctor.parameters) {
    final column = unmatchedColumnsByName.remove(parameter.name);
    if (column != null) {
      if (parameter.isPositional) {
        positionalColumns.add(column);
      } else {
        namedColumns[parameter] = column;
      }

      _checkParameterType(parameter, column, step, knownTypes);
    } else if (!parameter.isOptional) {
      step.reportError(DriftAnalysisError.forDartElement(
        parameter,
        'Unexpected parameter ${parameter.name} which has no matching column.',
      ));
    }
  }

  if (generateInsertable) {
    // Go through all columns, make sure that the class has getters for them.
    final missingGetters = <String>[];

    for (final column in columns) {
      final matchingField = dartClass.classElement
          .lookUpGetter(column.nameInDart, dartClass.classElement.library);

      if (matchingField == null) {
        missingGetters.add(column.nameInDart);
      }
    }

    if (missingGetters.isNotEmpty) {
      step.reportError(DriftAnalysisError.forDartElement(
        dartClass.classElement,
        'This class used as a custom row class for which an insertable '
        'is generated. This means that it must define getters for all '
        'columns, but some are missing: ${missingGetters.join(', ')}',
      ));
    }
  }

  return ExistingRowClass(
    targetClass: AnnotatedDartCode.topLevelElement(desiredClass),
    targetType: instantiation,
    constructor: constructor,
    positionalColumns: [
      for (final column in positionalColumns) column.nameInSql
    ],
    namedColumns: {
      for (final named in namedColumns.entries)
        named.key.name: named.value.nameInSql,
    },
    generateInsertable: generateInsertable,
    isAsyncFactory: isAsyncFactory,
  );
}

ExistingRowClass validateRowClassFromRecordType(
  Element element,
  Iterable<DriftColumn> columns,
  RecordType dartType,
  bool generateInsertable,
  LocalElementResolver step,
  KnownDriftTypes knownTypes,
) {
  final library = element.library!;

  final unmatchedColumnsByName = {
    for (final column in columns) column.nameInDart: column
  };

  final namedColumns = <String, String>{};

  for (final parameter in dartType.namedFields) {
    final column = unmatchedColumnsByName.remove(parameter.name);
    if (column != null) {
      namedColumns[parameter.name] = column.nameInSql;

      checkType(
        column.sqlType,
        column.nullable,
        column.typeConverter,
        parameter.type,
        library.typeProvider,
        library.typeSystem,
        knownTypes,
        (msg) {
          step.reportError(DriftAnalysisError.forDartElement(element, msg));
        },
      );
    } else {
      step.reportError(DriftAnalysisError.forDartElement(
        element,
        'Unexpected parameter ${parameter.name} which has no matching column.',
      ));
    }
  }

  // The analyzer doesn't expose the name of positional record types yet, so we
  // will have to come up with another approach to extract information for
  // positional types.
  if (dartType.positionalFields.isNotEmpty) {
    step.reportError(DriftAnalysisError.forDartElement(element,
        'Records with positional types are not yet supported as existing types.'));
  }

  return ExistingRowClass.record(
    targetType: dartType,
    positionalColumns: const [],
    namedColumns: namedColumns,
    generateInsertable: generateInsertable,
  );
}

ExistingRowClass defaultRecordRowClass({
  required List<DriftColumn> columns,
  required bool generateInsertable,
  required TypeProvider typeProvider,
  required TypeSystem typeSystem,
  required KnownDriftTypes knownDriftTypes,
}) {
  final type = typeProvider.createRecordType(
    positional: const [],
    named: [
      for (final column in columns)
        MapEntry(
            column.nameInDart,
            regularColumnType(
                typeProvider, typeSystem, knownDriftTypes, column)),
    ],
  );

  return ExistingRowClass.record(
    targetType: type,
    positionalColumns: [],
    namedColumns: {
      for (final column in columns) column.nameInDart: column.nameInSql,
    },
  );
}

enum EnumType {
  intEnum,
  textEnum,
}

CustomColumnType? readCustomType(
  LibraryElement library,
  Expression dartExpression,
  KnownDriftTypes helper,
  void Function(String) reportError,
) {
  final staticType = dartExpression.staticType;
  final asCustomType =
      staticType != null ? helper.asCustomType(staticType) : null;

  if (asCustomType == null) {
    reportError('Not a custom type');
    return null;
  }

  final dartType = asCustomType.typeArguments[0];

  return CustomColumnType(AnnotatedDartCode.ast(dartExpression), dartType);
}

AppliedTypeConverter? readTypeConverter(
  LibraryElement library,
  Expression dartExpression,
  ColumnType columnType,
  bool columnIsNullable,
  void Function(String) reportError,
  KnownDriftTypes helper,
) {
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

  final asJsonConverter = helper.asJsonTypeConverter(staticType);
  final appliesToJsonToo = asJsonConverter != null;

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

  checkType(columnType, columnIsNullable, null, sqlType, library.typeProvider,
      library.typeSystem, helper, reportError);

  return AppliedTypeConverter(
    expression: AnnotatedDartCode.ast(dartExpression),
    dartType: dartType,
    jsonType: appliesToJsonToo ? asJsonConverter.typeArguments[2] : null,
    sqlType: columnType,
    dartTypeIsNullable: dartTypeNullable,
    sqlTypeIsNullable: sqlTypeNullable,
    isDriftEnumTypeConverter: false,
  );
}

AppliedTypeConverter readEnumConverter(
  void Function(String) reportError,
  DartType dartEnumType,
  EnumType columnEnumType,
  KnownDriftTypes helper,
) {
  final typeProvider = helper.helperLibrary.typeProvider;
  if (dartEnumType is! InterfaceType) {
    reportError('Not a class: `$dartEnumType`');
  }

  final creatingClass = dartEnumType.element;
  if (creatingClass is! EnumElement) {
    reportError('Not an enum: `${creatingClass!.displayName}`');
  }

  // `const EnumIndexConverter<EnumType>(EnumType.values)`
  // or
  // `const EnumNameConverter<EnumType>(EnumType.values)`
  final expression = AnnotatedDartCode.build((builder) {
    builder.addText('const ');
    if (columnEnumType == EnumType.intEnum) {
      builder.addSymbol('EnumIndexConverter', AnnotatedDartCode.drift);
    } else {
      builder.addSymbol('EnumNameConverter', AnnotatedDartCode.drift);
    }
    builder
      ..addText('<')
      ..addTopLevelElement(dartEnumType.element!)
      ..addText('>(')
      ..addTopLevelElement(dartEnumType.element!)
      ..addText('.values)');
  });

  return AppliedTypeConverter(
    expression: expression,
    dartType: dartEnumType,
    jsonType: columnEnumType == EnumType.intEnum
        ? typeProvider.intType
        : typeProvider.stringType,
    sqlType: ColumnType.drift(columnEnumType == EnumType.intEnum
        ? DriftSqlType.int
        : DriftSqlType.string),
    dartTypeIsNullable: false,
    sqlTypeIsNullable: false,
    isDriftEnumTypeConverter: true,
  );
}

void _checkParameterType(
  ParameterElement element,
  DriftColumn column,
  LocalElementResolver resolver,
  KnownDriftTypes helper,
) {
  final type = element.type;
  final library = element.library!;
  final typesystem = library.typeSystem;

  void error(String message) {
    resolver.reportError(DriftAnalysisError.forDartElement(element, message));
  }

  final nullableDartType = column.nullableInDart;

  if (library.isNonNullableByDefault &&
      nullableDartType &&
      !typesystem.isNullable(type) &&
      element.isRequired) {
    error('Expected this parameter to be nullable');
    return;
  }

  checkType(
    column.sqlType,
    column.nullable,
    column.typeConverter,
    element.type,
    library.typeProvider,
    library.typeSystem,
    helper,
    error,
  );
}

bool checkType(
  ColumnType columnType,
  bool columnIsNullable,
  AppliedTypeConverter? typeConverter,
  DartType typeToCheck,
  TypeProvider typeProvider,
  TypeSystem typeSystem,
  KnownDriftTypes knownTypes,
  void Function(String) error,
) {
  DartType expectedDartType;
  if (typeConverter != null) {
    expectedDartType = typeConverter.dartType;
    if (typeConverter.canBeSkippedForNulls && columnIsNullable) {
      expectedDartType =
          typeProvider.makeNullable(expectedDartType, typeSystem);
    }
  } else {
    expectedDartType = typeProvider.typeFor(columnType, knownTypes);
  }

  if (!typeSystem.isAssignableTo(expectedDartType, typeToCheck)) {
    error('Parameter must accept '
        '${expectedDartType.getDisplayString(withNullability: true)}');
    return false;
  }

  return true;
}

DartType regularColumnType(
  TypeProvider typeProvider,
  TypeSystem typeSystem,
  KnownDriftTypes knownTypes,
  HasType type,
) {
  final converter = type.typeConverter;
  if (converter != null) {
    var dartType = converter.dartType;
    if (type.nullable && converter.canBeSkippedForNulls) {
      return typeProvider.makeNullable(dartType, typeSystem);
    } else {
      return dartType;
    }
  } else {
    final typeForNonNullable = typeProvider.typeFor(type.sqlType, knownTypes);
    return type.nullable
        ? typeProvider.makeNullable(typeForNonNullable, typeSystem)
        : typeForNonNullable;
  }
}

extension on TypeProvider {
  DartType typeFor(ColumnType type, KnownDriftTypes knownTypes) {
    if (type.custom case CustomColumnType custom) {
      return custom.dartType;
    }

    switch (type.builtin) {
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
        return knownTypes.uint8List;
      case DriftSqlType.double:
        return doubleType;
      case DriftSqlType.any:
        return knownTypes.driftAny;
    }
  }
}

extension CreateRecordType on TypeProvider {
  RecordType createRecordType({
    required List<DartType> positional,
    required List<MapEntry<String, DartType>> named,
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.none,
  }) {
    // todo: Use public API after https://dart-review.googlesource.com/c/sdk/+/277401
    return RecordTypeImpl(
      positionalFields: [
        for (final type in positional)
          RecordTypePositionalFieldImpl(type: type),
      ],
      namedFields: [
        for (final namedEntry in named)
          RecordTypeNamedFieldImpl(name: namedEntry.key, type: namedEntry.value)
      ],
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  DartType makeNullable(DartType type, TypeSystem typeSystem) {
    return typeSystem.leastUpperBound(type, nullType);
  }
}
