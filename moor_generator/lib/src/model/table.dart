import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

import 'base_entity.dart';
import 'column.dart';
import 'declarations/declaration.dart';

/// A parsed table, declared in code by extending `Table` and referencing that
/// table in `@UseMoor` or `@UseDao`.
class MoorTable implements MoorSchemaEntity {
  /// The [ClassElement] for the class that declares this table or null if
  /// the table was inferred from a `CREATE TABLE` statement.
  final ClassElement fromClass;

  @override
  final TableDeclaration declaration;

  /// The associated table to use for the sqlparser package when analyzing
  /// sql queries. Note that this field is set lazily.
  Table parserTable;

  /// If [fromClass] is null, another source to use when determining the name
  /// of this table in generated Dart code.
  final String _overriddenName;

  /// Whether this table was created from an `ALTER TABLE` statement instead of
  /// a Dart class.
  bool get isFromSql => _overriddenName != null;

  String get _baseName => _overriddenName ?? fromClass.name;

  /// The columns declared in this table.
  final List<MoorColumn> columns;

  /// The name of this table when stored in the database
  final String sqlName;

  /// The name for the data class associated with this table
  final String dartTypeName;

  /// The getter name used for this table in a generated database or dao class.
  String get tableFieldName => _dbFieldName(_baseName);
  String get tableInfoName {
    // if this table was parsed from sql, a user might want to refer to it
    // directly because there is no user defined parent class.
    // So, turn CREATE TABLE users into something called "Users" instead of
    // "$UsersTable".
    final name = _overriddenName ?? tableInfoNameForTableClass(_baseName);
    if (name == dartTypeName) {
      // resolve clashes if the table info class has the same name as the data
      // class. This can happen because the data class name can be specified by
      // the user.
      return '${name}Table';
    }
    return name;
  }

  String getNameForCompanionClass(MoorOptions options) {
    final baseName =
        options.useDataClassNameForCompanions ? dartTypeName : _baseName;
    return '${baseName}Companion';
  }

  /// The set of primary keys, if they have been explicitly defined by
  /// overriding `primaryKey` in the table class. `null` if the primary key has
  /// not been defined that way.
  final Set<MoorColumn> primaryKey;

  /// When non-null, the generated table class will override the `withoutRowId`
  /// getter on the table class with this value.
  final bool overrideWithoutRowId;

  /// When non-null, the generated table class will override the
  /// `dontWriteConstraint` getter on the table class with this value.
  final bool overrideDontWriteConstraints;

  /// When non-null, the generated table class will override the
  /// `customConstraints` getter in the table class with this value.
  final List<String> overrideTableConstraints;

  @override
  final Set<MoorTable> references = {};

  /// Returns whether this table was created from a `CREATE VIRTUAL TABLE`
  /// statement in a moor file
  bool get isVirtualTable {
    if (declaration == null) {
      throw StateError("Couldn't determine whether $displayName is a virtual "
          'table since its declaration is unknown.');
    } else if (declaration is! MoorTableDeclaration) {
      // tables declared in Dart can't be virtual
      return false;
    }

    final node = (declaration as MoorTableDeclaration).node;
    return node is CreateVirtualTableStatement;
  }

  MoorTable({
    this.fromClass,
    this.columns,
    this.sqlName,
    this.dartTypeName,
    this.primaryKey,
    String overriddenName,
    this.overrideWithoutRowId,
    this.overrideTableConstraints,
    this.overrideDontWriteConstraints,
    this.declaration,
  }) : _overriddenName = overriddenName;

  /// Finds all type converters used in this tables.
  Iterable<UsedTypeConverter> get converters =>
      columns.map((c) => c.typeConverter).where((t) => t != null);

  @override
  String get displayName {
    if (isFromSql) {
      return sqlName;
    } else {
      return fromClass.displayName;
    }
  }

  @override
  String toString() {
    return 'SpecifiedTable: $displayName';
  }
}

String _dbFieldName(String className) => ReCase(className).camelCase;

String tableInfoNameForTableClass(String className) => '\$${className}Table';
