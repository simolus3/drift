@TestOn('vm')
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('drift does not import legacy JS interop files', () {
    final failures = <(String, String)>[];

    void check(FileSystemEntity e) {
      switch (e) {
        case File():
          if (p.extension(e.path) != '.dart') return;

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

    expect(
      failures,
      isEmpty,
      reason: 'Drift should not import legacy JS code.',
    );
  });

  test('does not import drift3_preview', () {
    bool isDrift3Preview(String path, [p.Context? context]) {
      return (context ?? p.context).isWithin('lib/src/drift3_preview/', path);
    }

    void check(FileSystemEntity e) {
      switch (e) {
        case File():
          if (p.extension(e.path) != '.dart') return;

          final sourceFileIsDrift3 = isDrift3Preview(e.path);
          final text = e.readAsStringSync();
          final parsed = parseString(content: text, path: e.path).unit;

          for (final directive in parsed.directives) {
            if (directive is NamespaceDirective) {
              final imported = e.uri.resolve(directive.uri.stringValue!);
              if (!imported.hasScheme) {
                expect(
                  isDrift3Preview(imported.toFilePath()),
                  sourceFileIsDrift3,
                  reason: 'Source file ${e.path}, import $imported',
                );
              } else if (imported.isScheme('package') &&
                  imported.pathSegments[0] == 'drift') {
                final importedPath = p.url.joinAll(
                  imported.pathSegments.skip(1),
                );
                expect(
                  isDrift3Preview('lib/$importedPath', p.url),
                  sourceFileIsDrift3,
                  reason: 'Source file ${e.path}, import $imported',
                );
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
  });
}
