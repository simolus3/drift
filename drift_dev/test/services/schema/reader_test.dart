import 'dart:convert';

import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/services/schema/schema_files.dart';
import 'package:test/test.dart';

import '../../analysis/test_utils.dart';

void main() {
  test('keeps data class name for views', () async {
    final elements = await _analyzeAndSerialize('''
CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE VIEW user_ids AS SELECT id FROM users;
''');

    expect(
      elements[0],
      isA<DriftTable>()
          .having((e) => e.nameOfRowClass, 'nameOfRowClass', 'UsersData'),
    );
    expect(
      elements[1],
      isA<DriftView>()
          .having((e) => e.nameOfRowClass, 'nameOfRowClass', 'UserId'),
    );
  });
}

Future<List<DriftElement>> _analyzeAndSerialize(String source) async {
  final state = TestBackend.inTest({'a|lib/a.drift': source});
  final file = await state.analyze('package:a/a.drift');

  final writer = SchemaWriter(file.analyzedElements.toList());
  final schemaJson = json.decode(json.encode(writer.createSchemaJson()));

  final deserialized =
      SchemaReader.readJson(schemaJson as Map<String, Object?>);
  return deserialized.entities.toList();
}
