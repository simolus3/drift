import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/writer.dart';

/// Some schema entity found.
///
/// Most commonly a table, but it can also be a trigger.
abstract class DriftSchemaEntity implements HasDeclaration {
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
  Iterable<DriftSchemaEntity> get references;

  /// A human readable name of this entity, like the table name.
  String get displayName;

  /// The getter in a generated database accessor referring to this model.
  ///
  /// Returns null for entities that shouldn't have a getter.
  String? get dbGetterName;
}

abstract class DriftEntityWithResultSet extends DriftSchemaEntity {
  /// The columns declared in this table or view.
  List<DriftColumn> get columns;

  /// The name of the Dart row class for this result set.
  @Deprecated('Use dartTypeCode instead')
  String get dartTypeName;

  /// The type name of the Dart row class for this result set.
  ///
  /// This may contain generics.
  String dartTypeCode();

  /// The name of the Dart class storing additional properties like type
  /// converters.
  String get entityInfoName;

  /// The existing class designed to hold a row, if there is any.
  ExistingRowClass? get existingRowClass;

  /// Class that added to data class as implementation
  String? get customParentClass;

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
  final InterfaceElement targetClass;

  /// The Dart types that should be used to instantiate the [targetClass].
  final List<DartType> typeInstantiation;

  /// The method to use when instantiating the row class.
  ///
  /// This may either be a constructor or a static method on the row class.
  final ExecutableElement constructor;

  final Map<DriftColumn, ParameterElement> mapping;

  /// Generate toCompanion for data class
  final bool generateInsertable;

  ExistingRowClass(
    this.targetClass,
    this.constructor,
    this.mapping,
    this.generateInsertable, {
    this.typeInstantiation = const [],
  });

  /// Whether the [constructor] returns a future and thus needs to be awaited
  /// to create an instance of the custom row class.
  bool get isAsyncFactory {
    final typeSystem = targetClass.library.typeSystem;
    return typeSystem.flatten(constructor.returnType) != constructor.returnType;
  }

  String dartType([GenerationOptions options = const GenerationOptions()]) {
    if (typeInstantiation.isEmpty) {
      return targetClass.name;
    } else {
      return targetClass
          .instantiate(
            typeArguments: typeInstantiation,
            nullabilitySuffix: NullabilitySuffix.none,
          )
          .getDisplayString(withNullability: true);
    }
  }
}
