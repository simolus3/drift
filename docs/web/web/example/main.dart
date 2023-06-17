import 'dart:html';

import 'package:drift_docs/sample/app.zap.dart';

void main() {
  final main = document.querySelector('main.container')!;

  App().create(main);
}
