import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/sql_query.dart';

class ResultSetWriter {
  final SqlSelectQuery query;

  ResultSetWriter(this.query);

  void write(StringBuffer into) {
    final className = query.resultClassName;

    into.write('class $className {\n');
    // write fields
    for (var column in query.resultSet.columns) {
      final name = query.resultSet.dartNameFor(column);
      final runtimeType = dartTypeNames[column.type];
      into.write('final $runtimeType $name\n;');
    }

    // write the constructor
    into.write('$className({');
    for (var column in query.resultSet.columns) {
      into.write('this.${query.resultSet.dartNameFor(column)},');
    }
    into.write('});\n}\n');
  }
}
