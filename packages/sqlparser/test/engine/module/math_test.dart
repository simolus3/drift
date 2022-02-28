import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  final engine = SqlEngine(EngineOptions(
    version: SqliteVersion.current,
    enabledExtensions: const [BuiltInMathExtension()],
  ));

  ResolveResult resolveExpr(String expr) {
    final result = engine.analyze('SELECT $expr;');
    final column = ((result.root as SelectStatement).columns.single
            as ExpressionResultColumn)
        .expression;
    return result.typeOf(column);
  }

  test('refuses to work with old sqlite versions', () {
    expect(
      () => SqlEngine(EngineOptions(
        enabledExtensions: const [BuiltInMathExtension()],
      )),
      throwsStateError,
    );
  });

  test('reports pi as double', () {
    expect(resolveExpr('pi()').type?.type, BasicType.real);
  });

  test('reports sin as double', () {
    expect(resolveExpr('sin(3)').type?.type, BasicType.real);
  });

  test('reports ceil as int', () {
    expect(resolveExpr('ceil(3.5)').type?.type, BasicType.int);
  });

  test('infers arguments as numeric', () {
    final result = engine.analyze('SELECT sin(?);');
    final variable = result.root.allDescendants.whereType<Variable>().first;
    expect(result.typeOf(variable).type?.type, BasicType.real);
  });

  group('checks amount of arguments', () {
    test('for log', () {
      expect(engine.analyze('SELECT log(2)').errors, isEmpty);
      expect(engine.analyze('SELECT log(2, 4)').errors, isEmpty);
      expect(engine.analyze('SELECT log(2, 4, 8)').errors, isNotEmpty);
    });

    test('for pi', () {
      expect(engine.analyze('SELECT pi()').errors, isEmpty);
      expect(engine.analyze('SELECT pi(3)').errors, isNotEmpty);
    });

    test('for radians', () {
      expect(engine.analyze('SELECT radians(3)').errors, isEmpty);
      expect(engine.analyze('SELECT radians(3, 4)').errors, isNotEmpty);
    });

    test('for power', () {
      expect(engine.analyze('SELECT power(3, 4)').errors, isEmpty);
      expect(engine.analyze('SELECT power(3)').errors, isNotEmpty);
    });
  });
}
