import 'dart:async';

import 'package:meta/meta.dart';

import '../../../dsl/dsl.dart';
import '../../api/runtime_api.dart';
import '../../utils.dart';
import '../query_builder.dart';

/// In sqlite3, a table-valued function is a function that resolves to a result
/// set, meaning that it can be selected from.
///
/// For more information on table-valued functions in general, visit their
/// [documentation](https://sqlite.org/vtab.html#tabfunc2) on the sqlite website.
///
/// This class is meant to be extended for each table-valued function, so that
/// the [Self] type parameter points to the actual implementation class. The
/// class must also implement [createAlias] correctly (ensuring that every
/// column has its [GeneratedColumn.tableName] set to the [aliasedName]).
///
/// For an example of a table-valued function in drift, see the
/// `JsonTableFunction` in `package:drift/json1.dart`. It makes the `json_each`
/// and `json_tree` table-valued functions available to drift.
@experimental
abstract base class TableValuedFunction<Self extends ResultSetImplementation>
    extends ResultSetImplementation<Self, TypedResult>
    implements HasResultSet, Component {
  final String _functionName;

  /// The arguments passed to the table-valued function.
  final List<Expression> arguments;

  @override
  final DatabaseConnectionUser attachedDatabase;

  @override
  final List<GeneratedColumn<Object>> $columns;

  @override
  final String aliasedName;

  /// Constructor for table-valued functions.
  ///
  /// This takes the [attachedDatabase] (used to interpret results), the name
  /// of the function as well as arguments passed to it and finally the schema
  /// of the table (in the form of [columns]).
  TableValuedFunction(
    this.attachedDatabase, {
    required String functionName,
    required this.arguments,
    required List<GeneratedColumn> columns,
    String? alias,
  })  : _functionName = functionName,
        $columns = columns,
        aliasedName = alias ?? functionName;

  @override
  Self get asDslTable => this as Self;

  @override
  late final Map<String, GeneratedColumn<Object>> columnsByName = {
    for (final column in $columns) column.name: column,
  };

  @override
  String get entityName => _functionName;

  @override
  FutureOr<TypedResult> map(Map<String, dynamic> data, {String? tablePrefix}) {
    final row = QueryRow(data.withoutPrefix(tablePrefix), attachedDatabase);
    return TypedResult(
      const {},
      row,
      {
        for (final column in $columns)
          column: attachedDatabase.typeMapping
              .read(column.type, row.data[column.name]),
      },
    );
  }

  @override
  void writeInto(GenerationContext context) {
    context.buffer
      ..write(_functionName)
      ..write('(');

    var first = true;
    for (final argument in arguments) {
      if (!first) {
        context.buffer.write(', ');
      }

      argument.writeInto(context);
      first = false;
    }

    context.buffer.write(')');
  }
}
