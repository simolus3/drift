import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';
import 'package:build_test/src/in_memory_reader_writer.dart';
import 'package:drift_dev/integrations/build.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

final _resolvers =
    withEnabledExperiments(() => AnalyzerResolvers.sharedInstance, ['records']);

BuilderOptions builderOptionsFromYaml(String yaml) {
  final map = loadYaml(yaml);
  return BuilderOptions((map as YamlMap).cast());
}

Logger loggerThat(dynamic expectedLogs) {
  final logger = Logger.detached('drift_dev_test');

  expect(logger.onRecord, expectedLogs);
  return logger;
}

TypeMatcher<LogRecord> record(dynamic message) {
  return isA<LogRecord>().having((e) => e.message, 'message', message);
}

Future<TestReaderWriter> driftTestEnvironment(
    {String rootPackage = 'a'}) async {
  final rw = TestReaderWriter(rootPackage: rootPackage);
  final reader = await PackageAssetReader.currentIsolate();
  for (final package in [
    'async',
    'convert',
    'collection',
    'drift',
    'meta',
    'stream_channel',
    'sqlite3',
    'path',
    'stack_trace',
    'typed_data',
  ]) {
    await for (final asset
        in reader.findAssets(Glob('lib/**'), package: package)) {
      rw.testing.writeBytes(asset, await reader.readAsBytes(asset));
    }
  }

  return rw;
}

Future<DriftBuildResult> emulateDriftBuild({
  required Map<String, String> inputs,
  BuilderOptions options = const BuilderOptions({}),
  Logger? logger,
  bool modularBuild = false,
}) async {
  _resolvers.reset();
  logger ??= Logger.detached('emulateDriftBuild');
  final logLines = <LogRecord>[];

  final env = await driftTestEnvironment();
  final result = await testBuilders(
    [
      preparingBuilder(options),
      discover(options),
      analyzer(options),
      modularBuild ? modular(options) : driftBuilderNotShared(options),
      // TODO: Investigate testing post-process builder too. Once that's
      // possible, also patch DriftBuildResult.dartOutputs to use information
      // about deleted assets again.
      // driftCleanup(options),
    ],
    inputs,
    rootPackage: 'a',
    onLog: (record) {
      logLines.add(record);
      if (record.level >= Level.WARNING) {
        // We sometimes want to assert that no warnings are printed, but
        // everything below that is noise.
        logger?.log(
            record.level, record.message, record.error, record.stackTrace);
      }
    },
    readerWriter: env,
    // Assets from other packages are visible, but we're not running
    // builders on them.
    generateFor:
        inputs.keys.where((e) => makeAssetId(e).package == 'a').toSet(),
  );
  if (result.buildResult.failureType != null) {
    throw Exception('testBuilders failed');
  }

  final deletedAssets = <AssetId>[];

  logger.clearListeners();
  return DriftBuildResult(env, deletedAssets);
}

class DriftBuildResult {
  final TestReaderWriter writer;
  final List<AssetId> deleted;

  DriftBuildResult(this.writer, this.deleted);

  Iterable<AssetId> get dartOutputs {
    return writer.testing.assetsWritten.where((e) {
      return e.extension == '.dart' &&
          !deleted.contains(e) &&
          // TODO: Remove once we can test the post-process builder again.
          !e.path.endsWith('.temp.dart');
    });
  }

  void checkDartOutputs(Map<String, Object> outputs) {
    checkOutputs(outputs, dartOutputs, writer);
  }
}

extension ReaderWriterUtils on TestReaderWriter {
  String readGenerated(String assetId) {
    var id = AssetId.parse(assetId);
    if (!testing.exists(id)) {
      id = AssetId(
        (this as InMemoryAssetReaderWriter).rootPackage,
        '.dart_tool/build/generated/${id.package}/${id.path}',
      );

      // If neither succeeded then the asset was output but written somewhere
      // unexpected.
      if (!testing.exists(id)) {
        throw StateError(
          'Internal error: "$assetId" was recorded as output, but the file '
          'could not be found. All assets: ${testing.assets}',
        );
      }
    }

    return testing.readString(id);
  }
}

class IsValidDartFile extends CustomMatcher {
  IsValidDartFile(dynamic valueOrMatcher)
      : super(
          'A syntactically-valid Dart source file',
          'parsed unit',
          valueOrMatcher,
        );

  @override
  Object? featureValueOf(actual) {
    final resourceProvider = MemoryResourceProvider();
    if (actual is List<int>) {
      resourceProvider.newFileWithBytes('/foo.dart', actual);
    } else if (actual is String) {
      resourceProvider.newFile('/foo.dart', actual);
    } else {
      throw 'Not a String or a List<int>';
    }

    return parseFile(
      path: '/foo.dart',
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: Version(3, 0, 0),
        flags: const [],
      ),
      resourceProvider: resourceProvider,
      throwIfDiagnostics: true,
    ).unit;
  }
}
