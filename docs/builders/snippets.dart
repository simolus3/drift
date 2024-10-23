import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import 'src/excerpt.dart';
import 'src/highlighter.dart';

class SnippetsBuilder extends Builder {
  SnippetsBuilder(BuilderOptions options) : super();
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final outputAssetId = buildStep.allowedOutputs.single;
    final assetId = buildStep.inputId;
    if (assetId.package.startsWith(r'$') || assetId.path.endsWith(r'$')) return;

    final content = await buildStep.readAsString(assetId);
    final highlighter = Highlighter();
    final isDart = assetId.path.endsWith('.dart');
    final json = buildSnippets(content, highlighter, isDart: isDart);
    await buildStep.writeAsString(outputAssetId, json);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '': ['.excerpt.json'],
      };
}

/// Build the snippets from the file.
String buildSnippets(String code, Highlighter highlighter,
    {bool removeIndent = true, required bool isDart}) {
  var snippets = extractSnippets(code, removeIndent: removeIndent);
  final String json = jsonEncode(snippets.entries.map((e) {
    final String code;
    if (isDart) {
      final h = highlighter.highlight(e.value);
      code = h.toHTML();
    } else {
      code = e.value;
    }
    return {
      "name": e.key,
      "isHtml": isDart,
      "code": code,
    };
  }).toList());
  return json;
}
