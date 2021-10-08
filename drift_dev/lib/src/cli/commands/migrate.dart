// @dart=2.9
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:path/path.dart' as p;
import 'package:sqlparser/sqlparser.dart' hide AnalysisContext, StringLiteral;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../cli.dart';

class MigrateCommand extends MoorCommand {
  static final RegExp _buildYamlPattern =
      RegExp('(?:\\w+\\.)?build(?:\\.\\w+)?');
  static final RegExp _builderKeyPattern = RegExp('(?:(\\w+)[:|])?(\\w+)');

  AnalysisContext context;

  MigrateCommand(MoorCli cli) : super(cli);

  @override
  String get description => 'Migrate a project from moor to drift';

  @override
  String get name => 'migrate';

  @override
  Future<void> run() async {
    final collection =
        AnalysisContextCollection(includedPaths: [cli.project.directory.path]);
    context = collection.contextFor(cli.project.directory.path);

    await for (final file in cli.project.sourceFiles) {
      await _applyToFile(file);
    }
  }

  Future<void> _applyToFile(File file) async {
    switch (p.extension(file.path)) {
      case '.dart':
        await _transformDartFile(file);
        break;
      case '.moor':
        final newFile = File(p.setExtension(file.path, '.drift'));
        await newFile.writeAsString(await _transformMoorFile(file));
        break;
      case '.yaml':
        final name = p.basenameWithoutExtension(file.path);
        if (name == 'pubspec') {
          await _transformPubspec(file);
        } else if (_buildYamlPattern.hasMatch(name)) {
          await _transformBuildYaml(file);
        }
        break;
      default:
        break;
    }
  }

  Future<void> _transformDartFile(File file) async {
    final unitResult = await context.currentSession.getResolvedUnit(file.path);
    if (unitResult is! ResolvedUnitResult) {
      cli.logger.warning('Could not analyze ${file.path}, skipping...');
      return;
    }

    final typedResult = unitResult as ResolvedUnitResult;
    final writer = _Moor2DriftDartRewriter(await file.readAsString());
    typedResult.unit.accept(writer);

    await file.writeAsString(writer.content);
  }

  Future<String> _transformMoorFile(File file) async {
    final engine = SqlEngine(
        EngineOptions(useMoorExtensions: true, version: SqliteVersion.current));
    final originalContent = await file.readAsString();
    var output = originalContent;
    final result = engine.parseMoorFile(originalContent);

    if (result.errors.isNotEmpty) {
      cli.logger.warning('Could not parse ${file.path}, skipping...');
      return originalContent;
    }

    // Change imports to point from .moor to .drift files
    final root = result.rootNode as MoorFile;
    for (final import in root.imports) {
      final importedFile = import.importedFile;
      if (p.url.extension(importedFile) == '.moor') {
        final newImport = p.url.setExtension(importedFile, '.drift');
        output = output.replaceFirst(import.span.text, "import '$newImport';");
      }
    }

    return output;
  }

  String _newBuilder(String oldKey) {
    final match = _builderKeyPattern.firstMatch(oldKey);
    if (match == null) return oldKey;

    final builder = match.group(2);
    final package = match.group(1) ?? builder;

    if (package != 'moor_generator') return oldKey;

    if (builder == 'moor_generator') {
      return 'drift_dev';
    } else if (builder == 'moor_generator_not_shared') {
      return 'drift_dev|not_shared';
    } else {
      return 'drift_dev|$builder';
    }
  }

  Future<void> _transformBuildYaml(File file) async {
    dynamic originalBuildConfig;
    final originalContent = await file.readAsString();
    final writer = _StringRewriter(originalContent);

    try {
      originalBuildConfig = loadYaml(originalContent, sourceUrl: file.uri);
    } on Exception {
      cli.logger.warning('Could not parse ${file.path}, ignoring...');
    }

    if (originalBuildConfig is! Map) return;

    final targets = originalBuildConfig['targets'];
    if (targets is! Map) return;

    for (final key in (targets as Map).keys) {
      if (key is! String) continue;

      final builders = targets[key]['builders'];
      if (builders is! Map) continue;

      final buildersMap = builders as YamlMap;

      // Patch configured moor builders
      for (final yamlKey in buildersMap.nodes.keys.cast<YamlNode>()) {
        final builderKey = yamlKey.value as String;
        final newBuilder = _newBuilder(builderKey);

        if (newBuilder != builderKey) {
          final span = yamlKey.span;
          writer.replace(span.start.offset, span.length, newBuilder);
        }
      }
    }

    await file.writeAsString(writer.content);
  }

  Future<void> _transformPubspec(File file) async {
    dynamic originalPubspec;
    YamlEditor editor;

    try {
      final content = await file.readAsString();
      originalPubspec = loadYaml(content, sourceUrl: file.uri);
      editor = YamlEditor(content);
    } on Exception {
      cli.logger.warning('Could not parse ${file.path}, ignoring...');
    }

    const newPackages = {'moor': 'drift', 'moor_generator': 'drift_dev'};

    void replaceIn(String key) {
      if (originalPubspec is! Map) return;

      final dependencyBlock = originalPubspec[key];
      if (dependencyBlock is! Map) return;

      final block = dependencyBlock as Map;
      for (final package in newPackages.keys) {
        if (block.containsKey(package)) {
          final newPackage = newPackages[package];

          editor
            ..remove([key, package])
            ..update([key, newPackage], block[package]);
        }
      }
    }

    replaceIn('dependencies');
    replaceIn('dev_dependencies');
    replaceIn('dependency_overrides');

    await file.writeAsString(editor.toString());
  }
}

class _StringRewriter {
  String content;
  var _skew = 0;

  _StringRewriter(this.content);

  void replace(int start, int originalLength, String newContent) {
    content = content.replaceRange(
        _skew + start, _skew + start + originalLength, newContent);
    _skew += newContent.length - originalLength;
  }
}

class _Moor2DriftDartRewriter extends GeneralizingAstVisitor<void> {
  final _StringRewriter _writer;

  String get content => _writer.content;

  _Moor2DriftDartRewriter(String content) : _writer = _StringRewriter(content);

  void _rewriteImportString(StringLiteral l) {
    // Don't do anything if this is not a 'package:moor/` uri
    final value = l.stringValue;
    if (value == null) return;

    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'package') return;

    final segments = uri.pathSegments;
    if (segments.length <= 1 || segments[0] != 'moor') return;

    // Oh, it is a moor package import! Replace with the right drift import.
    var path = p.url.joinAll(segments.skip(1));

    // Some libraries have a changed path
    switch (path.toLowerCase()) {
      case 'moor.dart':
        path = 'drift.dart'; // moor/moor.dart -> drift/drift.dart
        break;
      case 'ffi.dart':
        path = 'native.dart'; // moor/ffi.dart -> drift/native.dart
        break;
      case 'extensions/moor_ffi.dart':
        path = 'extensions/native.dart'; // similar rename here
        break;
      case 'moor_web.dart':
        path = 'web.dart'; // moor/moor_web.dart -> drift/web.dart
        break;
    }

    final driftImport = 'package:drift/$path';
    _writer.replace(l.offset, l.length, asDartLiteral(driftImport));
  }

  @override
  void visitUriBasedDirective(UriBasedDirective node) {
    _rewriteImportString(node.uri);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element == null) {
      // It looks like left-hand identifiers of assignments don't have a static
      // element, infer from parent.
      if (node.parent is AssignmentExpression) {
        element = (node.parent as AssignmentExpression).writeElement;
      }

      if (element == null) return;
    }

    for (final annotation in element.metadata) {
      final value = annotation.computeConstantValue();
      if (value == null) return;
      final type = value.type;

      if (type is! InterfaceType) continue;

      final iType = type as InterfaceType;
      if (iType.element.library.isDartCore && iType.element.name == 'pragma') {
        final name = value.getField('name').toStringValue();

        if (name == 'moor2drift') {
          final newIdentifier = value.getField('options').toStringValue();
          _writer.replace(node.offset, node.length, newIdentifier);
          return;
        }
      }
    }
  }
}
