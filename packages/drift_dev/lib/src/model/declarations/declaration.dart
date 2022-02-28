import 'package:analyzer/dart/element/element.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/model/sources.dart';
import 'package:drift_dev/src/writer/queries/sql_writer.dart';
import 'package:sqlparser/sqlparser.dart';

import '../table.dart';

part 'columns.dart';
part 'database.dart';
part 'index.dart';
part 'special_queries.dart';
part 'tables.dart';
part 'trigger.dart';
part 'views.dart';

/// Interface for model elements that are declared somewhere.
abstract class HasDeclaration {
  /// Gets the declaration of this element, if set.
  Declaration? get declaration;
}

/// Base class for all declarations in the generator model.
abstract class Declaration {
  /// The file and text span where this element was declared.
  SourceRange get declaration;
}

/// Declaration for elements that are declared in a `.dart` file.
abstract class DartDeclaration extends Declaration {
  /// A fitting, enclosing element for this declaration.
  Element get element;
}

/// Declaration for elements that are declared in a `.moor` file.
abstract class MoorDeclaration extends Declaration {
  /// The ast node from a moor file for this declaration.
  AstNode get node;
}

extension ToSql on MoorDeclaration {
  String exportSql(MoorOptions options) {
    if (options.newSqlCodeGeneration) {
      final writer = SqlWriter(options, escapeForDart: false);
      return writer.writeSql(node);
    } else {
      return node.span!.text;
    }
  }
}

extension ToSqlIfAvailable on Declaration {
  String? formatSqlIfAvailable(MoorOptions options) {
    final $this = this;
    if ($this is MoorDeclaration) {
      return $this.exportSql(options);
    }

    return null;
  }
}

extension DeclarationUtils on HasDeclaration {
  bool get isDeclaredInDart => declaration is DartDeclaration;

  bool get isDeclaredInDriftFile => declaration is MoorDeclaration;
}
