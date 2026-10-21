import 'dart:convert';
import 'dart:typed_data';

import 'package:drift3_preview/drift.dart';
import 'package:drift3_preview/internal/common_dialect.dart';

/// A [DriftDialect] implementation for MariaDB and MySQL.
final class MariaDbDialect extends DriftDialect {
  const MariaDbDialect();

  @override
  bool get supportsIndexedParameters => false;

  @override
  StatementCompiler createCompiler() => _MariaDbStatementCompiler(this);

  @override
  PhysicalSqlType<bool> get boolType => const _MySqlType(
    'BOOL',
    _MySqlType._parseBool,
    needsStringLiteral: false,
  );

  @override
  PhysicalSqlType<Uint8List> get byteArrayType =>
      const CommonByteArrayType('BLOB');

  @override
  PhysicalSqlType<DateTime> get dateTimeType => const _DateTimeType();

  @override
  PhysicalSqlType<double> get doubleType => const CommonDoubleType();

  @override
  PhysicalSqlType<BigInt> get int64Type => const _BigIntType();

  @override
  PhysicalSqlType<int> get intType => const _MySqlType('INT8', int.parse);

  @override
  PhysicalSqlType<DatabaseJson> get jsonType => const _JsonType();

  @override
  KnownSqlDialect? get known => .mariadb;

  @override
  PhysicalSqlType<String> get textType => const CommonTextType();
}

final class _MariaDbStatementCompiler extends StatementCompiler {
  @override
  final MariaDbDialect dialect;

  _MariaDbStatementCompiler(this.dialect);

  @override
  void addPositionalVariable(int index) {
    statement.buffer.write('?');
  }

  @override
  void addVariable(Variable<Object> variable) {
    statement.variables.add(variable);
    addPositionalVariable(-1);
  }

  @override
  void addReference(String name) {
    statement.buffer
      ..write('`')
      ..write(name)
      ..write('`');
  }

  @override
  void addColumnPrimaryKeyConstraint(ColumnPrimaryKeyConstraint constraint) {
    statement.buffer.write('PRIMARY KEY');
    if (constraint.isAutoIncrementing) {
      statement.buffer.write(' AUTO_INCREMENT');
    }
  }

  @override
  void addDoUpdate(DoUpdate<Object, GeneratedTable<Object, dynamic>> clause) {
    statement.buffer.write('ON DUPLICATE KEY UPDATE ');
    final table = currentInsertStatement!.table;

    // ignore: invalid_use_of_internal_member
    final updateSet = clause.createInsertable(table).toColumns(false);
    addUpdateValues(updateSet);
  }

  @override
  void addBegin(BeginStatement stmt) {
    if (stmt.depth == 0) {
      statement.buffer.write('START TRANSACTION');
    } else {
      statement.buffer.write('SAVEPOINT s${stmt.depth}');
    }
  }

  @override
  void addCommit(CommitStatement stmt) {
    if (stmt.depth == 0) {
      statement.buffer.write('COMMIT');
    } else {
      statement.buffer.write('RELEASE SAVEPOINT s${stmt.depth}');
    }
  }

  @override
  void addRollback(RollbackStatement stmt) {
    if (stmt.depth == 0) {
      statement.buffer.write('ROLLBACK');
    } else {
      statement.buffer.write('ROLLBACK TO SAVEPOINT s${stmt.depth}');
    }
  }

  @override
  void addDateExtractionOperator(DateExtractionOperator<Object> e) {
    throw UnimplementedError(
      "The mariadb dialect doesn't support extracting fields from date times",
    );
  }

  @override
  void addUnixTimestampToDateTime(UnixTimestampToDateTime e) {
    addFunctionCallExpression(
      FunctionCallExpression('FROM_UNIXTIME', [e.timestamp]),
    );
  }
}

final class _MySqlType<T extends Object> extends PhysicalSqlType<T> {
  @override
  final String typeName;
  final bool needsStringLiteral;

  final T Function(String) readValue;

  const _MySqlType(
    this.typeName,
    this.readValue, {
    this.needsStringLiteral = true,
  });

  @override
  T dartValue(Object databaseValue) => readValue(databaseValue as String);

  @override
  String sqlLiteral(T value) {
    final asString = value.toString();
    if (needsStringLiteral) {
      return const CommonTextType().sqlLiteral(asString);
    } else {
      return asString;
    }
  }

  @override
  String? sqlParameter(T? value) => value?.toString();

  static bool _parseBool(String source) {
    return source == '0' ? false : true;
  }
}

final class _BigIntType extends _MySqlType<BigInt> {
  const _BigIntType() : super('INT8', BigInt.parse);

  @override
  BigInt dartValue(Object databaseValue) {
    return BigInt.from(databaseValue as int);
  }
}

final class _JsonType extends _MySqlType<DatabaseJson> {
  const _JsonType() : super('JSON', _read);

  @override
  String? sqlParameter(DatabaseJson? value) {
    return value == null ? null : json.encode(value.dartValue);
  }

  static DatabaseJson _read(String value) => DatabaseJson(json.decode(value));
}

final class _DateTimeType extends _MySqlType<DateTime> {
  const _DateTimeType() : super('DATETIME', DateTime.parse);
}
