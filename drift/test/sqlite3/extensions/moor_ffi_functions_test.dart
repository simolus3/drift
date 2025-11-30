import 'package:drift/drift.dart';
import 'package:drift/sqlite3/dialect.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  final a = Expression<double>.custom('a');
  final b = Expression<double>.custom('b');

  test('pow', () {
    expect(sqlPow(a, b), generates('pow(a,b)'));
  });

  test('sqrt', () => expect(sqlSqrt(a), generates('sqrt(a)')));
  test('sin', () => expect(sqlSin(a), generates('sin(a)')));
  test('cos', () => expect(sqlCos(a), generates('cos(a)')));
  test('tan', () => expect(sqlTan(a), generates('tan(a)')));
  test('asin', () => expect(sqlAsin(a), generates('asin(a)')));
  test('acos', () => expect(sqlAcos(a), generates('acos(a)')));
  test('atan', () => expect(sqlAtan(a), generates('atan(a)')));

  test('containsCase', () {
    final c = Expression<String>.custom('a');

    expect(c.containsCase('foo'), generates('drift_contains(a,?1,0)', ['foo']));
    expect(
      c.containsCase('foo', caseSensitive: true),
      generates('drift_contains(a,?1,1)', ['foo']),
    );
  });

  test('containsCase integration test', () async {
    final db = TodoDb(testInMemoryDatabase());
    // insert exactly one row so that we can evaluate expressions from Dart
    await db.into(db.pureDefaults).insert(PureDefaultsCompanion.insert());

    Future<bool?> evaluate(Expression<bool> expr) async {
      final row = await db.selectExpressions([expr]).getSingle();
      return row.read<bool>(expr);
    }

    expect(
      evaluate(const Variable('Häuser').containsCase('Ä')),
      completion(isTrue),
    );

    expect(
      evaluate(const Variable('Dart is cool')
          .containsCase('dart', caseSensitive: false)),
      completion(isTrue),
    );

    expect(
      evaluate(const Variable<String>(null)
          .containsCase('dart', caseSensitive: false)),
      completion(isNull),
    );
  });

  group('regexp flags', () {
    late TodoDb db;

    setUp(() async {
      db = TodoDb(testInMemoryDatabase());
      // insert exactly one row so that we can evaluate expressions from Dart
      await db.into(db.pureDefaults).insert(PureDefaultsCompanion.insert());
    });

    tearDown(() => db.close());

    Future<bool?> evaluate(Expression<bool> expr) async {
      final result = await (db.selectOnly(db.pureDefaults)..addColumns([expr]))
          .getSingle();

      return result.read<bool>(expr)!;
    }

    test('multiLine', () {
      expect(
        evaluate(
          Variable.withString('foo\nbar').regexp(
            '^bar',
            multiLine: true,
          ),
        ),
        completion(isTrue),
      );

      expect(
        evaluate(
          Variable.withString('foo\nbar').regexp(
            '^bar',
            // multiLine is disabled by default
          ),
        ),
        completion(isFalse),
      );
    });

    test('caseSensitive', () {
      expect(
        evaluate(
          Variable.withString('FOO').regexp(
            'foo',
            caseSensitive: false,
          ),
        ),
        completion(isTrue),
      );

      expect(
        evaluate(
          Variable.withString('FOO').regexp(
            'foo',
            // caseSensitive should be true by default
          ),
        ),
        completion(isFalse),
      );
    });

    test('unicode', () {
      // Note: `𝌆` is U+1D306 TETRAGRAM FOR CENTRE, an astral symbol.
      // https://mathiasbynens.be/notes/es6-unicode-regex
      const input = 'a𝌆b';

      expect(
        evaluate(
          Variable.withString(input).regexp(
            'a.b',
            unicode: true,
          ),
        ),
        completion(isTrue),
      );

      expect(
        evaluate(
          Variable.withString(input).regexp(
            'a.b',
            // Unicode is off by default
          ),
        ),
        completion(isFalse),
      );
    });

    test('dotAll', () {
      expect(
        evaluate(
          Variable.withString('fo\n').regexp(
            'fo.',
            dotAll: true,
          ),
        ),
        completion(isTrue),
      );

      expect(
        evaluate(
          Variable.withString('fo\n').regexp(
            'fo.',
            dotAll: false,
          ),
        ),
        completion(isFalse),
      );
    });
  });
}
