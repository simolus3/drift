import 'dart:async';

import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/components/limit.dart';
import 'package:sally/src/runtime/database.dart';
import 'package:sally/src/runtime/executor/stream_queries.dart';
import 'package:sally/src/runtime/statements/query.dart';
import 'package:sally/src/runtime/structure/table_info.dart';

typedef OrderingTerm OrderClauseGenerator<T>(T tbl);

class SelectStatement<T, D> extends Query<T, D>
    implements TableChangeListener<List<D>> {
  SelectStatement(QueryEngine database, TableInfo<T, D> table)
      : super(database, table);

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.buffer.write('SELECT * FROM ${table.$tableName}');
  }

  /// Loads and returns all results from this select query.
  Future<List<D>> get() async {
    final ctx = constructQuery();

    final results = await ctx.database.executor.doWhenOpened((e) async {
      return await ctx.database.executor.runSelect(ctx.sql, ctx.boundVariables);
    });
    return results.map(table.map).toList();
  }

  /// Limits the amount of rows returned by capping them at [limit]. If [offset]
  /// is provided as well, the first [offset] rows will be skipped and not
  /// included in the result.
  void limit(int limit, {int offset}) {
    limitExpr = Limit(limit, offset);
  }

  /// Orders the result by the given clauses. The clauses coming first in the
  /// list have a higher priority, the later clauses are only considered if the
  /// first clause considers two rows to be equal.
  void orderBy(List<OrderClauseGenerator<T>> clauses) {
    orderByExpr = OrderBy(clauses.map((t) => t(table.asDslTable)).toList());
  }

  /// Creates an auto-updating stream that emits new items whenever this table
  /// changes.
  Stream<List<D>> watch() {
    return database.createStream(this);
  }

  @override
  Future<List<D>> handleDataChanged() {
    return get();
  }

  @override
  bool isAffectedBy(String table) {
    return table == super.table.$tableName;
  }
}

class CustomSelectStatement implements TableChangeListener<List<QueryRow>> {
  /// Tables this select statement reads from
  final Set<TableInfo> tables;
  final String query;
  final List<Variable> variables;
  final QueryEngine db;

  CustomSelectStatement(this.query, this.variables, this.tables, this.db);

  Future<List<QueryRow>> read() => handleDataChanged();

  @override
  Future<List<QueryRow>> handleDataChanged() async {
    final ctx = GenerationContext(db);
    final mappedArgs = variables.map((v) => v.mapToSimpleValue(ctx)).toList();

    final result =
        await db.executor.doWhenOpened((e) => e.runSelect(query, mappedArgs));

    return result.map((row) => QueryRow(row, db)).toList();
  }

  @override
  bool isAffectedBy(String table) {
    return tables.any((t) => t.$tableName == table);
  }
}

/// For custom select statement, represents a row in the result set.
class QueryRow {
  final Map<String, dynamic> data;
  final QueryEngine _db;

  QueryRow(this.data, this._db);

  /// Reads an arbitrary value from the row and maps it to a fitting dart type.
  /// The dart type [T] must be supported by the type system of the database
  /// used (mostly contains booleans, strings, integers and dates).
  T read<T>(String key) {
    final type = _db.typeSystem.forDartType<T>();

    return type.mapFromDatabaseResponse(data[key]);
  }

  /// Reads a bool from the column named [key].
  bool readBool(String key) => read<bool>(key);

  /// Reads a string from the column named [key].
  String readString(String key) => read<String>(key);

  /// Reads a int from the column named [key].
  int readInt(String key) => read<int>(key);

  /// Reads a [DateTime] from the column named [key].
  DateTime readDateTime(String key) => read<DateTime>(key);
}
