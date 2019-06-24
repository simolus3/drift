import 'dart:html';

import 'package:moor/moor_web.dart';

import 'database.dart';

void main() async {
  final db = Database(AlaSqlDatabase('database'));
  db.watchEntries().listen(print);

  final content = querySelector('#description');

  (querySelector('#add_todo_form') as FormElement).onSubmit.listen((e) {
    e.preventDefault();

    db.insert(content.text);
    content.text = '';
  });
}
