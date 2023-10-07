import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType;
import 'package:sqlparser/sqlparser.dart' as sql;

import 'dart.dart';
import 'element.dart';

import 'column.dart';
import 'result_sets.dart';
import 'types.dart';

class DriftTable extends DriftElementWithResultSet {
  @override
  final List<DriftColumn> columns;

  final List<DriftTableConstraint> tableConstraints;

  @override
  final List<DriftElement> references;

  @override
  final ExistingRowClass? existingRowClass;

  @override
  final AnnotatedDartCode? customParentClass;

  /// The fixed [entityInfoName] to use, overriding the default.
  final String? fixedEntityInfoName;

  /// The default name to use for the [entityInfoName].
  final String baseDartName;

  @override
  final String nameOfRowClass;

  final bool withoutRowId;

  /// Information about the virtual table creating statement backing this table,
  /// if it [isVirtual].
  final VirtualTableData? virtualTableData;

  /// Whether this table is defined as `STRICT`. Support for strict tables has
  /// been added in sqlite 3.37.
  final bool strict;

  /// Whether the migrator should write SQL for [tableConstraints] added to this
  /// table (true by default).
  ///
  /// When disabled, only [overrideTableConstraints] entries will be written
  /// when creating the `CREATE TABLE` statement at runtime.
  final bool writeDefaultConstraints;

  /// When non-empty, the generated table class will override the
  /// `customConstraints` getter in the table class with this value.
  final List<String> overrideTableConstraints;

  /// The names of indices that have been attached to this table using the
  /// `@TableIndex` annotation in drift.
  ///
  /// This field only has the purpose of implicitly adding these indices to each
  /// database adding this table, so that code for that index will get generated
  /// without an explicit reference.
  final List<String> attachedIndices;

  DriftColumn? _rowIdColumn;

  DriftTable(
    super.id,
    super.declaration, {
    required this.columns,
    required this.baseDartName,
    required this.nameOfRowClass,
    this.references = const [],
    this.existingRowClass,
    this.customParentClass,
    this.fixedEntityInfoName,
    this.withoutRowId = false,
    this.strict = false,
    this.tableConstraints = const [],
    this.virtualTableData,
    this.writeDefaultConstraints = true,
    this.overrideTableConstraints = const [],
    this.attachedIndices = const [],
  }) {
    _rowIdColumn = DriftColumn(
      sqlType: ColumnType.drift(DriftSqlType.int),
      nullable: false,
      nameInSql: 'rowid',
      nameInDart: 'rowid',
      declaration: declaration,
      isImplicitRowId: true,
    )..owner = this;
  }

  late final DriftColumn? rowid = _findRowId();

  @override
  DriftElementKind get kind => DriftElementKind.table;

  /// Whether this is a virtual table, created with a `CREATE VIRTUAL TABLE`
  /// statement in SQL.
  bool get isVirtual => virtualTableData != null;

  @override
  String get dbGetterName => DriftSchemaElement.dbFieldName(baseDartName);

  /// The primary key for this table, computed by looking at the primary key
  /// defined as a table constraint or as a column constraint.
  Set<DriftColumn> get fullPrimaryKey {
    final fromTable =
        tableConstraints.whereType<PrimaryKeyColumns>().firstOrNull;

    if (fromTable != null) {
      return fromTable.primaryKey;
    }

    return columns
        .where((c) => c.constraints.any((f) => f is PrimaryKeyColumn))
        .toSet();
  }

  DriftColumn? _findRowId() {
    if (withoutRowId) return null;

    // See if we have an integer primary key as defined by
    // https://www.sqlite.org/lang_createtable.html#rowid
    final primaryKey = fullPrimaryKey;
    if (primaryKey.length == 1) {
      final column = primaryKey.single;
      final builtinType = column.sqlType.builtin;
      if (builtinType == DriftSqlType.int ||
          builtinType == DriftSqlType.bigInt) {
        // So this column is an alias for the rowid
        return column;
      }
    }

    // Otherwise, expose the implicit rowid column.
    return _rowIdColumn;
  }

  /// Determines whether [column] would be required for inserts performed via
  /// companions.
  bool isColumnRequiredForInsert(DriftColumn column) {
    assert(columns.contains(column));

    if (column.defaultArgument != null ||
        column.clientDefaultCode != null ||
        column.nullable ||
        column.isGenerated) {
      // default value would be applied, so it's not required for inserts
      return false;
    }

    if (rowid == column) {
      // If the column is an alias for the rowid, it will get set automatically
      // by sqlite and isn't required for inserts either.
      return false;
    }

    // In other cases, we need a value for inserts into the table.
    return true;
  }

  @override
  String get entityInfoName {
    // if this table was parsed from sql, a user might want to refer to it
    // directly because there is no user defined parent class.
    // So, turn CREATE TABLE users into something called "Users" instead of
    // "$UsersTable".
    final name =
        fixedEntityInfoName ?? _tableInfoNameForTableClass(baseDartName);
    if (name == nameOfRowClass) {
      // resolve clashes if the table info class has the same name as the data
      // class. This can happen because the data class name can be specified by
      // the user.
      return '${name}Table';
    }
    return name;
  }

  static String _tableInfoNameForTableClass(String className) =>
      '\$${className}Table';
}

sealed class DriftTableConstraint {}

final class UniqueColumns extends DriftTableConstraint {
  final Set<DriftColumn> uniqueSet;

  UniqueColumns(this.uniqueSet);
}

final class PrimaryKeyColumns extends DriftTableConstraint {
  final Set<DriftColumn> primaryKey;

  PrimaryKeyColumns(this.primaryKey);
}

final class ForeignKeyTable extends DriftTableConstraint {
  final List<DriftColumn> localColumns;
  final DriftTable otherTable;

  /// The columns matching [localColumns] in the [otherTable].
  final List<DriftColumn> otherColumns;

  final sql.ReferenceAction? onUpdate;
  final sql.ReferenceAction? onDelete;

  ForeignKeyTable({
    required this.localColumns,
    required this.otherTable,
    required this.otherColumns,
    this.onUpdate,
    this.onDelete,
  });
}

class VirtualTableData {
  /// The module used to create this table.
  ///
  /// In `CREATE VIRTUAL TABLE foo USING fts5`, the [module] would be `fts5`.
  final String module;

  /// The argument content immmediately following the [module] in the creating
  /// statement.
  final List<String> moduleArguments;

  final RecognizedVirtualTableModule? recognized;

  /// The module and the arguments in a single string, suitable for `CREATE
  /// VIRTUAL TABLE` statements.
  String get moduleAndArgs {
    return '$module(${moduleArguments.join(', ')})';
  }

  VirtualTableData(this.module, this.moduleArguments, this.recognized);
}

abstract class RecognizedVirtualTableModule {}

class DriftFts5Table extends RecognizedVirtualTableModule {
  /// For fts5 tables with external content (https://www.sqlite.org/fts5.html#external_content_tables),
  /// references the drift table providing the content.
  final DriftTable? externalContentTable;

  /// If this fts5 table has an [externalContentTable] and uses an explicit
  /// column as a rowid, this is a reference to that column.
  final DriftColumn? externalContentRowId;

  DriftFts5Table(this.externalContentTable, this.externalContentRowId)
      : assert(externalContentRowId == null ||
            externalContentRowId.owner == externalContentTable);
}
