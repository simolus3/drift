part of '../analysis.dart';

/// Something that will resolve to a result set.
abstract class ResolvesToResultSet with Referencable {
  ResultSet get resultSet;
}

abstract class ResultSet implements ResolvesToResultSet {
  List<Column> get resolvedColumns;

  @override
  ResultSet get resultSet => this;

  Column findColumn(String name) {
    return resolvedColumns.firstWhere((c) => c.name == name,
        orElse: () => null);
  }
}

class Table with ResultSet {
  final String name;

  @override
  final List<Column> resolvedColumns;

  Table({@required this.name, this.resolvedColumns});
}
