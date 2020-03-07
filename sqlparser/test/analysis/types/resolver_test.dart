import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';

Map<String, ResolveResult> _types = {
  'SELECT * FROM demo WHERE id = ?':
      const ResolveResult(ResolvedType(type: BasicType.int)),
  'SELECT * FROM demo WHERE content = ?':
      const ResolveResult(ResolvedType(type: BasicType.text)),
  'SELECT * FROM demo LIMIT ?':
      const ResolveResult(ResolvedType(type: BasicType.int)),
  'SELECT 1 FROM demo GROUP BY id HAVING COUNT(*) = ?':
      const ResolveResult(ResolvedType(type: BasicType.int)),
  'SELECT 1 FROM demo WHERE id BETWEEN 3 AND ?':
      const ResolveResult(ResolvedType(type: BasicType.int)),
  'UPDATE demo SET content = ? WHERE id = 3':
      const ResolveResult(ResolvedType(type: BasicType.text)),
  'SELECT * FROM demo WHERE content LIKE ?':
      const ResolveResult(ResolvedType(type: BasicType.text)),
  "SELECT * FROM demo WHERE content LIKE '%e' ESCAPE ?":
      const ResolveResult(ResolvedType(type: BasicType.text)),
  'SELECT * FROM demo WHERE content IN ?':
      const ResolveResult(ResolvedType(type: BasicType.text, isArray: true)),
  'SELECT * FROM demo WHERE content IN (?)':
      const ResolveResult(ResolvedType(type: BasicType.text, isArray: false)),
  'SELECT * FROM demo JOIN tbl ON demo.id = tbl.id WHERE date = ?':
      const ResolveResult(
          ResolvedType(type: BasicType.int, hint: IsDateTime())),
  'SELECT row_number() OVER (RANGE ? PRECEDING)':
      const ResolveResult(ResolvedType(type: BasicType.int)),
  'SELECT ?;': const ResolveResult.unknown(),
  'SELECT CAST(3 AS TEXT) = ?':
      const ResolveResult(ResolvedType(type: BasicType.text)),
  'SELECT (3 * 4) = ?': const ResolveResult(ResolvedType(type: BasicType.int)),
  'SELECT (3 / 4) = ?': const ResolveResult(ResolvedType(type: BasicType.int)),
  'SELECT CURRENT_TIME  = ?':
      const ResolveResult(ResolvedType(type: BasicType.text)),
  "SELECT ? || 'foo'": const ResolveResult(ResolvedType(type: BasicType.text)),
};

void main() {
  _types.forEach((sql, resolvedType) {
    test('types: resolves in $sql', () {
      final engine = SqlEngine()
        ..registerTable(demoTable)
        ..registerTable(anotherTable);
      final content = engine.analyze(sql);

      final variable = content.root.allDescendants
          .firstWhere((node) => node is Variable) as Typeable;

      expect(content.typeOf(variable), equals(resolvedType));
    });
  });

  test('handles VALUES clause in insert statements', () {
    final engine = SqlEngine()..registerTable(demoTable);
    final context = engine.analyze('INSERT INTO demo VALUES (?, ?), (?, ?)');

    final variables =
        context.root.allDescendants.whereType<Variable>().toList();

    expect(context.typeOf(variables[0]), ResolveResult(id.type));
    expect(context.typeOf(variables[1]), ResolveResult(content.type));
    expect(context.typeOf(variables[2]), ResolveResult(id.type));
    expect(context.typeOf(variables[3]), ResolveResult(content.type));
  });

  test('handles nth_value', () {
    final ctx = SqlEngine().analyze("SELECT nth_value('string', ?1) = ?2");
    final variables = ctx.root.allDescendants.whereType<Variable>().iterator;
    variables.moveNext();
    final firstVar = variables.current;
    variables.moveNext();
    final secondVar = variables.current;

    expect(ctx.typeOf(firstVar),
        equals(const ResolveResult(ResolvedType(type: BasicType.int))));

    expect(ctx.typeOf(secondVar),
        equals(const ResolveResult(ResolvedType(type: BasicType.text))));
  });

  test('can infer types for dart placeholder', () {
    final ctx = (SqlEngine(EngineOptions(useMoorExtensions: true))
          ..registerTable(demoTable))
        .analyze(r'SELECT * FROM demo WHERE $expr');

    final dartExpr =
        ctx.root.allDescendants.whereType<DartPlaceholder>().single;

    expect(ctx.typeOf(dartExpr as Expression),
        const ResolveResult(ResolvedType.bool()));
  });

  test('respects explicit types for variables', () {
    final ctx = SqlEngine(EngineOptions(useMoorExtensions: true)).analyze(
      'SELECT ?',
      stmtOptions: const AnalyzeStatementOptions(indexedVariableTypes: {
        1: ResolvedType.bool(),
      }),
    );

    final variable = ctx.root.allDescendants.whereType<Variable>().single;
    expect(ctx.typeOf(variable), const ResolveResult(ResolvedType.bool()));
  });
}
