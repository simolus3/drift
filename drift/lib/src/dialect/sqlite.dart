import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart' show jsonb;

import '../connections/connection.dart';
import '../dsl/columns.dart';
import '../dsl/table.dart';
import '../query_builder.dart';
import '../query_builder/compiler.dart';
import '../runtime/migrations.dart';

extension DriftAnyColumnBuilder on Table {
  /// Use this as a the body of a getter to declare a column that holds
  /// arbitrary values not modified by drift at runtime.
  ///
  /// The type of this column in the schema is `ANY`, which is particularly
  /// useful for columns with an unknown type in [isStrict] tables.
  /// This type has no direct equivalent for other database engines.
  @protected
  @DriftColumnDeclarationBuilder.forCustom(SqliteDialect.anyType)
  ColumnBuilder<DriftAny> sqliteAny() => throw '';
}

/// A column storing arbitrary values using SQLite's `ANY` type.
typedef AnyColumn = SchemaColumn<DriftAny>;

final class SqliteOptions {
  final bool strictTablesByDefault;
  final bool storeDateTimesAsText;
  final bool useBinaryJsonRepresentation;

  const SqliteOptions({
    this.strictTablesByDefault = true,
    this.storeDateTimesAsText = true,
    this.useBinaryJsonRepresentation = false,
  });
}

final class SqliteDialect extends DriftDialect {
  final SqliteOptions options;

  const SqliteDialect({this.options = const SqliteOptions()});

  @override
  KnownSqlDialect? get known => KnownSqlDialect.sqlite;

  @override
  StatementCompiler createCompiler() => _SqliteCompiler(this);

  @override
  SqlType<bool> get boolType => const _BoolType();

  @override
  SqlType<Uint8List> get byteArrayType => const _BlobType();

  @override
  SqlType<DateTime> get dateTimeType => const _DateTimeType();

  @override
  SqlType<double> get doubleType => const _DoubleType();

  @override
  SqlType<int> get intType => const _IntType();

  @override
  SqlType<BigInt> get int64Type => const _BigIntType();

  @override
  SqlType<DatabaseJson> get jsonType => const _JsonType();

  @override
  SqlType<String> get textType => const _StringType();

  static SqlType<DriftAny> anyType() => const _AnyType();
}

final class _SqliteCompiler extends StatementCompiler {
  @override
  final SqliteDialect dialect;

  _SqliteCompiler(this.dialect);

  @override
  void addPositionalVariable(int index) {
    statement.buffer
      ..write('?')
      ..write(index);
  }

  @override
  void addCreateTableStatement(CreateTableStatement stmt) {
    super.addCreateTableStatement(stmt);

    final table = stmt.entity;
    final options = [
      if (table.withoutRowId) 'WITHOUT ROWID',
      if (table.isStrict) 'STRICT'
    ].join(', ');

    if (options.isNotEmpty) {
      statement.buffer
        ..write(' ')
        ..write(options);
    }
  }
}

abstract base class _SqliteType<T extends Object> implements SqlType<T> {
  final String name;

  const _SqliteType(this.name);

  @override
  T dartValue(DriftDialect dialect, Object databaseValue) {
    return databaseValue as T;
  }

  @override
  Object sqlParameter(DriftDialect dialect, T value) {
    return value;
  }

  @override
  String typeName(DriftDialect dialect) => name;
}

final class _SqlTypeWithoutMapping<T extends Object> extends _SqliteType<T> {
  const _SqlTypeWithoutMapping(super.name);

  @override
  String sqlLiteral(DriftDialect dialect, T value) {
    return value.toString();
  }
}

final class _BlobType extends _SqliteType<Uint8List> {
  const _BlobType() : super('BLOB');

  @override
  String sqlLiteral(DriftDialect dialect, Uint8List value) {
    final String hexString = hex.encode(value);
    return "x'$hexString'";
  }
}

final class _BoolType extends _SqlTypeWithoutMapping<bool> {
  const _BoolType() : super('BOOLEAN');

  @override
  bool dartValue(DriftDialect dialect, Object databaseValue) {
    return databaseValue != 0 && databaseValue != false;
  }
}

final class _DoubleType extends _SqlTypeWithoutMapping<double> {
  const _DoubleType() : super('REAL');

  @override
  double dartValue(DriftDialect dialect, Object databaseValue) {
    return switch (databaseValue) {
      BigInt() => databaseValue.toDouble(),
      _ => (databaseValue as num).toDouble(),
    };
  }
}

final class _IntType extends _SqlTypeWithoutMapping<int> {
  const _IntType() : super('INTEGER');

  @override
  int dartValue(DriftDialect dialect, Object databaseValue) {
    return switch (databaseValue) {
      int() => databaseValue,
      BigInt() => databaseValue.toInt(),
      double() => databaseValue.toInt(),
      _ => int.parse(databaseValue.toString()),
    };
  }
}

final class _BigIntType extends _SqlTypeWithoutMapping<BigInt> {
  const _BigIntType() : super('INTEGER');

  @override
  BigInt dartValue(DriftDialect dialect, Object databaseValue) {
    return switch (databaseValue) {
      int() => BigInt.from(databaseValue),
      BigInt() => databaseValue,
      double() => BigInt.from(databaseValue.toInt()),
      _ => BigInt.parse(databaseValue.toString()),
    };
  }
}

final class _DateTimeType extends _SqliteType<DateTime> {
  const _DateTimeType() : super('TEXT');

  bool _dateTimesAsText(DriftDialect dialect) {
    return (dialect as SqliteDialect).options.storeDateTimesAsText;
  }

  @override
  Object sqlParameter(DriftDialect dialect, DateTime value) {
    if (_dateTimesAsText(dialect)) {
      // sqlite3 assumes UTC by default, so we store the explicit UTC offset
      // along with the value. For UTC datetimes, there's nothing to change
      if (value.isUtc) {
        return value.toIso8601String();
      } else {
        final offset = value.timeZoneOffset;
        // Quick sanity check: We can only store the UTC offset as `hh:mm`,
        // so if the offset has seconds for some reason we should refuse to
        // store that.
        if (offset.inSeconds - 60 * offset.inMinutes != 0) {
          throw ArgumentError.value(dartValue, 'dartValue',
              'Cannot be mapped to SQL: Invalid UTC offset $offset');
        }

        final hours = offset.inHours.abs();
        final minutes = offset.inMinutes.abs() - 60 * hours;

        // For local date times, add the offset as ` +hh:mm` in the end. This
        // format is understood by `DateTime.parse` and date time functions in
        // sqlite.
        final prefix = offset.isNegative ? ' -' : ' +';
        final formattedOffset = '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}';

        return '${value.toIso8601String()}$prefix$formattedOffset';
      }
    } else {
      return value.millisecondsSinceEpoch ~/ 1000;
    }
  }

  @override
  String sqlLiteral(DriftDialect dialect, DateTime value) {
    final param = sqlParameter(dialect, value);
    return switch (param) {
      String s => "'$s'",
      final other => other.toString(),
    };
  }

  @override
  String typeName(DriftDialect dialect) {
    return _dateTimesAsText(dialect) ? 'TEXT' : 'INTEGER';
  }
}

final class _JsonType extends _SqliteType<DatabaseJson> {
  const _JsonType() : super('BLOB');

  bool _useBinary(DriftDialect dialect) {
    return (dialect as SqliteDialect).options.useBinaryJsonRepresentation;
  }

  @override
  String sqlLiteral(DriftDialect dialect, DatabaseJson value) {
    final binary = _useBinary(dialect);
    if (binary) {
      return const _BlobType()
          .sqlLiteral(dialect, jsonb.encode(value.dartValue));
    } else {
      return const _StringType()
          .sqlLiteral(dialect, json.encode(value.dartValue));
    }
  }

  @override
  Object sqlParameter(DriftDialect dialect, DatabaseJson value) {
    if (_useBinary(dialect)) {
      return jsonb.encode(value.dartValue);
    } else {
      return json.encode(value.dartValue);
    }
  }

  @override
  DatabaseJson dartValue(DriftDialect dialect, Object databaseValue) {
    if (_useBinary(dialect)) {
      return DatabaseJson(
          jsonb.decode(const _BlobType().dartValue(dialect, databaseValue)));
    } else {
      return DatabaseJson(
          json.decode(const _StringType().dartValue(dialect, databaseValue)));
    }
  }

  @override
  String typeName(DriftDialect dialect) {
    return _useBinary(dialect) ? 'BLOB' : 'TEXT';
  }
}

final class _StringType extends _SqliteType<String> {
  const _StringType() : super('TEXT');

  @override
  String dartValue(DriftDialect dialect, Object databaseValue) {
    return databaseValue.toString();
  }

  @override
  String sqlLiteral(DriftDialect dialect, String value) {
    // From the sqlite docs: (https://www.sqlite.org/lang_expr.html)
    // A string constant is formed by enclosing the string in single quotes
    // (').
    // A single quote within the string can be encoded by putting two single
    // quotes in a row - as in Pascal. C-style escapes using the backslash
    // character are not supported because they are not standard SQL.
    final escapedChars = value.replaceAll('\'', '\'\'');
    return "'$escapedChars'";
  }
}

extension type DriftAny(Object fromDb) implements Object {}

final class _AnyType extends _SqliteType<DriftAny> {
  const _AnyType() : super('ANY');

  @override
  String sqlLiteral(DriftDialect dialect, DriftAny value) {
    throw 'TODO';
  }

  @override
  Object sqlParameter(DriftDialect dialect, DriftAny value) {
    return value.fromDb;
  }

  @override
  DriftAny dartValue(DriftDialect dialect, Object databaseValue) {
    return DriftAny(databaseValue);
  }
}

extension SqliteSpecificStringOperators on Expression<String> {
  /// Matches this string against the regular expression in [regex].
  ///
  /// The [multiLine], [caseSensitive], [unicode] and [dotAll] parameters
  /// correspond to the parameters on [RegExp].
  ///
  /// Note that this function is only available when using a `NativeDatabase`.
  /// If you need to support the web or `moor_flutter`, consider using [like]
  /// instead.
  Expression<bool> regexp(
    String regex, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) {
    // We have a special regexp sql function that takes a third parameter
    // to encode flags. If the least significant bit is set, multiLine is
    // enabled. The next three bits enable case INSENSITIVITY (it's sensitive
    // by default), unicode and dotAll.
    var flags = 0;

    if (multiLine) {
      flags |= 1;
    }
    if (!caseSensitive) {
      flags |= 2;
    }
    if (unicode) {
      flags |= 4;
    }
    if (dotAll) {
      flags |= 8;
    }

    if (flags != 0) {
      return FunctionCallExpression<bool>(
        'regexp_moor_ffi',
        [
          Variable.withString(regex),
          this,
          Variable.withInt(flags),
        ],
      );
    }

    // No special flags enabled, use the regular REGEXP operator
    return BinaryExpression(
        this, BinaryOperator.regexp, Variable.withString(regex));
  }
}

/// Contains instructions needed to run a complex migration on a table, using
/// the steps described in [Making other kinds of table schema changes](https://www.sqlite.org/lang_altertable.html#otheralter).
///
/// For examples and more details, see [the documentation](https://drift.simonbinder.eu/docs/advanced-features/migrations/#complex-migrations).
class TableMigration {
  /// The table to migrate. It is assumed that this table already exists at the
  /// time the migration is running. If you need to create a new table, use
  /// [Migrator.createTable] instead of the more complex [TableMigration].
  final GeneratedTable<Object, GeneratedTable> affectedTable;

  /// A list of new columns that are known to _not_ exist in the database yet.
  ///
  /// If these columns aren't set through the [columnTransformer], they must
  /// have a default value.
  final List<TableColumn> newColumns;

  /// A map describing how to transform columns of the [affectedTable].
  ///
  /// A key in the map refers to the new column in the table. If you're running
  /// a [TableMigration] to add new columns, those columns doesn't have to exist
  /// in the database yet.
  /// The value associated with a column is the expression to use when
  /// transforming the new table.
  final Map<TableColumn, Expression> columnTransformer;

  /// Creates migration description on the [affectedTable].
  TableMigration(
    this.affectedTable, {
    this.columnTransformer = const {},
    this.newColumns = const [],
  }) {
    // All new columns must either have a transformation or a default value of
    // some kind
    final problematicNewColumns = <String>[];
    for (final column in newColumns) {
      // isRequired returns false if the column has a client default value that
      // would be used for inserts. We can't apply the client default here
      // though, so it doesn't count as a default value.
      final isRequired =
          column.requiredDuringInsert || column.clientDefault != null;
      if (isRequired && !columnTransformer.containsKey(column)) {
        problematicNewColumns.add(column.name);
      }
    }

    if (problematicNewColumns.isNotEmpty) {
      throw ArgumentError(
        "Some of the newColumns don't have a default value and aren't included "
        'in columnTransformer: ${problematicNewColumns.join(', ')}. \n'
        'To add columns, make sure that they have a default value or write an '
        'expression to use in the columnTransformer map.',
      );
    }
  }
}

extension SqliteMigrator on Migrator {
  /// Alter columns of an existing table.
  ///
  /// Since sqlite does not provide a way to alter the type or constraint of an
  /// individual column, one needs to write a fairly complex migration procedure
  /// for this.
  /// [alterTable] will run the [12 step procedure][other alter] recommended by
  /// sqlite.
  ///
  /// The [migration] to run describes the transformation to apply to the table.
  /// The individual fields of the [TableMigration] class contain more
  /// information on the transformations supported at the moment. Drifts's
  /// [documentation][drift docs] also contains more details and examples for
  /// common migrations that can be run with [alterTable].
  ///
  /// When deleting columns from a table, make sure to migrate tables that have
  /// a foreign key constraint on those columns first.
  ///
  /// While this function will re-create affected indexes and triggers, it does
  /// not reliably handle views at the moment.
  ///
  /// [other alter]: https://www.sqlite.org/lang_altertable.html#otheralter
  /// [drift docs]: https://drift.simonbinder.eu/docs/advanced-features/migrations/#complex-migrations
  Future<void> alterTable(TableMigration migration) async {
    final foreignKeysEnabled =
        (await database.customSelect('PRAGMA foreign_keys').getSingle())
            .read<bool>('foreign_keys');
    bool? legacyAlterTable =
        (await database.customSelect('PRAGMA legacy_alter_table').getSingle())
            .read<bool>('legacy_alter_table');

    if (foreignKeysEnabled) {
      await database.customStatement('PRAGMA foreign_keys = OFF;');
    }

    final table = migration.affectedTable;
    final tableName = table.entityName;

    await database.transaction(() async {
      // We will drop the original table later, which will also delete
      // associated triggers, indices and and views. We query sqlite_schema to
      // re-create those later.
      // We use the legacy sqlite_master table since the _schema rename happened
      // in a very recent version (3.33.0)
      final schemaQuery = await database.customSelect(
        'SELECT type, name, sql FROM sqlite_master WHERE tbl_name = ?;',
        variables: [Variable<String>(tableName)],
      ).get();

      final createAffected = <String>[];

      for (final row in schemaQuery) {
        final type = row.read<String>('type');
        final sql = row.readNullable<String>('sql');
        final name = row.read<String>('name');

        if (sql == null) {
          // These indexes are created by sqlite to enforce different kinds of
          // special constraints.
          // They do not have any SQL create statement as they are created
          // automatically by the constraints on the table.
          // They can not be re-created and need to be skipped.
          assert(name.startsWith('sqlite_autoindex'));
          continue;
        }

        switch (type) {
          case 'trigger':
          case 'view':
          case 'index':
            createAffected.add(sql);
            break;
        }
      }

      // Step 4: Create the new table in the desired format
      final temporaryName = 'tmp_for_copy_$tableName';
      final temporaryTable = table.withAlias(temporaryName);
      await createTable(temporaryTable);

      // Step 5: Transfer old content into the new table
      final compiler = database.dialect.createCompiler();
      final expressionsForSelect = <Expression>[];

      compiler.statement.buffer.write('INSERT INTO $temporaryName (');
      var first = true;
      for (final column in table.columns) {
        if (column.constraints.any((e) => e is ColumnGeneratedAs)) continue;

        final transformer = migration.columnTransformer[column];

        if (transformer != null || !migration.newColumns.contains(column)) {
          // New columns without a transformer have a default value, so we don't
          // include them in the column list of the insert.
          // Otherwise, we prefer to use the column transformer if set. If there
          // isn't a transformer, just copy the column from the old table,
          // without any transformation.
          final expression = migration.columnTransformer[column] ?? column;
          expressionsForSelect.add(expression);

          if (!first) compiler.statement.comma();
          compiler.addReference(column.name);
          first = false;
        }
      }

      compiler.statement.buffer.write(') SELECT ');
      first = true;
      for (final expr in expressionsForSelect) {
        if (!first) compiler.statement.comma();
        expr.compileWith(compiler);
        first = false;
      }
      compiler.statement.buffer.write(' FROM ');
      compiler.addReference(tableName);
      compiler.statement.buffer.write(';');
      (await database.currentSession())
          .execute(StatementInfo(compiler.statement));

      // Step 6: Drop the old table
      await database.runStatement(DropStatement('TABLE', tableName));

      // This step is not mentioned in the documentation, but: If we use `ALTER`
      // on an inconsistent schema (and it is inconsistent right now because
      // we've just dropped the original table), we need to enable the legacy
      // option which skips the integrity check.
      // See also: https://sqlite.org/forum/forumpost/0e2390093fbb8fd6
      if (legacyAlterTable == false) {
        try {
          await database.customStatement('pragma legacy_alter_table = 1;');
        } on Object {
          // On some databases like Turso, legacy_alter_table is not writable.
          legacyAlterTable = null;

          // A workaround is to drop all views and to re-create them later.
          // We're not doing this by default to ensure we're not breaking
          // existing users (e.g. if the new table references a view somehow).
          final allViews = await database.customSelect(
            'SELECT name, sql FROM sqlite_master WHERE type = ?;',
            variables: [Variable<String>('view')],
          ).get();

          for (final row in allViews) {
            final sql = row.read<String>('sql');
            if (!createAffected.contains(sql)) {
              createAffected.add(sql);
            }

            final name = row.read<String>('name');
            await database.customStatement('DROP VIEW "$name";');
          }
        }
      }

      // Step 7: Rename the new table to the old name
      await database.runStatement(RenameTableStatement(temporaryName, table));

      if (legacyAlterTable == false) {
        await database.customStatement('pragma legacy_alter_table = 0;');
      }

      // Step 8: Re-create associated indexes, triggers and views
      for (final stmt in createAffected) {
        await database.customStatement(stmt);
      }

      // We don't currently check step 9 and 10, step 11 happens implicitly.
    });

    // Finally, re-enable foreign keys if they were enabled originally.
    if (foreignKeysEnabled) {
      await database.customStatement('PRAGMA foreign_keys = ON;');
    }
  }
}
