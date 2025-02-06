import '../results.dart';
import 'column.dart';

abstract base class ResultSet<Row extends Object,
    Self extends ResultSet<Row, Self>> {
  final String name;
  final String? alias;

  List<SchemaColumn> get columns;

  String get aliasOrName => alias ?? name;

  late final Map<String, SchemaColumn> columnsByName = {
    for (final column in columns) column.name: column,
  };

  ResultSet({required this.name, required this.alias});

  Row? mapToDart(DriftRow row);

  Self withAlias(String alias);
}
