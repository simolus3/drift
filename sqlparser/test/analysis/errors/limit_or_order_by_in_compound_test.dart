import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('reports error if LIMIT is used before last part', () {
    final engine = SqlEngine();
    final analyzed = engine.analyze('SELECT 1 LIMIT 3 UNION SELECT 2');

    expect(analyzed.errors, hasLength(1));
    final error = analyzed.errors.single;

    expect(error.type, AnalysisErrorType.synctactic);
    final problematicSelect = (analyzed.root as CompoundSelectStatement).base;
    final wrongLimit = (problematicSelect as SelectStatement).limit;
    expect(error.source, wrongLimit);
  });

  test('reports error if ORDER BY is used before last part', () {
    final engine = SqlEngine();
    final analyzed = engine.analyze('''
      SELECT 1 UNION
      SELECT 1 ORDER BY 2 INTERSECT
      SELECT 1
    ''');

    expect(analyzed.errors, hasLength(1));
    final error = analyzed.errors.single;

    expect(error.type, AnalysisErrorType.synctactic);
    final problematicSelect =
        (analyzed.root as CompoundSelectStatement).additional[0].select;
    final wrongOrderBy = (problematicSelect as SelectStatement).orderBy;
    expect(error.source, wrongOrderBy);
  });
}
