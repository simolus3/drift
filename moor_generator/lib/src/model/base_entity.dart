import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/moor_generator.dart';

/// Some schema entity found.
///
/// Most commonly a table, but it can also be a trigger.
abstract class MoorSchemaEntity implements HasDeclaration {
  /// All entities that have to be created before this entity can be created.
  ///
  /// For tables, this can be contents of a `REFERENCES` clause. For triggers,
  /// it would be the tables watched.
  ///
  /// If an entity contains an (invalid) null reference, that should not be
  /// included in [references].
  ///
  /// The generator will verify that the graph of entities and [references]
  /// is acyclic and sort them topologically.
  Iterable<MoorSchemaEntity> get references;

  /// A human readable name of this entity, like the table name.
  String get displayName;

  /// The getter in a generated database accessor referring to this model.
  ///
  /// Returns null for entities that shouldn't have a getter.
  String? get dbGetterName;
}

abstract class MoorEntityWithResultSet extends MoorSchemaEntity {
  /// The columns declared in this table or view.
  List<MoorColumn> get columns;

  /// The name of the Dart row class for this result set.
  String get dartTypeName;

  /// The name of the Dart class storing additional properties like type
  /// converters.
  String get entityInfoName;

  /// The existing class designed to hold a row, if there is any.
  ExistingRowClass? get existingRowClass;

  /// The name of the Dart class storing the right column getters for this type.
  ///
  /// This class is equal to, or a superclass of, [entityInfoName].
  String get dslName => entityInfoName;

  /// Whether this table has an existing row class, meaning that moor doesn't
  /// have to generate one on its own.
  bool get hasExistingRowClass => existingRowClass != null;
}

/// Information used by the generator to generate code for a custom data class
/// written by users.
class ExistingRowClass {
  final ClassElement targetClass;

  /// The Dart types that should be used to instantiate the [targetClass].
  final List<DartType> typeInstantiation;
  final ConstructorElement constructor;
  final Map<MoorColumn, ParameterElement> mapping;

  ExistingRowClass(this.targetClass, this.constructor, this.mapping,
      {this.typeInstantiation = const []});
}
