// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:with_built_value/tables.drift.dart' as i1;

abstract class $Database extends i0.GeneratedDatabase {
  $Database(i0.QueryExecutor e) : super(e);
  late final i1.Users users = i1.Users(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [users];
}
