import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:sqlparser/sqlparser.dart';

class BaseDeclaration {
  final FoundFile declarationFile;

  /// If the column was declared in Dart, contains an enclosing getter element
  /// that declared the column
  final Element dartDeclaration;

  /// If the column was declared in a moor file, contains the ast node that
  /// contains the column definition
  final AstNode moorDeclaration;

  BaseDeclaration(
      this.declarationFile, this.dartDeclaration, this.moorDeclaration);
}

/// Column declaration that is used as a metadata on a [Column] so that the
/// analysis plugin can know where a referenced column was declared and provide
/// navigation hints.
class ColumnDeclaration extends BaseDeclaration {
  /// The moor version of the declared column.
  final SpecifiedColumn column;

  /// Whether this declaration is from a moor file (e.g. inside a `CREATE TABLE`
  /// statement).
  bool get isDefinedInMoorFile => moorDeclaration != null;

  ColumnDeclaration(this.column, FoundFile declarationFile,
      Element dartDeclaration, AstNode moorDeclaration)
      : super(declarationFile, dartDeclaration, moorDeclaration);
}

/// Meta information set on a [Table] so that the analysis plugin can know where
/// a referenced table was declared and provide navigation hints.
class TableDeclaration extends BaseDeclaration {
  final SpecifiedTable table;

  TableDeclaration(this.table, FoundFile declarationFile,
      Element dartDeclaration, AstNode moorDeclaration)
      : super(declarationFile, dartDeclaration, moorDeclaration);
}
