import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';

/// A [MultiPackageAssetReader] able to read assets from a
/// [RecordingAssetWriter].
class WrittenAssetsReader extends MultiPackageAssetReader {
  final RecordingAssetWriter source;

  WrittenAssetsReader(this.source);

  @override
  Future<bool> canRead(AssetId id) {
    return Future.value(source.assets.containsKey(id));
  }

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) {
    return Stream.fromIterable(source.assets.keys).where((id) {
      final matchesPath = glob.matches(id.path);
      if (package != null) {
        return id.package == package && matchesPath;
      }
      return matchesPath;
    });
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    return Future.value(source.assets[id]);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding}) {
    final actualEncoding = encoding ?? utf8;
    return Future.value(actualEncoding.decode(source.assets[id]));
  }
}
