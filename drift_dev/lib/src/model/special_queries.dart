import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import 'model.dart';

enum SpecialQueryMode {
  atCreate,
}

/// A special query, such as the ones executes when the database was created.
///
/// Those are generated from `@created:` queries in moor files.
class SpecialQuery implements MoorSchemaEntity {
  final String sql;
  final SpecialQueryMode mode;
  @override
  final SpecialQueryDeclaration declaration;

  SpecialQuery(this.sql, this.declaration,
      [this.mode = SpecialQueryMode.atCreate]);

  factory SpecialQuery.fromMoor(DeclaredStatement stmt, FoundFile file) {
    return SpecialQuery(stmt.statement.span!.text,
        MoorSpecialQueryDeclaration.fromNodeAndFile(stmt, file));
  }

  @override
  String? get dbGetterName => null;

  @override
  String get displayName =>
      throw UnsupportedError("Special queries don't have a name");

  @override
  List<MoorTable> references = [];

  String formattedSql(MoorOptions options) {
    final decl = declaration;
    if (decl is MoorSpecialQueryDeclaration && options.newSqlCodeGeneration) {
      return decl.node.statement
          .toSql(compatibleMode: options.compatibleModeGeneration);
    }
    return sql;
  }
}
