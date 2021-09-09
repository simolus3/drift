import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/engine/autocomplete/engine.dart';
import 'package:test/test.dart';

import '../../analysis/data.dart';
import 'utils.dart';

void main() {
  group('suggests table name', () {
    test('after SELECT FROM', () {
      expect(_compute('a: SELECT * FROM ^'), suggestsTables);
    });

    test('in join', () {
      expect(_compute('a: SELECT * FROM demo INNER JOIN ^;'), suggestsTables);
    });

    test('after update', () {
      expect(_compute('a: UPDATE ^ SET'), suggestsTables);
    });

    test('after insert', () {
      expect(_compute('a: INSERT INTO ^;'), suggestsTables);
    });

    test('in index', () {
      final suggestion = _compute('CREATE INDEX IF NOT EXISTS name ON ^ (id)');
      expect(suggestion, suggestsTables);
    });

    test('in trigger', () {
      final suggestion = _compute('CREATE TRIGGER name BEFORE DELETE ON ^');
      expect(suggestion, suggestsTables);
    });
  });
}

ComputedSuggestions _compute(String moorFile) {
  return completionsFor(moorFile, setup: _setupEngine);
}

void _setupEngine(SqlEngine engine) {
  engine
    ..registerTable(demoTable)
    ..registerTable(anotherTable);
}

Matcher get suggestsTables => suggestsAll(['demo', 'tbl', 'sqlite_master']);
