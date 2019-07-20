import 'dart:io';

import 'package:moor/moor_vm.dart';

void main() async {
  final executor = VMDatabase(File('test.db'), logStatements: true);

  await executor.doWhenOpened((_) async {
    await executor.close();
  });
}
