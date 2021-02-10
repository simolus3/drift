import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

import 'base_entity.dart';
import 'declarations/declaration.dart';
import 'model.dart';

/// A parsed view
class MoorView extends MoorSchemaEntity {
  @override
  final MoorViewDeclaration declaration;

  /// The associated view to use for the sqlparser package when analyzing
  /// sql queries. Note that this field is set lazily.
  View parserView;

  final String name;

  @override
  List<MoorSchemaEntity> references = [];

  List<ViewColumn> columns;

  MoorView({
    this.declaration,
    this.name,
  });

  factory MoorView.fromMoor(CreateViewStatement stmt, FoundFile file) {
    return MoorView(
      declaration: MoorViewDeclaration(stmt, file),
      name: stmt.viewName,
    );
  }

  /// The `CREATE VIEW` statement that can be used to create this view.
  String createSql(MoorOptions options) {
    return declaration.formatSqlIfAvailable(options) ?? declaration.createSql;
  }

  @override
  String get dbGetterName => dbFieldName(name);

  @override
  String get displayName => name;
}
