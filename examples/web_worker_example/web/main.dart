import 'dart:html';

import 'package:drift/remote.dart';
import 'package:drift/web.dart';
import 'package:web_worker_example/database.dart';

void main() async {
  final worker = SharedWorker('worker.dart.js');
  final connection = await connectToRemoteAndInitialize(worker.port!.channel());
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
