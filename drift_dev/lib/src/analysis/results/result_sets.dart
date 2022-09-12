import 'package:json_annotation/json_annotation.dart';

import 'element.dart';
import 'column.dart';
import 'dart.dart';

part '../../generated/analysis/results/result_sets.g.dart';

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

  DriftElementWithResultSet(super.id, super.declaration);
}

/// An existing row data class to be used, replacing the default one generated
/// by drift.
@JsonSerializable()
class ExistingRowClass {
  /// The name of the class used as an existing row class.
  final AnnotatedDartCode targetClass;

  /// The full type of the existing row class.
  ///
  /// This is an instantiation of the [targetClass] with type parameters
  /// determined during an analysis step.
  final AnnotatedDartCode targetType;

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

  ExistingRowClass({
    required this.targetClass,
    required this.targetType,
    required this.constructor,
    required this.positionalColumns,
    required this.namedColumns,
    this.generateInsertable = false,
    this.isAsyncFactory = false,
  });

  factory ExistingRowClass.fromJson(Map json) =>
      _$ExistingRowClassFromJson(json);

  Map<String, Object?> toJson() => _$ExistingRowClassToJson(this);
}
