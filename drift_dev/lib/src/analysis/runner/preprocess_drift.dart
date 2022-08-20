import 'package:json_annotation/json_annotation.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:path/path.dart' show url;

import '../../utils/string_escaper.dart';
import '../backend.dart';

part 'preprocess_drift.g.dart';

@JsonSerializable(constructor: '_')
class DriftPreprocessorResult {
  /// A map from inline Dart lexemes used in a `.drift` file to the name of
  /// fields in a file generated to help analyze them.
  ///
  /// Public APIs in the `analyzer` (or `build_resolvers`) packages only support
  /// resolving full Dart files. In a `.drift` file however, it is possible to
  /// write in-line Dart expressions in SQL, for instance to declare a type
  /// converter with `MAPPED BY const MyTypeConverter()`.
  /// To enable drift's analyzer to see the `const MyTypeConverter()` expression
  /// in a meaningful way, a preprocess step generates a hidden Dart source file
  /// storing these expressions as text:
  ///
  /// ```dart
  ///  var expr_1 = const MyTypeConverter();
  /// ```
  ///
  /// This map contains the lexemes of Dart expressions (like
  /// `const MyTypeConverter()`) as keys and maps to the name of fields to use
  /// (here, `expr_1`).
  final Map<String, String> inlineDartExpressionsToHelperField;

  /// The names of all tables and views declared in this `.drift` file.
  ///
  /// Having this information available helps drift's analyzer in a future
  /// steps. When a table or view name is encountered in another `.drift` file,
  /// knowing where that table is likely to be defined helps doing analysis in
  /// the right order.
  final List<String> declaredTablesAndViews;

  final List<Uri> imports;

  DriftPreprocessorResult._(this.inlineDartExpressionsToHelperField,
      this.declaredTablesAndViews, this.imports);

  factory DriftPreprocessorResult.fromJson(Map<String, Object?> json) =>
      _$DriftPreprocessorResultFromJson(json);

  Map<String, Object?> toJson() => _$DriftPreprocessorResultToJson(this);
}

class DriftPreprocessor {
  final DriftPreprocessorResult result;
  final String temporaryDartFile;

  DriftPreprocessor._(this.result, this.temporaryDartFile);

  static Iterable<Uri> _imports(AstNode node, Uri ownUri) {
    return node.allDescendants
        .whereType<ImportStatement>()
        .map((stmt) => ownUri.resolve(stmt.importedFile));
  }

  static Future<DriftPreprocessor> analyze(
      DriftBackend backend, Uri uri) async {
    final contents = await backend.readAsString(uri);
    final engine = SqlEngine(EngineOptions(
        useDriftExtensions: true, version: SqliteVersion.current));
    final parsedInput = engine.parseDriftFile(contents);

    final directImports = _imports(parsedInput.rootNode, uri).toList();

    // Generate a hidden Dart helper file if this drift file uses inline Dart
    // expressions.
    final dartLexemes = parsedInput.tokens
        .whereType<InlineDartToken>()
        .map((token) => token.dartCode)
        .toList();

    var dartHelperFile = '';
    final codeToField = <String, String>{};

    if (dartLexemes.isNotEmpty) {
      // Imports in drift files are transitive, so we need to find all
      // transitive Dart sources to import into the generated helper file.
      final seenFiles = <Uri>{uri};
      final queue = [...directImports];

      while (queue.isNotEmpty) {
        final foundImport = queue.removeLast();

        if (!seenFiles.contains(foundImport)) {
          seenFiles.add(foundImport);

          final extension = url.extension(foundImport.path);
          if (extension == '.moor' || extension == '.drift') {
            ParseResult parsed;
            try {
              parsed = engine
                  .parseDriftFile(await backend.readAsString(foundImport));
            } catch (e, s) {
              // Not being able to read or parse this file isn't critical, we'll
              // just ignore the imports it contributes.
              // The main analysis step will definitely warn about the import
              // not existing or parse errors afterwards, so there's no need to
              // warn twice.
              backend.log.fine('Could not read or parse $foundImport', e, s);
              continue;
            }

            _imports(parsed.rootNode, foundImport)
                .where((importedId) =>
                    !seenFiles.contains(importedId) &&
                    !queue.contains(importedId))
                .forEach(queue.add);
          }
        }
      }

      final importedDartFiles =
          seenFiles.where((uri) => url.extension(uri.path) == '.dart');

      // to analyze the expressions, generate a fake Dart file that declares each
      // expression in a `var`, we can then read the static type when resolving
      // file later.

      final dartBuffer = StringBuffer();
      for (final import in importedDartFiles) {
        final importUri = import.toString();
        dartBuffer.writeln('import ${asDartLiteral(importUri)};');
      }

      for (var i = 0; i < dartLexemes.length; i++) {
        final name = 'expr_$i';
        dartBuffer.writeln('var $name = ${dartLexemes[i]};');
        codeToField[dartLexemes[i]] = name;
      }

      dartHelperFile = dartBuffer.toString();
    }

    final declaredTablesAndViews = <String>[];
    for (final entry in parsedInput.rootNode.childNodes) {
      if (entry is CreateTableStatement) {
        declaredTablesAndViews.add(entry.tableName);
      } else if (entry is CreateViewStatement) {
        declaredTablesAndViews.add(entry.viewName);
      }
    }

    final result = DriftPreprocessorResult._(
      codeToField,
      declaredTablesAndViews,
      directImports.toList(),
    );

    return DriftPreprocessor._(result, dartHelperFile);
  }
}
