import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../analysis/data.dart';
import '../../analysis/errors/utils.dart';

void main() {
  final options = EngineOptions(
      version: SqliteVersion.current,
      enabledExtensions: [const PowerSyncSqliteExtension()]);
  late SqlEngine engine;

  setUp(() {
    engine = SqlEngine(options)..registerTableFromSql('''
CREATE TABLE todo_lists (
   id TEXT NOT NULL PRIMARY KEY,
   created_by TEXT NOT NULL,
   title TEXT NOT NULL,
   content TEXT
) STRICT;
''');
  });

  group('crud vtab via triggers', () {
    // This captures suggestions from https://docs.powersync.com/usage/use-case-examples/raw-tables#capture-local-writes-with-triggers
    test('insert', () {
      final result = engine.analyze('''
CREATE TRIGGER todo_lists_insert
   AFTER INSERT ON todo_lists
   FOR EACH ROW
   BEGIN
      INSERT INTO powersync_crud (op, id, type, data) VALUES ('PUT', NEW.id, 'todo_lists', json_object(
         'created_by', NEW.created_by,
         'title', NEW.title,
         'content', NEW.content
      ));
   END;
''');

      result.expectNoError();
    });

    test('update', () {
      final result = engine.analyze('''
CREATE TRIGGER todo_lists_update
   AFTER UPDATE ON todo_lists
   FOR EACH ROW
   BEGIN
      SELECT CASE
         WHEN (OLD.id != NEW.id)
         THEN RAISE (FAIL, 'Cannot update id')
      END;

      -- TODO: You may want to replace the json_object with a powersync_diff call of the old and new values, or
      -- use your own diff logic to avoid marking unchanged columns as updated.
      INSERT INTO powersync_crud (op, id, type, data) VALUES ('PATCH', NEW.id, 'todo_lists', json_object(
         'created_by', NEW.created_by,
         'title', NEW.title,
         'content', NEW.content
      ));
   END;
''');

      result.expectNoError();
    });

    test('delete', () {
      final result = engine.analyze('''
CREATE TRIGGER todo_lists_delete
   AFTER DELETE ON todo_lists
   FOR EACH ROW
   BEGIN
      INSERT INTO powersync_crud (op, id, type) VALUES ('DELETE', OLD.id, 'todo_lists');
   END;
''');

      result.expectNoError();
    });
  });

  test('infers function return type', () {
    final functions = {
      "powersync_diff('{}', '{}')": BasicType.text,
      'powersync_client_id()': BasicType.text,
      'powersync_in_sync_operation()': BasicType.int,
      'gen_random_uuid()': BasicType.text,
      'uuid()': BasicType.text,
    };

    functions.forEach((call, type) {
      final analyzed = engine.analyze('SELECT $call;');
      analyzed.expectNoError();
      final [column] = (analyzed.root as SelectStatement).resolvedColumns!;

      expect(analyzed.typeOf(column).type?.type, type,
          reason: '$call should resolve to $type');
    });
  });
}
