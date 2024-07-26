import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final allMarkdownFiles = markdownDir
    .listSync(recursive: true)
    .whereType<File>()
    .where((element) => element.path.endsWith(".md"))
    .map((file) => DocFile(file))
    .toList();
final markdownDir = Directory.current / "pages" / "docs";
final snippetsDir = Directory.current / 'lib' / "snippets";
final migratedMarkdownPath = Directory.current / "docs" / "src";

void main() {
  /// Migrate the markdown files to the new format
  for (var docFile in allMarkdownFiles) {
    docFile.writeMigratedMarkdown();
  }
}

class DocFile {
  /// The file to be migrated
  final File file;

  /// The content of the file
  late final String content = file.readAsStringSync();

  /// The migrated content of the file
  late String migratedContent;

  /// The snippet files that this file references
  late final Map<String, Map<String, String>> snippets = {};

  DocFile(this.file) {
    /// Define a regular expression to match the snippet assignment annotations
    final regx = RegExp(
        r"""{% assign (.+?) = ['"]package:drift_docs\/snippets\/(.+?)['"].+%}""",
        multiLine: true);

    /// Find all the snippet annotations in the content
    final matches = regx.allMatches(content);

    /// Read the snippet files and store the content in a map
    for (var match in matches) {
      final snippetFileLabel = match.group(1)!;
      final snippetFilePath = snippetsDir - match.group(2)!;
      final snippetContent = snippetFilePath.readAsStringSync();

      final Map<String, String> snippetJson =
          Map.from(jsonDecode(snippetContent) as Map);
      if (snippets.containsKey(snippetFileLabel)) {
        snippets[snippetFileLabel]!.addAll(snippetJson);
      } else {
        snippets[snippetFileLabel] = snippetJson;
      }
    }

    /// Replace the snippet injection with the MkDocs snippet injection
    migratedContent = replaceSnippets(content);

    // Remove the legacy snippet annotations from the content
    migratedContent = migratedContent.replaceAllMapped(regx, (match) => "");

    // Replace the urls with the new format
    migratedContent = migratedContent.replaceAllMapped(
        RegExp(r"""\[(.+?)\]\({{ ['"](.+?)['"] \| pageUrl }}\)"""),
        (match) => "[${match.group(1)}](${match.group(2)})");

    // Replace page info block
    migratedContent = migratedContent.replaceAllMapped(
        RegExp(r"""{% block "blocks\/pageinfo" %}([^%]+?){% endblock %}"""),
        (match) => note(match.group(1)!, NoteType.note, null));

    // Replace the urls with the new format
    migratedContent = migratedContent.replaceAllMapped(
        RegExp(r"""^(#+.+){.+}""", multiLine: true),
        (match) => match.group(1)!);

    // Replace the alert blocks
    migratedContent = migratedContent.replaceAllMapped(
        RegExp(
            r"""{% block ["']blocks\/alert["'] title=["'](.+?)["'] color=["'](.+?)["'] %}([^%]+){% endblock %}""",
            multiLine: true), (match) {
      final title = match.group(1)!;
      final color = match.group(2)!;
      final content = match.group(3)!;
      return note(content, NoteType.byString(color), title);
    });
    // Replace the alert blocks without color
    migratedContent = migratedContent.replaceAllMapped(
        RegExp(
            r"""{% block ["']blocks\/alert["'] +title=["'](.+?)["'] +%}([^%]+){% endblock %}""",
            multiLine: true), (match) {
      final title = match.group(1)!;
      final content = match.group(2)!;
      return note(content, NoteType.note, title);
    });

    /// Replace the front matter with the new format
    migratedContent = migratedContent.replaceFirst(
        RegExp(r"---(.+?)---", multiLine: true, dotAll: true),
        readFrontMatter().toString());

    /// Remove version tags
    migratedContent = migratedContent.replaceAllMapped(
        "{% assign versions = 'package:drift_docs/versions.json' | readString | json_decode %}",
        (match) => "");
  }

  // String a(String content) {
  //   final startblockRegx =
  //       RegExp(r"""^{% block ['"]blocks\/(.+?)["s](.+)%}$""");
  //   final endblockRegx = RegExp(r"""^{% endblock %}$""");
  //   final startBlocks = startblockRegx.allMatches(content);
  //   final endBlocks = endblockRegx.allMatches(content);
  //   if (startBlocks.isEmpty) {
  //     return content;
  //   }
  //   final startBlock = startBlocks.first;

  //   /// We will get the end block with this index, however, we may adjust this index up if we meet start indexes
  //   int targetBlockIndex = 0;

  //   final blocks = startBlocks
  //       .map((e) => (isStart: true, match: e))
  //       .followedBy(endBlocks.map((e) => (isStart: false, match: e)))
  //       .sorted((a, b) => a.match.start.compareTo(b.match.start))
  //       .sublist(1);
  //   int seenEndBlocks = 0;
  //   ({bool isStart, RegExpMatch match}) endBlock;
  //   for (var block in blocks) {
  //     if (block.isStart) {
  //       // If there is another start block before a end block, we will skip a end block
  //       targetBlockIndex += 1;
  //     } else {
  //       if (targetBlockIndex == seenEndBlocks) {
  //         endBlock = block;
  //         break;
  //       } else {
  //         seenEndBlocks += 1;
  //       }
  //     }
  //   }
  // }

  /// Parse the front matter from the content
  FrontMatter readFrontMatter() {
    final matches = RegExp(r"---(.+?)---", multiLine: true, dotAll: true)
        .allMatches(content);
    final match = matches.first;
    final frontMatter = match.group(1);
    final yaml = loadYaml(frontMatter!);
    return FrontMatter(
        title: yaml["data"]['title'] as String,
        description: yaml?["data"]?['description'] as String?,
        weight: yaml?["data"]?['weight'] as int?,
        path: yaml?["data"]?['path'] as String?);
  }

  /// Replace the legacy snippet annotations with the MkDocs snippet injection
  String replaceSnippets(String content) {
    return content.replaceAllMapped(
        RegExp(
            r"""{% include "blocks\/snippet" snippets = (.+?) name = ['"](.+?)['"] %}""",
            multiLine: true), (match) {
      final snippetFile = match.group(1)!;
      final snippetName = match.group(2)!;
      try {
        return snippets[snippetFile]![snippetName]!;
      } catch (e) {
        print("Snippet not found: $snippetFile, $snippetName");
        rethrow;
      }
    });
  }

  void writeMigratedMarkdown() {
    final path = file.path;
    final newPath = path.replaceFirst("pages/", "");
    final newFile = File(newPath);
    newFile.createSync(recursive: true);
    newFile.writeAsStringSync(migratedContent);
  }
}

class FrontMatter extends Object {
  final String title;
  final String? description;
  final int? weight;
  final String? path;

  FrontMatter(
      {required this.title,
      required this.description,
      required this.weight,
      required this.path});

  @override
  String toString() {
    String result = "---\n\n";
    result += "title: $title\n";
    if (description != null) {
      result += "description: $description\n";
    }
    // TODO
    // if (weight != null) {
    //   result += "weight: $weight\n";
    // }
    // if (path != null) {
    //   result += "path: $path\n";
    // }
    result += "\n---";
    return result;
  }
}

extension on Directory {
  Directory operator /(String path) => Directory(p.join(this.path, path));
  File operator -(String path) => File(p.join(this.path, path));
}

enum NoteType {
  danger("danger"),
  info("info"),
  note("note"),
  warning("warning"),
  success("success");

  const NoteType(this.label);
  final String label;
  static NoteType byString(String label) {
    return NoteType.values.firstWhere((element) => element.label == label);
  }
}

String note(String content, NoteType type, String? header) {
  return """!!! ${type.name} "${header ?? ''}"

${indentText(content)}

""";
}

String indentText(String text) {
  return text.split("\n").map((e) => "    ${e.trim()}").join('\n');
}
