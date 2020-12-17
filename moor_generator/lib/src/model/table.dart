import 'package:analyzer/dart/element/element.dart';
import 'package:moor/moor.dart' show UpdateKind;
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

  /// Whether this table was created from an `CREATE TABLE` statement instead of
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
  @override
  String get dbGetterName => dbFieldName(_baseName);
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
  ///
  /// For the full primary key, see [fullPrimaryKey].
  final Set<MoorColumn> primaryKey;

  /// The primary key for this table.
  ///
  /// Unlikely [primaryKey], this method is not limited to the `primaryKey`
  /// override in Dart table declarations.
  Set<MoorColumn> get fullPrimaryKey {
    if (primaryKey != null) return primaryKey;

    return columns.where((c) => c.features.any((f) => f is PrimaryKey)).toSet();
  }

  /// When non-null, the generated table class will override the `withoutRowId`
  /// getter on the table class with this value.
  final bool /*?*/ overrideWithoutRowId;

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
    }

    return declaration.isVirtual;
  }

  /// If this table [isVirtualTable], returns the `CREATE VIRTUAL TABLE`
  /// statement to create this table. Otherwise returns null.
  String get createVirtual {
    if (!isVirtualTable) return null;

    return (declaration as TableDeclarationWithSql).createSql;
  }

  MoorTable({
    this.fromClass,
    this.columns = const [],
    this.sqlName,
    this.dartTypeName,
    this.primaryKey,
    String overriddenName,
    this.overrideWithoutRowId,
    this.overrideTableConstraints,
    this.overrideDontWriteConstraints,
    this.declaration,
  }) : _overriddenName = overriddenName {
    _attachToConverters();
  }

  /// Finds all type converters used in this tables.
  Iterable<UsedTypeConverter> get converters =>
      columns.map((c) => c.typeConverter).where((t) => t != null);

  void _attachToConverters() {
    var index = 0;
    for (final converter in converters) {
      converter
        ..index = index++
        ..table = this;
    }
  }

  /// Determines whether [column] would be required for inserts performed via
  /// companions.
  bool isColumnRequiredForInsert(MoorColumn column) {
    assert(columns.contains(column));

    if (column.defaultArgument != null ||
        column.clientDefaultCode != null ||
        column.nullable) {
      // default value would be applied, so it's not required for inserts
      return false;
    }

    // A column isn't required if it's an alias for the rowid, as explained
    // at https://www.sqlite.org/lang_createtable.html#rowid
    final isWithoutRowId = overrideWithoutRowId ?? false;
    final fullPk = fullPrimaryKey;
    final isAliasForRowId = !isWithoutRowId &&
        column.type == ColumnType.integer &&
        fullPk.length == 1 &&
        fullPk.single == column;

    return !isAliasForRowId;
  }

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

class WrittenMoorTable {
  final MoorTable table;
  final UpdateKind kind;

  WrittenMoorTable(this.table, this.kind);
}

String dbFieldName(String className) => ReCase(className).camelCase;

String tableInfoNameForTableClass(String className) => '\$${className}Table';
