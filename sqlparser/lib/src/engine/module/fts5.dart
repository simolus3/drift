import 'package:meta/meta.dart';
import 'package:sqlparser/sqlparser.dart';

final _rankColumn = _Fts5RankColumn();

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
      : super(name: name, resolvedColumns: columns, definition: definition);

  @override
  Column findColumn(String name) {
    if (name == 'rank') {
      return _rankColumn;
    }
    return super.findColumn(name);
  }
}

class _Fts5RankColumn extends TableColumn {
  _Fts5RankColumn() : super('rank', const ResolvedType(type: BasicType.int));
}
