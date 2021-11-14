import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/utils/names.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

import '../../writer.dart';
import 'base_entity.dart';
import 'declarations/declaration.dart';
import 'model.dart';

/// A parsed view
class MoorView extends MoorEntityWithResultSet {
  @override
  final ViewDeclaration? declaration;

  /// The associated view to use for the sqlparser package when analyzing
  /// sql queries. Note that this field is set lazily.
  View? parserView;

  ParsedMoorFile? file;

  final String name;

  @override
  List<MoorSchemaEntity> references = [];

  @override
  late List<MoorColumn> columns;

  @override
  String dartTypeName;

  @override
  String entityInfoName;

  @override
  ExistingRowClass? existingRowClass;

  final List<String> staticReferences;

  final ViewQueryInformation? viewQuery;

  MoorView({
    this.declaration,
    required this.name,
    required this.dartTypeName,
    required this.entityInfoName,
    this.existingRowClass,
    this.staticReferences = const [],
    this.viewQuery,
  });

  @override
  String dartTypeCode([GenerationOptions options = const GenerationOptions()]) {
    return existingRowClass?.dartType(options) ?? dartTypeName;
  }

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
    final entityInfoName = ReCase(stmt.viewName).pascalCase;
    final dataClassName = dataClassNameForClassName(entityInfoName);

    return MoorView(
      declaration: MoorViewDeclaration(stmt, file),
      name: stmt.viewName,
      dartTypeName: dataClassName,
      entityInfoName: entityInfoName,
    );
  }

  /// The `CREATE VIEW` statement that can be used to create this view.
  String createSql(MoorOptions options) {
    final decl = declaration as MoorViewDeclaration?;
    if (decl == null) {
      throw StateError('Cannot show SQL for views without a declaration');
    }

    return decl.formatSqlIfAvailable(options) ?? decl.createSql;
  }

  @override
  String get dbGetterName => dbFieldName(name);

  @override
  String get displayName => name;
}

class ViewQueryInformation {
  final List<MoorColumn> columns;
  final String from;
  final String query;

  ViewQueryInformation(this.columns, this.from, this.query);
}
