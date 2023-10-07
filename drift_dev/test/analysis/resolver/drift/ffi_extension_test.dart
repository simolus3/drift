import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/drift_native_functions.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  late SqlEngine engine;

  setUp(() {
    engine = SqlEngine(
      EngineOptions(enabledExtensions: const [DriftNativeExtension()]),
    );
  });

  group('reports errors', () {
    test('when pow is called with 3 arguments', () {
      final result = engine.analyze('SELECT pow(1, 2, 3);');

      expect(result.errors, [
        const TypeMatcher<AnalysisError>()
            .having(
              (source) => source.message,
              'message',
              allOf(contains('2'), contains('3'), contains('pow expects')),
            )
            .having(
              (source) => source.span!.text,
              'span.text',
              'pow(1, 2, 3)',
            ),
      ]);
    });

    test('when an unary function is called with 2 arguments', () {
      final result = engine.analyze('SELECT sin(1, 2);');

      expect(result.errors, [
        const TypeMatcher<AnalysisError>()
            .having(
              (source) => source.message,
              'message',
              allOf(contains('2'), contains('1'), contains('sin expects')),
            )
            .having(
              (source) => source.span!.text,
              'span.text',
              'sin(1, 2)',
            ),
      ]);
    });
  });

  test('infers return type', () {
    final result = engine.analyze('SELECT pow(2.5, 3);');
    final stmt = result.root as SelectStatement;

    expect(stmt.resolvedColumns!.map(result.typeOf), [
      const ResolveResult(ResolvedType(type: BasicType.real, nullable: true))
    ]);
  });

  test('infers return type for current_time_millis', () {
    final result = engine.analyze('SELECT current_time_millis();');
    final stmt = result.root as SelectStatement;

    expect(stmt.resolvedColumns!.map(result.typeOf), [
      const ResolveResult(ResolvedType(type: BasicType.int, nullable: false))
    ]);
  });

  test('infers argument type', () {
    final result = engine.analyze('SELECT pow(2.5, ?);');
    final variable = result.root.allDescendants.whereType<Variable>().first;

    expect(
      result.typeOf(variable),
      const ResolveResult(ResolvedType(type: BasicType.real, nullable: false)),
    );
  });

  test('integration tests with drift files and experimental inference',
      () async {
    final state = TestBackend.inTest(
      const {
        'foo|lib/a.drift': '''
CREATE TABLE numbers (foo REAL NOT NULL);

query: SELECT pow(oid, foo) FROM numbers;
        ''',
        'foo|lib/b.drift': '''
import 'a.drift';

wrongArgs: SELECT sin(oid, foo) FROM numbers;
        '''
      },
      options: const DriftOptions.defaults(modules: [SqlModule.moor_ffi]),
    );

    final fileA = await state.analyze('package:foo/a.drift');
    expect(fileA.allErrors, isEmpty);

    final queryInA =
        fileA.fileAnalysis!.resolvedQueries.values.single as SqlSelectQuery;
    expect(
      queryInA.resultSet.scalarColumns.single,
      const TypeMatcher<ScalarResultColumn>()
          .having((e) => e.sqlType.builtin, 'type', DriftSqlType.double),
    );

    final fileB = await state.analyze('package:foo/b.drift');
    expect(fileB.allErrors, [
      isDriftError('sin expects 1 arguments, got 2.').withSpan('sin(oid, foo)')
    ]);
  });
}
