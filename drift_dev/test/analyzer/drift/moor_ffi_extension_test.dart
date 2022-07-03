import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/drift/moor_ffi_extension.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late SqlEngine engine;

  setUp(() {
    engine = SqlEngine(
      EngineOptions(enabledExtensions: const [MoorFfiExtension()]),
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

  test('integration tests with moor files and experimental inference',
      () async {
    final state = TestState.withContent(
      const {
        'foo|lib/a.moor': '''
CREATE TABLE numbers (foo REAL NOT NULL);

query: SELECT pow(oid, foo) FROM numbers;
        ''',
        'foo|lib/b.moor': '''
import 'a.moor';

wrongArgs: SELECT sin(oid, foo) FROM numbers;
        '''
      },
      options: const DriftOptions.defaults(modules: [SqlModule.moor_ffi]),
    );
    addTearDown(state.close);

    final fileA = await state.analyze('package:foo/a.moor');

    expect(fileA.errors.errors, isEmpty);
    final resultA = fileA.currentResult as ParsedDriftFile;

    final queryInA = resultA.resolvedQueries!.single as SqlSelectQuery;
    expect(
      queryInA.resultSet.columns.single,
      const TypeMatcher<ResultColumn>()
          .having((e) => e.type, 'type', ColumnType.real),
    );

    final fileB = await state.analyze('package:foo/b.moor');
    expect(fileB.errors.errors, [
      const TypeMatcher<ErrorInDriftFile>()
          .having((e) => e.span.text, 'span.text', 'sin(oid, foo)')
    ]);
  });
}
