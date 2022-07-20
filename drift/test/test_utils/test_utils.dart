import 'package:drift/drift.dart';

export 'database_stub.dart'
    if (dart.library.ffi) 'database_vm.dart'
    if (dart.library.js) 'database_web.dart';
export 'matchers.dart';
export 'mocks.dart';

class CustomTable extends Table with TableInfo<CustomTable, Null> {
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
  Null map(Map<String, dynamic> data, {String? tablePrefix}) => null;
}
