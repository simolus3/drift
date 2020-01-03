import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/model/sources.dart';
import 'package:sqlparser/sqlparser.dart';

part 'columns.dart';
part 'database.dart';
part 'index.dart';
part 'tables.dart';
part 'trigger.dart';

/// Interface for model elements that are declared somewhere.
abstract class HasDeclaration {
  /// Gets the declaration of this element, if set.
  Declaration get declaration;
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
