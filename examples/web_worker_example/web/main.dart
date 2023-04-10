import 'dart:html';

import 'package:drift/web/worker.dart';
import 'package:web_worker_example/database.dart';

void main() async {
  final connection = await connectToDriftWorker('worker.dart.js');
  final db = MyDatabase(connection);

  final output = document.getElementById('output')!;
  final input = document.getElementById('field')! as InputElement;
  final submit = document.getElementById('submit')! as ButtonElement;

  db.allEntries().watch().listen((rows) {
    output.innerHtml = '';

    for (final row in rows) {
      output.children.add(Element.li()..text = row.value);
    }
  });

  submit.onClick.listen((event) {
    db.addEntry(input.value ?? '');
    input.value = null;
  });
}
