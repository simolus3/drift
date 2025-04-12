import 'package:drift/drift.dart';

import 'compiler.dart';

/// In sqlite3, a table-valued function is a function that resolves to a result
/// set, meaning that it can be selected from.
///
/// For more information on table-valued functions in general, visit their
/// [documentation](https://sqlite.org/vtab.html#tabfunc2) on the sqlite website.
///
/// This class is meant to be extended for each table-valued function, so that
/// the [Self] type parameter points to the actual implementation class. The
/// class must also implement [withAlias] correctly.
///
/// For an example of a table-valued function in drift, see the
/// `JsonTableFunction` in `package:drift/json1.dart`. It makes the `json_each`
/// and `json_tree` table-valued functions available to drift.
abstract base class TableValuedFunction<Self extends TableValuedFunction<Self>>
    with ResultSet<DriftRow, Self>
    implements SqlComponent {
  /// The name of the table-valued function being called.
  final String functionName;

  /// The arguments passed to the table-valued function.
  final List<Expression> arguments;

  @override
  final List<SchemaColumn<Object>> columns;

  @override
  final String? alias;

  /// Constructor for table-valued functions.
  ///
  /// This takes the [attachedDatabase] (used to interpret results), the name
  /// of the function as well as arguments passed to it and finally the schema
  /// of the table (in the form of [columns]).
  TableValuedFunction({
    required this.functionName,
    required this.arguments,
    required this.columns,
    this.alias,
  }) {
    for (final column in columns) {
      column.owningResultSet = this;
    }
  }

  @override
  Self asSelfType() => this as Self;

  @override
  String get entityName => functionName;

  @override
  DriftRow? Function(DriftRow p1) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (row) => row;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    if (compiler case final SqliteCompiler sqlite) {
      return sqlite.addTableValuedFunction(this);
    } else {
      throw ArgumentError('Table-valued functions only support SQLite');
    }
  }
}
