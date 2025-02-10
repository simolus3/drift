import '../results.dart';
import 'column.dart';

abstract base class ResultSet<Row extends Object,
    Self extends ResultSet<Row, Self>> {
  final String entityName;
  final String? alias;

  List<SchemaColumn> get columns;

  String get aliasOrName => alias ?? entityName;

  late final Map<String, SchemaColumn> columnsByName = {
    for (final column in columns) column.name: column,
  };

  ResultSet({required this.entityName, required this.alias});

  Row? mapToDart(DriftRow row);

  Self withAlias(String alias);

  /// Type-level hack: Result sets are supposed to inherit from the [Self] type
  /// they declare, so this returns just `this`.
  Self asSelfType();
}
