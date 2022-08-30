import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:drift_dev/src/analysis/backend.dart';
import 'package:drift_dev/src/analysis/driver/driver.dart';
import 'package:drift_dev/src/analysis/driver/error.dart';
import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:logging/logging.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class TestBackend extends DriftBackend {
  final Map<String, String> sourceContents;

  late final DriftAnalysisDriver driver;

  TestBackend(Map<String, String> sourceContents, DriftOptions options)
      : sourceContents = {
          for (final entry in sourceContents.entries)
            AssetId.parse(entry.key).uri.toString(): entry.value,
        } {
    driver = DriftAnalysisDriver(this, options);
  }

  factory TestBackend.inTest(Map<String, String> sourceContents,
      {DriftOptions options = const DriftOptions.defaults()}) {
    final backend = TestBackend(sourceContents, options);
    addTearDown(backend.dispose);

    return backend;
  }

  @override
  Logger get log => Logger.root;

  @override
  Uri resolveUri(Uri base, String uriString) {
    return base.resolve(uriString);
  }

  @override
  Future<String> readAsString(Uri uri) async {
    return sourceContents[uri.toString()] ??
        (throw StateError('No source for $uri'));
  }

  @override
  Future<LibraryElement> readDart(Uri uri) {
    // TODO: implement readDart
    throw UnimplementedError();
  }

  Future<void> dispose() async {}
}

Matcher get hasNoErrors => isA<FileState>()
    .having((e) => e.errorsDuringDiscovery, 'errorsDuringDiscovery', isEmpty)
    .having((e) => e.errorsDuringAnalysis, 'errorsDuringAnalysis', isEmpty);

Matcher isDriftError(dynamic message) {
  return isA<DriftAnalysisError>().having((e) => e.message, 'message', message);
}
