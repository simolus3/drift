import 'dart:convert';
import 'dart:isolate';

import 'package:build/build.dart';
import 'package:package_config/package_config.dart';

import '../../analysis/driver/driver.dart';
import '../../analysis/options.dart';
import '../../writer/import_manager.dart';
import '../../writer/writer.dart';
import 'backend.dart';

class DriftAnalyzer extends Builder {
  final DriftOptions options;

  DriftAnalyzer(BuilderOptions options)
      : options = DriftOptions.fromJson(options.config);

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.drift': [
          '.drift.drift_module.json',
          '.drift.types.temp.dart',
        ],
        '.dart': [
          '.dart.drift_module.json',
          '.dart.types.temp.dart',
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final backend = DriftBuildBackend(buildStep);
    final driver = DriftAnalysisDriver(backend, options);

    final results = await driver.resolveElements(buildStep.inputId.uri);

    for (final parseError in results.errorsDuringDiscovery) {
      log.warning(parseError.toString());
    }

    if (results.analysis.isNotEmpty) {
      for (final result in results.analysis.values) {
        for (final error in result.errorsDuringAnalysis) {
          log.warning(error.toString());
        }
      }

      final serialized = driver.serializeState(results);
      final asJson =
          JsonUtf8Encoder(' ' * 2).convert(serialized.serializedData);

      final jsonOutput = buildStep.inputId.addExtension('.drift_module.json');
      final typesOutput = buildStep.inputId.addExtension('.types.temp.dart');

      await buildStep.writeAsBytes(jsonOutput, asJson);

      if (serialized.dartTypes.isNotEmpty) {
        // We're using general typedefs in the generated helper code, which rely
        // on Dart 2.13. We could just add a // @2.13 comment at the top, but
        // we also want to be able to use newer features if the source package
        // opted in to them (e.g. to be able to express records in here).
        // So, we need to know about the package version from the pubspec.
        final version = await buildStep.languageVersionForPackage ??
            _languageVersionForGeneralizedTypedefs;

        final imports = LibraryImportManager();
        final writer = Writer(
          options,
          generationOptions: GenerationOptions(imports: imports),
        );
        imports.linkToWriter(writer);

        // We prefer newer versions, but we really need 2.13
        if (version.compareTo(_languageVersionForGeneralizedTypedefs) < 0) {
          writer.leaf().write('// @dart=2.13');
        }

        for (var i = 0; i < serialized.dartTypes.length; i++) {
          writer.leaf()
            ..write('typedef T$i = ')
            ..writeDart(serialized.dartTypes[i])
            ..writeln(';');
        }

        await buildStep.writeAsString(typesOutput, writer.writeGenerated());
      }
    }
  }

  static final _languageVersionForGeneralizedTypedefs = LanguageVersion(2, 13);
}

extension on BuildStep {
  Future<LanguageVersion?> get languageVersionForPackage async {
    try {
      // This is kind of hacky, hopefully we can get this information out of the
      // build system with https://github.com/dart-lang/build/issues/3492
      final configUri = await Isolate.packageConfig;
      if (configUri == null) return null;

      final packageConfig = await loadPackageConfigUri(configUri);

      for (final package in packageConfig.packages) {
        if (package.name == inputId.package) {
          return package.languageVersion;
        }
      }
    } on Object {
      // Can't read version, so be it
      log.fine('Could not resolve language version of package to determine '
          'whether a //@dart comment is necessary for intermediate sources');
    }

    return null;
  }
}
