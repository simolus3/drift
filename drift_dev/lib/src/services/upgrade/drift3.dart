import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:drift/drift.dart' show SqlDialect;
import 'package:drift_dev/src/backends/analyzer_context_backend.dart';
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

  final AnalysisContextBackend backend;
  _KnownDriftImports? _knownImports;

  final Map<String, String> _updatedFiles = {};
  var _didTransformBuildYaml = false;

  UpgradeToDrift3._(this.project, this.backend, this.logger);

  factory UpgradeToDrift3(DriftProject project, [Logger? logger]) {
    final collection = AnalysisContextCollection(
      includedPaths: [project.directory.path],
    );
    final context = collection.contextFor(project.directory.path);

    return UpgradeToDrift3._(
      project,
      AnalysisContextBackend.withoutExpressionSupport(context),
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

  Future<_KnownDriftImports> _resolveKnownImports() async {
    if (_knownImports case final resolved?) return resolved;

    final library = await backend.readDart(
      Uri.parse('package:drift/drift.dart'),
    );
    return _knownImports = _KnownDriftImports(library);
  }

  Future<void> _transformDartFile(File file) async {
    final contents = await file.readAsString();
    if (contents.contains('// GENERATED CODE - DO NOT MODIFY BY HAND')) {
      return;
    }

    final imports = await _resolveKnownImports();
    final unitResult = await backend.context.currentSession.getResolvedUnit(
      file.path,
    );
    if (unitResult is! ResolvedUnitResult) {
      logger.warning('Could not analyze ${file.path}, skipping...');
      return;
    }

    final writer = _DartToDrift3Rewriter(
      contents,
      unitResult.libraryElement.typeSystem,
      imports,
    );
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
  final TypeSystem _typeSystem;
  final _KnownDriftImports _types;

  var isInTableDefinition = false;

  String get content => _writer.content;

  _DartToDrift3Rewriter(String content, this._typeSystem, this._types)
    : _writer = StringRewriter(content);

  void _rewriteImportString(StringLiteral l) {
    const changedImports = {
      'drift': {
        'extensions/geopoly.dart':
            'package:drift_sqlite/extensions/geopoly.dart',
        'backends.dart': 'package:drift3_preview/drift.dart',
        'drift.dart': 'package:drift3_preview/drift.dart',
        'isolate.dart': 'package:drift_sqlite/native.dart',
        'wasm.dart': 'package:drift_sqlite/web.dart',
        'web/worker.dart': 'package:drift_sqlite/web.dart',
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
      _writer.replaceNode(l, asDartLiteral(replacement));
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

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Transform usages of the pattern db.table.insertOne (and other extensions
    // defined in on_table.dart) into db.tableQueries.insertOne.
    if (node.function case SimpleIdentifier(:final element?)) {
      if (element.enclosingElement case ExtensionElement(
        name: 'TableOrViewStatements' || 'TableStatements',
      )) {
        // This needs a rewrite, which can be automated if the receiver is a
        // getter invocation from a database.
        if (node.target
            case PrefixedIdentifier(
              prefix: SimpleIdentifier(:final staticType?),
              identifier: final databaseGetter,
            )
            when _typeSystem.isSubtypeOf(
              staticType,
              _types.databaseConnectionUser,
            )) {
          _writer.replaceNode(databaseGetter, '${databaseGetter.name}Queries');
        }
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // In tables, replace text()() column definitions with just text()
    if (isInTableDefinition && node.isGetter) {
      if (node.body case ExpressionFunctionBody(:final expression)) {
        if (expression.asColumnDefinition() case final def?) {
          final args = def.argumentList;
          _writer.replaceNode(args, '');
          return;
        }
      }
    }

    super.visitMethodDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // In tables, rewrite `late final x = text()()` with
    // `Column<Text> get x => text()`.
    if (isInTableDefinition && node.fields.variables.length == 1) {
      final [declaredField] = node.fields.variables;
      final initializer = declaredField.initializer;
      final type = declaredField.declaredFragment?.element.type;

      if (declaredField.isLate &&
          declaredField.isFinal &&
          initializer != null &&
          type != null) {
        if (initializer.asColumnDefinition() case final def?) {
          final args = def.argumentList;

          final start = node.offset;
          final nameOffset = declaredField.name.offset;
          // late final $name => Column<Text> get $name
          _writer.replace(
            start,
            nameOffset - start,
            '${type.getDisplayString()} get ',
          );

          if (declaredField.equals case final equals?) {
            _writer.replaceNode(equals, '=>');
          }

          _writer.replaceNode(args, '');
          return;
        }
      }
    }

    super.visitFieldDeclaration(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final thisType = node.declaredFragment?.element.thisType;
    if (thisType != null &&
        _typeSystem.isSubtypeOf(thisType, _types.dslTable)) {
      isInTableDefinition = true;
      super.visitClassDeclaration(node);
      isInTableDefinition = false;
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _transformIdentifier(node, node.name, node.element);
  }

  @override
  void visitNamedType(NamedType node) {
    _transformIdentifier(node.name, node.name.lexeme, node.element);
    super.visitNamedType(node);
  }

  void _transformIdentifier(
    SyntacticEntity identifier,
    String name,
    Element? element,
  ) {
    String? newIdentifier;

    if (element == null && identifier is AstNode) {
      // It looks like left-hand identifiers of assignments don't have a
      // static element, infer from parent.
      if (identifier.parent is AssignmentExpression) {
        element = (identifier.parent as AssignmentExpression).writeElement;
      }
    }

    if (element == null) return;

    for (final annotation in element.metadata.annotations) {
      final value = annotation.computeConstantValue();
      if (value == null) return;
      final type = value.type;

      if (type is! InterfaceType) continue;

      if (type.element.library.isDartCore && type.element.name == 'pragma') {
        final name = value.getField('name')!.toStringValue()!;

        if (name == 'drift:v3-rename') {
          newIdentifier = value.getField('options')!.toStringValue()!;
          break;
        }
      }
    }

    if (newIdentifier != null) {
      _writer.replace(identifier.offset, name.length, newIdentifier);
    }
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

final class _KnownDriftImports {
  final InterfaceType databaseConnectionUser;
  final InterfaceType dslTable;

  _KnownDriftImports(LibraryElement drift)
    : databaseConnectionUser =
          (drift.exportNamespace.definedNames2['DatabaseConnectionUser']
                  as ClassElement)
              .thisType,
      dslTable = (drift.exportNamespace.definedNames2['Table'] as ClassElement)
          .thisType;
}

extension on Expression {
  FunctionExpressionInvocation? asColumnDefinition() {
    final invoke = this;
    if (invoke is FunctionExpressionInvocation) {
      final element = invoke.element;
      if (element case MethodElement(
        enclosingElement: ExtensionElement(name: 'BuildGeneralColumn'),
      )) {
        return invoke;
      }
    }

    return null;
  }
}
