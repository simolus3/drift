import 'package:moor/moor.dart';
import 'package:test/test.dart';

extension ComponentExpectations on Component {
  void expectGenerates(String sql, [List<dynamic> variables]) {
    final ctx = GenerationContext(SqlTypeSystem.defaultInstance, null);
    writeInto(ctx);

    expect(ctx.sql, sql);

    if (variables != null) {
      expect(ctx.boundVariables, variables);
    }
  }
}
