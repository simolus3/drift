import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:sqlparser/sqlparser.dart';

/// Column declaration that is used as a metadata on a [Column] so that the
/// analysis plugin can know where a referenced column was declared and provide
/// navigation hints.
class ColumnDeclaration {
  /// The moor version of the declared column.
  final SpecifiedColumn column;
  final FoundFile declarationFile;

  /// If the column was declared in Dart, contains an enclosing getter element
  /// that declared the column
  final Element dartDeclaration;

  /// If the column was declared in a moor file, contains the ast node that
  /// contains the column definition
  final AstNode moorDeclaration;

  ColumnDeclaration(this.column, this.declarationFile, this.dartDeclaration,
      this.moorDeclaration);
}
