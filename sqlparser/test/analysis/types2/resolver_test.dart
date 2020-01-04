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
    return TypeResolver(TypeInferenceSession(context))..run(context.root);
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

  test('infers type in a string concatenation', () {
    expect(_resolveFirstVariable("SELECT '' || :foo"),
        const ResolvedType(type: BasicType.text));
  });

  group('cast expressions', () {
    test('resolve to type argument', () {
      expect(_resolveResultColumn('SELECT CAST(3+4 AS TEXT)'),
          const ResolvedType(type: BasicType.text));
    });

    test('allow anything as their operand', () {
      expect(_resolveFirstVariable('SELECT CAST(? AS TEXT)'), null);
    });
  });

  group('types in insert statements', () {
    test('for VALUES', () {
      final resolver =
          _obtainResolver('INSERT INTO demo VALUES (:id, :content);');
      final root = resolver.session.context.root;
      final variables = root.allDescendants.whereType<Variable>();

      final idVar = variables.singleWhere((v) => v.resolvedIndex == 1);
      final contentVar = variables.singleWhere((v) => v.resolvedIndex == 2);

      expect(resolver.session.typeOf(idVar), id.type);
      expect(resolver.session.typeOf(contentVar), content.type);
    });

    test('for SELECT', () {
      final resolver = _obtainResolver('INSERT INTO demo SELECT :id, :content');
      final root = resolver.session.context.root;
      final variables = root.allDescendants.whereType<Variable>();

      final idVar = variables.singleWhere((v) => v.resolvedIndex == 1);
      final contentVar = variables.singleWhere((v) => v.resolvedIndex == 2);

      expect(resolver.session.typeOf(idVar), id.type);
      expect(resolver.session.typeOf(contentVar), content.type);
    });
  });
}
