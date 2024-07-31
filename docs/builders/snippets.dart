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
    final highlighter = Highlighter(theme: HighlighterTheme(ThemeMode.dark));
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
  final String json = Snippet.multipleToJson(snippets.entries.map((e) {
    return Snippet(
        name: e.key,
        isHtml: isDart,
        code: isDart ? highlighter.highlight(e.value).toHTML() : e.value);
  }));
  return json;
}

class Snippet {
  final String name;
  final String code;
  final bool isHtml;
  Snippet({
    required this.name,
    required this.code,
    required this.isHtml,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'code': code,
      'isHtml': isHtml,
    };
  }

  factory Snippet.fromMap(Map<String, dynamic> map) {
    return Snippet(
      name: map['name'] as String,
      code: map['code'] as String,
      isHtml: map['isHtml'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory Snippet.fromJson(String source) =>
      Snippet.fromMap(json.decode(source) as Map<String, dynamic>);
  static String multipleToJson(Iterable<Snippet> snippets) =>
      json.encode(snippets.map((x) => x.toMap()).toList());
}
