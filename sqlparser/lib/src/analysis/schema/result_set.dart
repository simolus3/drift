part of '../analysis.dart';

/// Something that will resolve to an [ResultSet] when referred to via
/// the [ReferenceScope].
abstract class ResolvesToResultSet with Referencable {
  ResultSet? get resultSet;
}

/// Something that returns a set of columns when evaluated.
abstract class ResultSet implements ResolvesToResultSet {
  /// The columns that will be returned when evaluating this query.
  List<Column>? get resolvedColumns;

  @override
  ResultSet get resultSet => this;

  @override
  bool get visibleToChildren => false;

  Column? findColumn(String name) {
    return resolvedColumns!.firstWhereOrNull((c) => c.name == name);
  }
}

/// A custom result set that has columns but isn't a table.
class CustomResultSet with ResultSet {
  @override
  final List<Column> resolvedColumns;

  CustomResultSet(this.resolvedColumns);
}

/// Something that returns a set of Columns and can be referenced by a name,
/// such as a table or a view.
abstract class NamedResultSet extends ResultSet {
  /// The name of this result set, as it appears in sql statements. This should
  /// be the raw name, not an escaped version.
  ///
  /// To obtain an escaped name, use [escapedName].
  String get name;

  /// If [name] is a reserved sql keyword, wraps it in double ticks. Otherwise
  /// just returns the [name] directly.
  String get escapedName {
    return isKeywordLexeme(name) ? '"$name"' : name;
  }
}

extension UnaliasResultSet on ResultSet {
  ResultSet unalias() {
    var $this = this;
    while ($this is TableAlias) {
      $this = $this.delegate;
    }

    return $this;
  }
}
