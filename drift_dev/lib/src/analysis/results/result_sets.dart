import 'package:analyzer/dart/element/type.dart';
import 'package:sqlparser/utils/case_insensitive_map.dart';

import 'element.dart';
import 'column.dart';
import 'dart.dart';

abstract class DriftElementWithResultSet extends DriftSchemaElement {
  /// The columns declared in this table or view.
  List<DriftColumn> get columns;

  /// The name of the Dart class storing additional properties like type
  /// converters or the schema definition.
  String get entityInfoName;

  /// The existing class designed to hold a row, if there is such existing class
  /// replacing the default, drift-generated class.
  ExistingRowClass? get existingRowClass;

  /// Class that added to data class as implementation
  AnnotatedDartCode? get customParentClass;

  /// Whether this table has an existing row class, meaning that drift will not
  /// generate one on its own.
  bool get hasExistingRowClass => existingRowClass != null;

  /// The name for the data class associated with this table or view.
  String get nameOfRowClass;

  /// All [columns] of this table, indexed by their name in SQL.
  late final Map<String, DriftColumn> columnBySqlName = CaseInsensitiveMap.of({
    for (final column in columns) column.nameInSql: column,
  });

  /// All type converter applied to columns on this table.
  Iterable<AppliedTypeConverter> get appliedConverters sync* {
    for (final column in columns) {
      if (column.typeConverter != null) {
        yield column.typeConverter!;
      }
    }
  }

  DriftElementWithResultSet(super.id, super.declaration) {
    for (final column in columns) {
      column.owner = this;
    }
  }
}

/// An existing row data class to be used, replacing the default one generated
/// by drift.
class ExistingRowClass {
  /// The name of the class used as an existing row class, or null if we're
  /// using a record type instead of an existing class.
  final AnnotatedDartCode? targetClass;

  /// The full type of the existing row class.
  ///
  /// For actual classes, this is an instantiation of the [targetClass] with
  /// type parameters determined during an analysis step.
  /// For records, [targetClass] is null and this [targetType] describes a Dart
  /// record type to be used instead.
  final DartType targetType;

  /// The constructor, factory or static method to use then instantiating the
  /// row class.
  ///
  /// The default unnamed constructor is represented as an empty string.
  final String constructor;

  /// Whether the [constructor] returns a future and thus needs to be awaited
  /// to create an instance of the custom row class.
  final bool isAsyncFactory;

  /// The name of drift columns which should be passed as positional arguments
  /// when creating an instance of the data class.
  final List<String> positionalColumns;

  /// A map from Dart parameters to the names of drift columns which should be
  /// passed as named arguments when creating an instance of the data class.
  final Map<String, String> namedColumns;

  /// Whether a `toCompanion` extension should be generated for this data class.
  final bool generateInsertable;

  /// Whether a record type should be used as the existing row class.
  bool get isRecord => targetType is RecordType;

  ExistingRowClass({
    required this.targetClass,
    required this.targetType,
    required this.constructor,
    required this.positionalColumns,
    required this.namedColumns,
    this.generateInsertable = false,
    this.isAsyncFactory = false,
  });

  ExistingRowClass.record({
    required this.targetType,
    required this.positionalColumns,
    required this.namedColumns,
    this.generateInsertable = false,
  })  : targetClass = null,
        constructor = '',
        isAsyncFactory = false;
}
