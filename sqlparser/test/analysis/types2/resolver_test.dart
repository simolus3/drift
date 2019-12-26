import 'package:sqlparser/sqlparser.dart' hide TypeResolver;
import 'package:sqlparser/src/analysis/types2/types.dart';
import 'package:test/test.dart';

import '../data.dart';

void main() {
  final engine = SqlEngine()
    ..registerTable(demoTable)
    ..registerTable(anotherTable);

  TypeResolver _obtainResolver(String sql) {
    final context = engine.analyze(sql);
    return TypeResolver(TypeInferenceSession(context))..start(context.root);
  }

  ResolvedType _resolveFirstVariable(String sql) {
    final resolver = _obtainResolver(sql);
    final session = resolver.session;
    final variable =
        session.context.root.allDescendants.whereType<Variable>().first;
    return session.typeOf(variable);
  }

  ResolvedType _resolveResultColumn(String sql) {
    final resolver = _obtainResolver(sql);
    final session = resolver.session;
    final stmt = session.context.root as SelectStatement;
    return session
        .typeOf((stmt.columns.single as ExpressionResultColumn).expression);
  }

  test('resolves literals', () {
    expect(_resolveResultColumn('SELECT NULL'),
        const ResolvedType(type: BasicType.nullType, nullable: true));

    expect(_resolveResultColumn('SELECT TRUE'), const ResolvedType.bool());
    expect(_resolveResultColumn("SELECT x''"),
        const ResolvedType(type: BasicType.blob));
    expect(_resolveResultColumn("SELECT ''"),
        const ResolvedType(type: BasicType.text));
    expect(_resolveResultColumn('SELECT 3'),
        const ResolvedType(type: BasicType.int));
    expect(_resolveResultColumn('SELECT 3.5'),
        const ResolvedType(type: BasicType.real));
  });

  test('infers boolean type in where conditions', () {
    expect(_resolveFirstVariable('SELECT * FROM demo WHERE :foo'),
        const ResolvedType.bool());
  });

  test('infers boolean type in a join ON clause', () {
    expect(
      _resolveFirstVariable('SELECT * FROM demo JOIN tbl ON :foo'),
      const ResolvedType.bool(),
    );
  });
}
