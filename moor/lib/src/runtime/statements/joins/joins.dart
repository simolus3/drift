import 'package:moor/moor.dart';

/// A [SelectStatement] that operates on more than one table.
class JoinedSelectStatement extends SelectStatement {
  JoinedSelectStatement(QueryEngine database, TableInfo table)
      : super(database, table);
}

abstract class JoinCreator {}
