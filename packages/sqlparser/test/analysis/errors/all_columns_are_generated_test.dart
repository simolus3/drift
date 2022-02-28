import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('reports error if all columns are generated', () {
    final result = SqlEngine().analyze('''
      CREATE TABLE a (
        a TEXT GENERATED ALWAYS AS ('a'),
        b TEXT GENERATED ALWAYS AS ('b')
      );
    ''');

    expect(result.errors, hasLength(1));
    final error = result.errors.single;

    expect(error.type, AnalysisErrorType.allColumnsAreGenerated);
  });

  test('does not report an error if a non-generated column exists', () {
    final result = SqlEngine().analyze('''
      CREATE TABLE a (
        a TEXT GENERATED ALWAYS AS ('a'),
        b TEXT GENERATED ALWAYS AS ('b'),
        c TEXT
      );
    ''');

    expect(result.errors, isEmpty);
  });
}
