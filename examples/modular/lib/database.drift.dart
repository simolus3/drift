// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:modular/src/users.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;

abstract class $Database extends i0.GeneratedDatabase {
  $Database(i0.QueryExecutor e) : super(e);
  late final i1.Users users = i1.Users(this);
  i1.UsersDrift get usersDrift =>
      i2.ReadDatabaseContainer(this).accessor<i1.UsersDrift>(
          'package:modular/src/users.drift', i1.UsersDrift.new);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [users];
}
