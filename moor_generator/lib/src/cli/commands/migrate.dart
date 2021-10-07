// @dart=2.9
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;
import 'package:sqlparser/sqlparser.dart' hide AnalysisContext;
import 'package:yaml_edit/yaml_edit.dart';

import '../cli.dart';

class MigrateCommand extends MoorCommand {
  static final RegExp _buildYamlPattern = RegExp('(?:\w+\.)build(?:\.\w+)');

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

  Future<void> _transformBuildYaml(File file) async {}

  Future<void> _transformPubspec(File file) async {}
}
