import 'dart:html';

import 'package:moor/moor_web.dart';

import 'database.dart';

void main() async {
  final db = Database(WebDatabase('database', logStatements: true));
  db.watchEntries().listen(print);

  (querySelector('#add_todo_form') as FormElement).onSubmit.listen((e) {
    final content = querySelector('#description') as InputElement;
    e.preventDefault();

    db.insert(content.value).then((insertId) => print('inserted #$insertId'));
    content.value = '';
  });
}
