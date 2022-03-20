import 'package:collection/collection.dart';

import '../builder/context.dart';
import '../expressions/expression.dart';
import '../schema.dart';
import 'clauses.dart';
import 'scope.dart';

class SelectStatement with WhereClause, GeneralFrom implements SqlComponent {
  final List<Expression> _columns;

  SelectStatement(this._columns);

  @override
  void writeInto(GenerationContext context) {
    context.pushScope(_SelectGenerationScope(this));
    context.buffer.write('SELECT ');

    _columns.forEachIndexed((index, column) {
      if (index != 0) context.buffer.write(',');

      column.writeInto(context);
    });

    context.writeWhitespace();
    writeFrom(context);

    context.popScope();
  }
}

class _SelectGenerationScope extends StatementScope {
  final SelectStatement statement;

  _SelectGenerationScope(this.statement) : super(statement.tables.length > 1);

  @override
  AddedTable? findTable(EntityWithResult entity, String? name) {
    bool hasMatch(AddedTable table) {
      return table.table == entity && table.as == name;
    }

    for (final joined in statement.tables) {
      if (joined is AddedTable && hasMatch(joined)) {
        return joined;
      } else if (joined is Join && hasMatch(joined.table)) {
        return joined.table;
      }
    }

    return null;
  }
}
