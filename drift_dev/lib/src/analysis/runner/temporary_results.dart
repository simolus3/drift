import 'package:sqlparser/sqlparser.dart';

abstract class TemporaryResult {}

class TemporaryDriftTable extends TemporaryResult {
  final TableInducingStatement statement;

  TemporaryDriftTable(this.statement);
}

class TemporaryDriftView extends TemporaryResult {
  final CreateViewStatement statement;

  TemporaryDriftView(this.statement);
}
