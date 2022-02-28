import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';

void main() {
  test('correctly reports results for aliases', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final stmt = engine.analyze('''
    SELECT
      a1.*,
      a2.*
    FROM demo AS a1
      LEFT JOIN demo AS a2 ON FALSE
      INNER JOIN demo AS a3 ON TRUE;
    ''').root;

    final model = JoinModel.of(stmt)!;
    expect(
      model.isNullableTable(stmt.scope
          .resolve<ResultSetAvailableInStatement>('a1')!
          .resultSet
          .resultSet!),
      isFalse,
    );
    expect(
      model.isNullableTable(stmt.scope
          .resolve<ResultSetAvailableInStatement>('a2')!
          .resultSet
          .resultSet!),
      isTrue,
    );
    expect(
      model.isNullableTable(stmt.scope
          .resolve<ResultSetAvailableInStatement>('a3')!
          .resultSet
          .resultSet!),
      isFalse,
    );
  });
}
