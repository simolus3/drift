import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/services/ide/moor_ide.dart';
import 'package:test/test.dart';

import 'utils.dart';

final _asset = AssetId('foo', 'lib/bar.moor');

void main() {
  MoorIde moorIde;
  Map<AssetId, String> data;
  List<HighlightRegion> results;

  setUp(() {
    data = {};
    moorIde = spawnIde(data);
  });

  Future<void> highlight(String source) async {
    data[_asset] = source;
    results = await moorIde.highlight('/foo/lib/bar.moor');
  }

  void expectRegion(String content, HighlightRegionType type) {
    final failureBuffer = StringBuffer();

    for (final region in results) {
      final regionType = region.type;
      final lexeme =
          data[_asset].substring(region.offset, region.offset + region.length);

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
