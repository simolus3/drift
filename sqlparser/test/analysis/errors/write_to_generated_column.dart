import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';
import 'utils.dart';

void main() {
  late SqlEngine engine;

  setUp(() {
    engine = SqlEngine();
    engine.registerTableFromSql('''
      CREATE TABLE a (
        ok TEXT NOT NULL,
        g TEXT GENERATED ALWAYS AS (ok) STORED
      );
    ''');
  });

  test('reports error when updating generated column', () {
    engine
        .analyze("UPDATE a SET ok = 'new', g = 'old';")
        .expectError('g', type: AnalysisErrorType.writeToGeneratedColumn);
  });

  test('reports error when updating generated column with column-name-list',
      () {
    engine
        .analyze("UPDATE a SET (ok, g) = ('new', 'old');")
        .expectError('g', type: AnalysisErrorType.writeToGeneratedColumn);
  });

  test('reports error when inserting generated column', () {
    engine
        .analyze('INSERT INTO a (ok, g) VALUES (?, ?)')
        .expectError('g', type: AnalysisErrorType.writeToGeneratedColumn);
  });
}
