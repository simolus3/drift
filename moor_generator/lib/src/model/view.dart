//@dart=2.9
import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:sqlparser/sqlparser.dart';

import 'base_entity.dart';
import 'declarations/declaration.dart';
import 'model.dart';

/// A parsed view
class MoorView extends MoorEntityWithResultSet {
  @override
  final MoorViewDeclaration declaration;

  /// The associated view to use for the sqlparser package when analyzing
  /// sql queries. Note that this field is set lazily.
  View parserView;

  ParsedMoorFile file;

  final String name;

  @override
  List<MoorSchemaEntity> references = [];

  @override
  List<MoorColumn> columns;

  @override
  String get dartTypeName => 'ViewData$name'; // todo: Names

  @override
  String get entityInfoName => '_View$name';

  MoorView({
    this.declaration,
    this.name,
  });

  /// Obtains all tables transitively referenced by the declaration of this
  /// view.
  ///
  /// This includes all tables in [references]. If this view references other
  /// views, their [transitiveTableReferences] will be included as well.
  Set<MoorTable> get transitiveTableReferences {
    return {
      for (final reference in references)
        if (reference is MoorTable)
          reference
        else if (reference is MoorView)
          ...reference.transitiveTableReferences,
    };
  }

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
