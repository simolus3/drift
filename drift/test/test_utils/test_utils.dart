import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';

export 'database_stub.dart'
    if (dart.library.ffi) 'database_vm.dart'
    if (dart.library.js) 'database_web.dart';
export 'matchers.dart';
export 'mocks.dart';

GenerationContext stubContext({DriftDatabaseOptions? options}) {
  return GenerationContext(
      options ?? const DriftDatabaseOptions(), _NullDatabase.instance);
}

class _NullDatabase extends GeneratedDatabase {
  static final instance = _NullDatabase();

  _NullDatabase() : super(_NullExecutor());

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      throw UnsupportedError('stub');

  @override
  int get schemaVersion => throw UnsupportedError('stub!');
}

class _NullExecutor extends Fake implements QueryExecutor {
  @override
  SqlDialect get dialect => SqlDialect.sqlite;
}

class CustomTable extends Table with TableInfo<CustomTable, void> {
  @override
  final String actualTableName;
  @override
  final DatabaseConnectionUser attachedDatabase;
  final List<GeneratedColumn<Object>> columns;
  final String? _alias;

  CustomTable(this.actualTableName, this.attachedDatabase, this.columns,
      [this._alias]);

  @override
  List<GeneratedColumn<Object>> get $columns => columns;

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  CustomTable createAlias(String alias) {
    return CustomTable(actualTableName, attachedDatabase, columns, alias);
  }

  @override
  Future<void> map(Map<String, dynamic> data, {String? tablePrefix}) async {
    return;
  }
}
