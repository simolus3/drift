import 'package:drift_dev/src/analysis/options.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('can define triggers referencing powersync vtab', () async {
    final state = await TestBackend.inTest({
      'a|lib/main.drift': '''
CREATE TABLE todo_lists (
   id TEXT NOT NULL PRIMARY KEY,
   created_by TEXT NOT NULL,
   title TEXT NOT NULL,
   content TEXT
) STRICT;

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

CREATE TRIGGER todo_lists_delete
   AFTER DELETE ON todo_lists
   FOR EACH ROW
   BEGIN
      INSERT INTO powersync_crud (op, id, type) VALUES ('DELETE', OLD.id, 'todo_lists');
   END;
'''
    }, options: DriftOptions.defaults(modules: [SqlModule.powersync]));

    await state.analyze('package:a/main.drift');
    state.expectNoErrors();
  });
}
