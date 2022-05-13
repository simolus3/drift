import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:build/build.dart';
import 'package:test/test.dart';

import 'utils.dart';

final _asset = AssetId('foo', 'lib/bar.moor');

void main() {
  late List<HighlightRegion> results;
  late String contents;

  Future<void> highlight(String source) async {
    final ide = spawnIde({_asset: source});
    contents = source;
    results = await ide.highlight('/foo/lib/bar.moor');
  }

  void expectRegion(String content, HighlightRegionType type) {
    final failureBuffer = StringBuffer();

    for (final region in results) {
      final regionType = region.type;
      final lexeme =
          contents.substring(region.offset, region.offset + region.length);

      if (regionType == type && lexeme == content) return;

      failureBuffer.write('$regionType with $lexeme \n');
    }

    fail(
        'Expected region of type $type with text $content. Got $failureBuffer');
  }

  test('import statement', () async {
    await highlight("import 'package:bar/baz.moor'");
    expectRegion('import', HighlightRegionType.BUILT_IN);
    expectRegion("'package:bar/baz.moor'", HighlightRegionType.LITERAL_STRING);
  });

  test('string literals', () async {
    await highlight("query: SELECT 'foo';");
    expectRegion("'foo'", HighlightRegionType.LITERAL_STRING);
  });
}
