import 'dart:convert';

import 'package:build/build.dart';

import '../../analysis/preprocess_drift.dart';
import 'new_backend.dart';

/// A support builder that runs before the main generator to parse and resolve
/// inline Dart resources in a `.drift` file.
///
/// We use this builder to extract and analyze inline Dart expressions from
/// drift files, which are mainly used for type converters. For instance, let's
/// say we had a drift file like this:
///
/// ```
/// -- called input.drift
/// import 'package:my_package/converter.dart';
///
/// CREATE TABLE users (
///   preferences TEXT MAPPED BY `const PreferencesConverter()`
/// );
/// ```
/// For that file, the [PreprocessBuilder] would generate a hidden json file
/// which contains information about the static type of all expressions in
/// the drift file. The main generator can then read this hidden file to resolve
/// those expressions.
///
/// To aid further analysis steps, a list of all table and view names is also
/// emitted into the json. That way, further analysis steps can easily recognize
/// dependencies between different definitions.
class PreprocessBuilder extends Builder {
  static const _outputs = ['.temp.dart', '.drift_prep.json'];

  PreprocessBuilder();

  @override
  late final Map<String, List<String>> buildExtensions = {
    '.moor': _outputs,
    '.drift': _outputs
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final backend = DriftBuildBackend(buildStep);
    final input = buildStep.inputId;
    final preprocessor = await DriftPreprocessor.analyze(backend, input.uri);

    final tempDartAsset = input.changeExtension('.temp.dart');
    await buildStep.writeAsString(
        tempDartAsset, preprocessor.temporaryDartFile);

    // And the file mapping Dart expressions onto the variable names here
    final outputAsset = input.changeExtension('.drift_prep.json');
    await buildStep.writeAsString(
        outputAsset, json.encode(preprocessor.result.toJson()));
  }
}
