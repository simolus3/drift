import 'dart:io';

import 'package:drift_website/src/navigation.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  test('all pages are referenced in navigation tree', () async {
    const hidden = [
      'sql_api/sql_ide.md', // Currently defunct.
      '404.html', // Not supposed to be visible.
    ];

    final referenced = <String>{
      ...hidden,
      for (final tab in DriftTab.all)
        for (final group in tab.groups)
          for (final page in group.pages) page.definingFile,
    };
    final missing = <String>[];

    await for (final page in Glob('content/**').list()) {
      if (page is File) {
        final name = normalize(relative(page.path, from: 'content/'));
        if (!referenced.contains(name)) {
          missing.add(name);
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'All pages should be referenced in sidebar tree',
    );
  });
}
