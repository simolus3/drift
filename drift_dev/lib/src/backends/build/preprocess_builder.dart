import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:sqlparser/sqlparser.dart';

/// A support builder that runs before the main generator to parse and resolve
/// inline Dart resources in a moor file.
///
/// We use this builder to extract and analyze inline Dart expressions from
/// drift files, which are mainly used for type converters. For instance, let's
/// say we had a drift file like this:
/// ```
/// -- called input.drift
/// import 'package:my_package/converter.dart';
///
/// CREATE TABLE users (
///   preferences TEXT MAPPED BY `const PreferencesConverter()`
/// );
/// ```
/// For that file, the [PreprocessBuilder] would generate a `.dart_in_drift`
/// file which contains information about the static type of all expressions in
/// the drift file. The main generator can then read the `.dart_in_drift` file
/// to resolve those expressions.
class PreprocessBuilder extends Builder {
  static const _outputs = ['.temp.dart', '.dart_in_drift'];

  PreprocessBuilder();

  @override
  late final Map<String, List<String>> buildExtensions = {
    '.moor': _outputs,
    '.drift': _outputs
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    final moorFileContent = await buildStep.readAsString(input);
    final engine = SqlEngine(EngineOptions(useDriftExtensions: true));

    ParseResult parsedInput;
    try {
      parsedInput = engine.parseDriftFile(moorFileContent);
    } on Exception {
      // Drift file couldn't be parsed, ignore... If it's imported, the main
      // builder will provide a better error message.
      return;
    }

    final dartLexemes = parsedInput.tokens
        .whereType<InlineDartToken>()
        .map((token) => token.dartCode)
        .toList();

    if (dartLexemes.isEmpty) return; // nothing to do, no Dart in this moor file

    // Crawl through transitive imports and find all Dart libraries
    final seenFiles = <AssetId>{};
    final queue = <AssetId>[input];

    while (queue.isNotEmpty) {
      final asset = queue.removeLast();

      if (!seenFiles.contains(asset)) {
        seenFiles.add(asset);

        if (asset.extension == '.moor' || asset.extension == '.drift') {
          final parsed = asset == input
              ? parsedInput
              : engine.parseDriftFile(await buildStep.readAsString(asset));

          parsed.rootNode.allDescendants
              .whereType<ImportStatement>()
              .map((stmt) =>
                  AssetId.resolve(Uri.parse(stmt.importedFile), from: asset))
              .where((importedId) =>
                  !seenFiles.contains(importedId) &&
                  !queue.contains(importedId))
              .forEach(queue.add);
        }
      }
    }

    final importedDartFiles =
        seenFiles.where((asset) => asset.extension == '.dart');

    final codeToField = <String, String>{};

    // to analyze the expressions, generate a fake Dart file that declares each
    // expression in a `var`, we can then read the static type when resolving
    // file later.

    final dartBuffer = StringBuffer();
    for (final import in importedDartFiles) {
      final importUri = import.uri.toString();
      dartBuffer.write('import ${asDartLiteral(importUri)};\n');
    }

    for (var i = 0; i < dartLexemes.length; i++) {
      final name = _nameForDartExpr(i);
      dartBuffer.write('var $name = ${dartLexemes[i]};\n');
      codeToField[dartLexemes[i]] = name;
    }

    final tempDartAsset = input.changeExtension('.temp.dart');

    // Await the file needed to resolve types.
    await buildStep.writeAsString(tempDartAsset, dartBuffer.toString());

    // And the file mapping Dart expressions onto the variable names here
    final outputAsset = input.changeExtension('.dart_in_drift');
    await buildStep.writeAsString(outputAsset, json.encode(codeToField));
  }

  String _nameForDartExpr(int i) => 'expr_$i';
}
