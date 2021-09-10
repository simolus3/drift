import 'package:built_value/built_value.dart';
import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';

part 'database.g.dart';
part 'database.moor.dart';

abstract class Foo implements Built<Foo, FooBuilder> {
  User get moorField;

  Foo._();

  factory Foo([void Function(FooBuilder) updates]) = _$Foo;
}

@UseMoor(include: {'tables.moor'})
class Database extends _$Database {
  Database() : super(VmDatabase.memory());

  @override
  int get schemaVersion => 1;
}
