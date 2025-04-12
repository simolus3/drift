import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'dialect.dart';

@internal
final class PostgresCompiler extends StatementCompiler {
  @override
  final PostgresDialect dialect;

  PostgresCompiler(this.dialect);

  @override
  void addDateExtractionOperator(DateExtractionOperator<Object> e) {
    throw UnimplementedError();
  }

  @override
  void addPositionalVariable(int index) {
    statement.buffer
      ..write(r'$')
      ..write(index);
  }

  @override
  void addUnixTimestampToDateTime(UnixTimestampToDateTime e) {
    throw UnimplementedError();
  }
}
