// Stubs for external APIs we want to reference in Snippets without being able
// to depend on them.

import 'dart:typed_data';

abstract class AssetBundle {
  Future<ByteData> load(String key);
}

AssetBundle get rootBundle => throw 'stub';
