import 'element.dart';

/// A named SQL query defined in a `.drift` file. A later compile step will
/// further analyze this query and run analysis on it.
///
/// We deliberately only store very basic information here: The actual query
/// model is very complex and hard to serialize. Further, lots of generation
/// logic requires actual references to the AST which will be difficult to
/// translate across serialization run.
/// Since SQL queries only need to be fully analyzed before generation, and
/// since they are local elements which can't be referenced by others, there's
/// no clear advantage wrt. incremental compilation if queries are fully
/// analyzed and serialized. So, we just do this in the generator.
class DefinedSqlQuery extends DriftElement {
  /// The unmodified source of the declared SQL statement forming this query.
  final String sql;

  /// The offset of [sql] in the source file, used to properly report errors
  /// later.
  final int sqlOffset;

  @override
  final List<DriftElement> references;

  DefinedSqlQuery(
    super.id,
    super.declaration, {
    required this.references,
    required this.sql,
    required this.sqlOffset,
  });
}
