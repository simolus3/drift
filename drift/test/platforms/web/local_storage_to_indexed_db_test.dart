@TestOn('browser && !dart2wasm')
@Skip('sql.js not set up for testing')
library;

import 'dart:convert';

import 'package:drift/drift.dart';
// ignore: deprecated_member_use_from_same_package
import 'package:drift/web.dart';
import 'package:test/test.dart';

final _allBytes = Uint8List.fromList(List.generate(256, (index) => index));

void main() {
  test('can migrate from local storage to IndexedDb', () async {
    const local = DriftWebStorage('name');
    final idb = DriftWebStorage.indexedDb('name');

    await local.open();
    await local.store(_allBytes);
    await local.close();

    await idb.open();
    final restored = await idb.restore();
    await idb.close();

    expect(restored, _allBytes);
  });

  test('does not migrate when idb database already exists', () async {
    final otherPayload = Uint8List.fromList(utf8.encode('hello world'));

    const local = DriftWebStorage('name');
    final idb = DriftWebStorage.indexedDb('name');

    await idb.open();
    await idb.store(otherPayload);
    await idb.close();

    await local.open();
    await local.store(_allBytes);
    await local.close();

    await idb.open();
    final restored = await idb.restore();
    await idb.close();

    expect(restored, otherPayload);
  });
}
