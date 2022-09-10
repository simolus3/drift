import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqlparser/sqlparser.dart' hide AnalysisError;

import '../driver/driver.dart';
import '../driver/error.dart';
import '../driver/state.dart';
import '../results/element.dart';
import 'dart/helper.dart';
import 'intermediate_state.dart';

class DiscoverStep {
  final DriftAnalysisDriver _driver;
  final FileState _file;

  DiscoverStep(this._driver, this._file);

  DriftElementId _id(String name) => DriftElementId(_file.ownUri, name);

  Future<void> discover() async {
    final extension = _file.extension;
    final pendingElements = <DiscoveredElement>[];

    switch (extension) {
      case '.dart':
        try {
          final library = await _driver.backend.readDart(_file.ownUri);
          final finder =
              _FindDartElements(this, library, await _driver.loadKnownTypes());
          await finder.find();

          _file.errorsDuringDiscovery.addAll(finder.errors);
          _file.discovery = DiscoveredDartLibrary(library, finder.found);
        } catch (e, s) {
          _driver.backend.log
              .fine('Could not read Dart library from ${_file.ownUri}', e, s);
          _file.discovery = NotADartLibrary();
        }
        break;
      case '.drift':
        final engine = _driver.newSqlEngine();
        String contents;
        try {
          contents = await _driver.backend.readAsString(_file.ownUri);
        } catch (e, s) {
          _driver.backend.log
              .fine('Could not read drift sources ${_file.ownUri}', e, s);
          _file.discovery = NoSuchFile();
          break;
        }

        final parsed = engine.parseDriftFile(contents);
        for (final error in parsed.errors) {
          _file.errorsDuringDiscovery
              .add(DriftAnalysisError(error.token.span, error.message));
        }

        final ast = parsed.rootNode as DriftFile;
        final imports = <DriftFileImport>[];

        for (final node in ast.childNodes) {
          if (node is ImportStatement) {
            final uri =
                _driver.backend.resolveUri(_file.ownUri, node.importedFile);

            imports.add(DriftFileImport(node, uri));
          } else if (node is TableInducingStatement) {
            pendingElements
                .add(DiscoveredDriftTable(_id(node.createdName), node));
          } else if (node is CreateViewStatement) {
            pendingElements
                .add(DiscoveredDriftView(_id(node.createdName), node));
          } else if (node is CreateIndexStatement) {
            pendingElements
                .add(DiscoveredDriftIndex(_id(node.indexName), node));
          }
        }

        _file.discovery = DiscoveredDriftFile(
          originalSource: contents,
          ast: parsed.rootNode as DriftFile,
          imports: imports,
          locallyDefinedElements: pendingElements,
        );
        break;
    }
  }
}

class _FindDartElements extends RecursiveElementVisitor<void> {
  final DiscoverStep _discoverStep;
  final LibraryElement _library;
  final TypeChecker _isTable;

  final List<Future<void>> _pendingWork = [];

  final errors = <DriftAnalysisError>[];
  final found = <DiscoveredElement>[];

  _FindDartElements(
      this._discoverStep, this._library, KnownDriftTypes knownTypes)
      : _isTable = TypeChecker.fromStatic(knownTypes.tableType);

  Future<void> find() async {
    visitLibraryElement(_library);
    await Future.wait(_pendingWork);
  }

  @override
  void visitClassElement(ClassElement element) {
    if (_isTable.isAssignableFrom(element)) {
      _pendingWork.add(Future.sync(() async {
        final name = await _sqlNameOfTable(element);
        final id = _discoverStep._id(name);

        found.add(DiscoveredDartTable(id, element));
      }));
    }

    super.visitClassElement(element);
  }

  /// Obtains the SQL schema name of a Dart-defined table.
  ///
  /// By default, we use the `snake_case` transformation of the classes' name.
  /// E.g. a class `class TrackedUsers extends Table` will yield a SQL table
  /// named `tracked_user`.
  /// The default behavior can be overridden by declaring a getter named
  /// `tableName` returning a direct string literal.
  Future<String> _sqlNameOfTable(ClassElement table) async {
    final defaultName = ReCase(table.name).snakeCase;

    final tableNameGetter = table.lookUpGetter('tableName', _library);
    if (tableNameGetter == null ||
        tableNameGetter.isFromDefaultTable ||
        tableNameGetter.isAbstract) {
      // class does not override tableName, so fall back to the default case.
      return defaultName;
    }

    final node = await _discoverStep._driver.backend
        .loadElementDeclaration(tableNameGetter);
    final returnExpr = returnExpressionOfMethod(node as dart.MethodDeclaration);

    const message =
        'This getter must directly return a string literal with the `=>` syntax';

    if (returnExpr == null) {
      errors.add(DriftAnalysisError.forDartElement(tableNameGetter, message));
      return defaultName;
    }

    final value =
        (returnExpr is dart.StringLiteral) ? returnExpr.stringValue : null;
    if (value == null) {
      errors.add(DriftAnalysisError.forDartElement(tableNameGetter, message));
      return defaultName;
    }

    return value;
  }
}
