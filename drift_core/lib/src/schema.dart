import 'types.dart';

abstract class SchemaEntity {
  String get name;
}

abstract class SchemaColumn<T> {
  String get name;
  SqlType<T> get type;
}

abstract class EntityWithResult implements SchemaEntity {
  List<SchemaColumn> get columns;
}

class SchemaTable implements EntityWithResult {
  @override
  final String name;

  @override
  final List<SchemaColumn> columns;

  SchemaTable({required this.name, required this.columns});
}
