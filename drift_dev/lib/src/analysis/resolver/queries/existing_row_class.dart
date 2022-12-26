import 'dart:math';

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';

import '../../results/results.dart';
import '../shared/dart_types.dart';
import '../dart/helper.dart';

/// Checks whether the [existingRowType] is suitable for holding a result row
/// of the [original] result set. If so, returns a new result set with its
/// [InferredResultSet.existingRowType] set accordingly.
InferredResultSet applyExistingType(
  InferredResultSet original,
  DartType existingRowType,
  KnownDriftTypes knownTypes,
  void Function(String) reportError,
) {
  ExistingQueryRowType? match;

  final library = knownTypes.helperLibrary;
  final typeSystem = library.typeSystem;
  final typeProvider = library.typeProvider;

  final unmatchedColumnsByName = {
    for (final column in original.columns) original.dartNameFor(column): column
  };

  if (existingRowType.isDartCoreRecord) {
    // General `Record` supertype => Drift will pick a suitable record type.
    match = _defaultRecord(original);
  }
  if (existingRowType is InterfaceType) {
    final element = existingRowType.element;

    final constructor = existingRowType.lookUpConstructor('', element.library);
    if (constructor == null) {
      reportError(
          'The class to use as an existing row type must have an unnamed constructor.');
      return original;
    }

    final positionalColumns = <ResultColumn>[];
    final namedColumns = <String, ResultColumn>{};

    for (final parameter in constructor.parameters) {
      final column = unmatchedColumnsByName.remove(parameter.name);
      if (column != null) {
        if (parameter.isPositional) {
          positionalColumns.add(column);
        } else {
          namedColumns[parameter.name] = column;
        }

        _checkType(column, parameter.type, typeProvider, typeSystem, knownTypes,
            reportError);
      } else if (!parameter.isOptional) {
        reportError(
            'Unexpected parameter ${parameter.name} has no matching column.');
      }
    }

    match = ExistingQueryRowType(
      rowType: AnnotatedDartCode.type(existingRowType),
      positionalArguments: positionalColumns,
      namedArguments: namedColumns,
    );
  } else if (existingRowType is RecordType) {
    final amountOfPositionalFields = existingRowType.positionalFields.length;
    if (amountOfPositionalFields > original.columns.length) {
      reportError('The desired record has $amountOfPositionalFields positional '
          'parameters, but there are only ${original.columns.length} columns.');
    }

    final positionalColumns = <ResultColumn>[];
    final namedColumns = <String, ResultColumn>{};

    for (var i = 0;
        i < min(amountOfPositionalFields, original.columns.length);
        i++) {
      positionalColumns.add(original.columns[i]);
    }

    for (final parameter in existingRowType.namedFields) {
      final column = unmatchedColumnsByName.remove(parameter.name);
      if (column != null) {
        namedColumns[parameter.name] = column;

        _checkType(column, parameter.type, typeProvider, typeSystem, knownTypes,
            reportError);
      } else {
        reportError(
            'Unexpected field ${parameter.name} has no matching column.');
      }
    }

    match = ExistingQueryRowType(
      rowType: AnnotatedDartCode.type(existingRowType),
      positionalArguments: positionalColumns,
      namedArguments: namedColumns,
    );
  } else {
    reportError('Invalid row type, must be a class or a record.');
  }

  if (match != null) {
    return InferredResultSet(
      null,
      original.columns,
      existingRowType: match,
    );
  } else {
    return original;
  }
}

ExistingQueryRowType _defaultRecord(InferredResultSet original) {
  final type = AnnotatedDartCode.build((builder) {
    builder.addText('({');

    for (var i = 0; i < original.columns.length; i++) {
      if (i != 0) builder.addText(', ');

      final column = original.columns[i];

      if (column is ScalarResultColumn) {
        builder.addDriftType(column);
      } else if (column is NestedResult) {
        builder.addTypeOfNestedResult(column);
      }

      builder.addText(' ${original.dartNameFor(column)}');
    }

    builder.addText('})');
  });

  return ExistingQueryRowType(
    rowType: type,
    positionalArguments: const [],
    namedArguments: {
      for (final column in original.columns)
        original.dartNameFor(column): column,
    },
  );
}

void _checkType(
  ResultColumn column,
  DartType actualType,
  TypeProvider typeProvider,
  TypeSystem typeSystem,
  KnownDriftTypes knownTypes,
  void Function(String) error,
) {
  if (column is ScalarResultColumn) {
    _checkScalar(
        column, actualType, typeProvider, typeSystem, knownTypes, error);
  }

  // TODO: Check nested types if possible
}

void _checkScalar(
  ScalarResultColumn column,
  DartType actualType,
  TypeProvider typeProvider,
  TypeSystem typeSystem,
  KnownDriftTypes knownTypes,
  void Function(String) error,
) {
  checkType(column.sqlType, column.nullable, column.typeConverter, actualType,
      typeProvider, typeSystem, knownTypes, error);
}
