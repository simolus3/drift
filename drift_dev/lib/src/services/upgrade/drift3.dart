import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:drift/drift.dart' show SqlDialect;
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../../analysis/options.dart';
import '../../cli/project.dart';
import 'shared.dart';

/// A tool to upgrade a project using drift 2.x to drift 3.x.
final class UpgradeToDrift3 {
  final DriftProject project;
  final Logger logger;

  final AnalysisContext context;

  final Map<String, String> _updatedFiles = {};
  var _didTransformBuildYaml = false;

  UpgradeToDrift3._(this.project, this.context, this.logger);

  factory UpgradeToDrift3(DriftProject project, [Logger? logger]) {
    final collection = AnalysisContextCollection(
      includedPaths: [project.directory.path],
    );
    final context = collection.contextFor(project.directory.path);

    return UpgradeToDrift3._(
      project,
      context,
      logger ?? Logger.detached('upgrade-to-drift3'),
    );
  }

  Future<void> upgrade() async {
    await for (final file in project.sourceFiles) {
      await _transformFile(file);
    }

    if (!_didTransformBuildYaml) {
      final empty = YamlEditor('');
      empty.update([], {
        'targets': {
          r'$default': {
            'builders': {
              'drift_dev': {
                'options': {
                  'dialects': const DriftOptions.defaults()
                      .drift3DialectOptions(),
                },
              },
            },
          },
        },
      });

      _updatedFiles[p.join(project.directory.path, 'build.yaml')] = empty
          .toString();
    }

    for (final MapEntry(key: path, value: contents) in _updatedFiles.entries) {
      await File(path).writeAsString(contents);
    }
  }

  Future<void> _transformFile(File file) async {
    switch (p.extension(file.path)) {
      case '.dart':
        await _transformDartFile(file);
      case '.yaml':
        final name = p.basenameWithoutExtension(file.path);
        if (buildYamlPattern.hasMatch(name)) {
          await _transformBuildYaml(file);
        }
    }
  }

  Future<void> _transformDartFile(File file) async {
    final unitResult = await context.currentSession.getResolvedUnit(file.path);
    if (unitResult is! ResolvedUnitResult) {
      logger.warning('Could not analyze ${file.path}, skipping...');
      return;
    }

    final writer = _DartToDrift3Rewriter(unitResult.content);
    unitResult.unit.accept(writer);

    _updatedFiles[file.path] = writer.content;
  }

  Future<void> _transformBuildYaml(File file) async {
    final YamlEditor editor;
    try {
      editor = YamlEditor(await file.readAsString());
    } on Exception {
      logger.warning('Could not parse ${file.path}, ignoring...');
      return;
    }

    final sentinelNode = wrapAsYamlNode(null);
    final targets = editor.parseAt(['targets'], orElse: () => sentinelNode);
    if (targets is! YamlMap) return;

    for (final target in targets.keys.whereType<String>()) {
      final builders = editor.parseAt([
        'targets',
        target,
        'builders',
      ], orElse: () => sentinelNode);
      if (builders is! YamlMap) continue;

      for (final builder in builders.keys.whereType<String>()) {
        if (!builder.contains('drift_dev')) continue;

        final key = ['targets', target, 'builders', builder, 'options'];

        final options = editor.parseAt(key, orElse: () => sentinelNode);
        if (options is! YamlMap) continue;

        final DriftOptions parsedOptions;
        try {
          parsedOptions = DriftOptions.fromJson(options);
        } catch (e) {
          logger.warning(
            'Could not parse drift options for target $target in ${file.path}',
          );
          continue;
        }

        editor.update([
          ...key,
          'dialects',
        ], parsedOptions.drift3DialectOptions());
        const outdatedOptions = [
          'store_date_time_values_as_text',
          'sql',
          'sqlite_modules',
          'sqlite',
          'write_from_json_string_constructor',
        ];
        for (final outdated in outdatedOptions) {
          final path = [...key, outdated];
          final existing = editor.parseAt(path, orElse: () => sentinelNode);
          if (existing case YamlScalar(value: null)) continue;

          editor.remove(path);
        }

        _didTransformBuildYaml = true;
      }
    }

    if (!_didTransformBuildYaml) {
      var options = <String, Object?>{
        'options': {
          'dialects': const DriftOptions.defaults().drift3DialectOptions(),
        },
      };

      final key = ['targets', r'$default', 'builders', 'drift_dev'];

      while (true) {
        if (key.isEmpty) {
          editor.update([], options);
          break;
        }

        final parent = editor.parseAt(
          key.take(key.length - 1),
          orElse: () => sentinelNode,
        );
        if (parent case YamlScalar(value: null)) {
          // We can't write into this map directly because it doesn't exist.
          // Create the map in the outer structure instead.
          options = {key.removeLast(): options};
          continue;
        }

        editor.update(key, options);
        break;
      }

      _didTransformBuildYaml = true;
    }

    _updatedFiles[file.path] = editor.toString();
  }
}

final class _DartToDrift3Rewriter extends GeneralizingAstVisitor<void> {
  final StringRewriter _writer;

  String get content => _writer.content;

  _DartToDrift3Rewriter(String content) : _writer = StringRewriter(content);

  void _rewriteImportString(StringLiteral l) {
    const changedImports = {
      'drift': {
        'extensions/geopoly.dart':
            'package:drift_sqlite/extensions/geopoly.dart',
        'backends.dart': 'package:drift/drift.dart',
        'isolate.dart': 'package:drift_sqlite/native.dart',
        'wasm.dart': 'package:drift_sqlite/web.dart',
      },
      'drift_dev': {
        'api/migrations_common.dart':
            'package:drift_sqlite/schema_verifier.dart',
        'api/migrations_native.dart':
            'package:drift_sqlite/schema_verifier.dart',
        'api/migrations_web.dart': 'package:drift_sqlite/schema_verifier.dart',
        'api/migrations.dart': 'package:drift_sqlite/schema_verifier.dart',
      },
    };

    final value = l.stringValue;
    if (value == null) return;

    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'package') return;
    final segments = uri.pathSegments;
    if (segments.length <= 1) return;
    final [package, ...path] = segments;

    final replacement = changedImports[package]?[p.url.joinAll(path)];
    if (replacement != null) {
      _writer.replace(l.offset, l.length, asDartLiteral(replacement));
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _rewriteImportString(node.uri);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _rewriteImportString(node.uri);
  }
}

extension on DriftOptions {
  List<Object?> drift3DialectOptions() {
    return [
      for (final dialect in supportedDialects)
        switch (dialect) {
          SqlDialect.sqlite => {
            'dialect': 'sqlite',
            ...?sqliteAnalysisOptions?.toJson(),
            'strict_tables_by_default': false,
            'use_binary_json_representation': false,
            'store_date_times_as_text': storeDateTimeValuesAsText,
          },
          _ => {'dialect': dialect.name},
        },
    ];
  }
}
