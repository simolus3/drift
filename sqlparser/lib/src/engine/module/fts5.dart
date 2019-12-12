import 'package:meta/meta.dart';
import 'package:sqlparser/sqlparser.dart';

class Fts5Extension implements Extension {
  const Fts5Extension();

  @override
  void register(SqlEngine engine) {
    engine.registerModule(_Fts5Module());
  }
}

/// FTS5 module for `CREATE VIRTUAL TABLE USING fts5` support
class _Fts5Module extends Module {
  _Fts5Module() : super('fts5');

  @override
  Table parseTable(CreateVirtualTableStatement stmt) {
    // arguments with an equals sign are parameters passed to the fts5 module.
    // they're not part of the schema.
    final columnNames =
        stmt.argumentContent.where((arg) => !arg.contains('=')).map((c) {
      // actual syntax is <name> <options...>
      return c.trim().split(' ').first;
    });

    return _Fts5Table(
      name: stmt.tableName,
      columns: [
        for (var arg in columnNames)
          TableColumn(arg, const ResolvedType(type: BasicType.text)),
      ],
      definition: stmt,
    );
  }
}

class _Fts5Table extends Table {
  _Fts5Table(
      {@required String name,
      List<TableColumn> columns,
      CreateVirtualTableStatement definition})
      : super(
          name: name,
          resolvedColumns: [
            ...columns,
            _Fts5RankColumn(),
            _Fts5TableColumn(name),
          ],
          definition: definition,
        );
}

/// The rank column, which we introduce to support queries like
/// ```
/// SELECT * FROM my_fts_table WHERE my_fts_table MATCH 'foo' ORDER BY rank;
/// ```
class _Fts5RankColumn extends TableColumn {
  @override
  bool get includedInResults => false;

  _Fts5RankColumn() : super('rank', const ResolvedType(type: BasicType.int));
}

/// A column that has the same name as the fts5 it's from. We introduce this
/// column to support constructs like
/// ```
/// CREATE VIRTUAL TABLE foo USING fts5(bar, baz);
/// query: SELECT * FROM foo WHERE foo MATCH 'something';
/// ```
/// The easiest way to support that is to just make "foo" a column on that
/// table.
class _Fts5TableColumn extends TableColumn {
  @override
  bool get includedInResults => false;

  _Fts5TableColumn(String name)
      : super(name, const ResolvedType(type: BasicType.text));
}
