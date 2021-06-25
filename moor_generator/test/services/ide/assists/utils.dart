//@dart=2.9
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../utils.dart';

@isTest
void testSourceEdit(String description, String input, String output,
    bool Function(SourceChange) filter,
    {int length = 1}) {
  test(description, () async {
    final offset = input.indexOf('^');
    input = input.replaceFirst('^', '');

    final ide = spawnIde({AssetId('foo', 'lib/bar.moor'): input});
    final assists = await ide.assists('/foo/lib/bar.moor', offset, length);

    final sourceChange = assists.map((p) => p.change).firstWhere(filter);

    final result = SourceEdit.applySequence(
        input, sourceChange.edits.expand((f) => f.edits));

    expect(result, output);
  });
}
