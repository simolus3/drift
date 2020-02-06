import 'package:built_value/built_value.dart';
import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';

part 'database.moor.dart';
part 'database.g.dart';

abstract class Foo implements Built<Foo, FooBuilder> {
  SomeInt get moorField;

  Foo._();

  factory Foo([void Function(FooBuilder) updates]) = _$Foo;
}

class SomeInts extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@UseMoor(tables: [SomeInts])
class Database extends _$Database {
  Database() : super(VmDatabase.memory());

  @override
  int get schemaVersion => 1;
}
