@TestOn('vm')
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';

void main() {
  test('drift does not import legacy JS interop files', () {
    // The old web APIs can't be used in dart2wasm, so we shouldn't use them in
    // web-specific drift code.
    const allowedLegacyCode = [
      'lib/src/web/channel_legacy.dart',
    ];

    final failures = <(String, String)>[];

    void check(FileSystemEntity e) {
      switch (e) {
        case File():
          if (allowedLegacyCode.contains(e.path)) return;

          final text = e.readAsStringSync();
          final parsed = parseString(content: text).unit;

          for (final directive in parsed.directives) {
            if (directive is ImportDirective) {
              final uri = directive.uri.stringValue!;
              if (uri.contains('package:js') ||
                  uri == 'dart:js' ||
                  uri == 'dart:js_util' ||
                  uri == 'dart:html' ||
                  uri == 'dart:indexeddb') {
                failures.add((e.path, directive.toString()));
              }
            }
          }

        case Directory():
          for (final entry in e.listSync()) {
            check(entry);
          }
      }
    }

    final root = Directory('lib/');
    check(root);

    expect(failures, isEmpty,
        reason: 'Drift should not import legacy JS code.');
  });
}
