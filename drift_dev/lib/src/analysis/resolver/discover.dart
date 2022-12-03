import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqlparser/sqlparser.dart' hide AnalysisError;

import '../driver/driver.dart';
import '../driver/error.dart';
import '../driver/state.dart';
import '../results/element.dart';
import 'dart/helper.dart';
import 'intermediate_state.dart';

/// Finds the name and kind (e.g. table, view, database, index, ...) of entries
/// defined in a given file.
class DiscoverStep {
  final DriftAnalysisDriver _driver;
  final FileState _file;

  DiscoverStep(this._driver, this._file);

  DriftElementId _id(String name) => DriftElementId(_file.ownUri, name);

  List<DiscoveredElement> _checkForDuplicates(List<DiscoveredElement> source) {
    final ids = <DriftElementId>{};
    final result = <DiscoveredElement>[];

    for (final found in source) {
      if (ids.add(found.ownId)) {
        result.add(found);
      } else {
        final DriftAnalysisError error;

        final msg =
            'This file already defines an element named `${found.ownId.name}`';

        if (found is DiscoveredDriftElement) {
          error = DriftAnalysisError.inDriftFile(found.sqlNode, msg);
        } else if (found is DiscoveredDartElement) {
          error = DriftAnalysisError.forDartElement(found.dartElement, msg);
        } else {
          error = DriftAnalysisError(null, msg);
        }

        _file.errorsDuringDiscovery.add(error);
      }
    }

    return result;
  }

  Future<void> discover() async {
    final extension = _file.extension;
    _file.discovery = UnknownFile();

    switch (extension) {
      case '.dart':
        LibraryElement library;
        try {
          library = await _driver.backend.readDart(_file.ownUri);
        } catch (e) {
          _file.discovery = NotADartLibrary();
          break;
        }
        final finder =
            _FindDartElements(this, library, await _driver.loadKnownTypes());
        await finder.find();

        _file.errorsDuringDiscovery.addAll(finder.errors);
        _file.discovery =
            DiscoveredDartLibrary(library, _checkForDuplicates(finder.found));
        break;
      case '.drift':
      case '.moor':
        final engine = _driver.newSqlEngine();
        final pendingElements = <DiscoveredDriftElement>[];

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

        var specialQueryNameCount = 0;

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
          } else if (node is CreateTriggerStatement) {
            pendingElements
                .add(DiscoveredDriftTrigger(_id(node.triggerName), node));
          } else if (node is DeclaredStatement) {
            String name;

            final declaredName = node.identifier;
            if (declaredName is SimpleName) {
              name = declaredName.name;
            } else {
              name = 'special:${specialQueryNameCount++}';
            }

            pendingElements.add(DiscoveredDriftStatement(_id(name), node));
          }
        }

        _file.discovery = DiscoveredDriftFile(
          originalSource: contents,
          ast: parsed.rootNode as DriftFile,
          imports: imports,
          locallyDefinedElements: _checkForDuplicates(pendingElements),
        );
        break;
    }
  }
}

class _FindDartElements extends RecursiveElementVisitor<void> {
  final DiscoverStep _discoverStep;
  final LibraryElement _library;

  final TypeChecker _isTable, _isView, _isTableInfo, _isDatabase, _isDao;

  final List<Future<void>> _pendingWork = [];

  final errors = <DriftAnalysisError>[];
  final found = <DiscoveredElement>[];

  _FindDartElements(
      this._discoverStep, this._library, KnownDriftTypes knownTypes)
      : _isTable = TypeChecker.fromStatic(knownTypes.tableType),
        _isView = TypeChecker.fromStatic(knownTypes.viewType),
        _isTableInfo = TypeChecker.fromStatic(knownTypes.tableInfoType),
        _isDatabase = TypeChecker.fromStatic(knownTypes.driftDatabase),
        _isDao = TypeChecker.fromStatic(knownTypes.driftAccessor);

  Future<void> find() async {
    visitLibraryElement(_library);
    await Future.wait(_pendingWork);
  }

  bool _isDslTable(ClassElement element) {
    // check if the table inherits from the drift table class. The !isExactly
    // check is here because we run this generator on drift itself and we get
    // weird errors for the Table class itself. In weird cases where we iterate
    // over generated code (standalone tool), don't report existing
    // implementations as tables.
    return _isTable.isAssignableFrom(element) &&
        !_isTable.isExactly(element) &&
        !_isTableInfo.isAssignableFrom(element) &&
        // Temporary workaround until https://github.com/dart-lang/source_gen/pull/628
        // gets merged.
        !element.mixins.any((e) => e.nameIfInterfaceType == 'TableInfo');
  }

  bool _isDslView(ClassElement element) {
    return _isView.isAssignableFrom(element) && !_isView.isExactly(element);
  }

  @override
  void visitClassElement(ClassElement element) {
    if (_isDslTable(element)) {
      _pendingWork.add(Future.sync(() async {
        final name = await _sqlNameOfTable(element);
        final id = _discoverStep._id(name);

        found.add(DiscoveredDartTable(id, element));
      }));
    } else if (_isDslView(element)) {
      final annotation = _driftViewAnnotation(element);
      final name = annotation?.getField('name')?.toStringValue() ??
          _defaultNameForTableOrView(element);
      final id = _discoverStep._id(name);

      found.add(DiscoveredDartView(id, element, annotation));
    } else {
      // Check if this class declares a database or a database accessor.

      final firstDb = _isDatabase.firstAnnotationOf(element);
      final firstDao = _isDao.firstAnnotationOf(element);
      final id = _discoverStep._id(element.name);

      if (firstDb != null) {
        found.add(DiscoveredBaseAccessor(id, element, firstDb, true));
      } else if (firstDao != null) {
        found.add(DiscoveredBaseAccessor(id, element, firstDao, false));
      }
    }

    super.visitClassElement(element);
  }

  String _defaultNameForTableOrView(ClassElement definingElement) {
    return _discoverStep._driver.options.caseFromDartToSql
        .apply(definingElement.name);
  }

  DartObject? _driftViewAnnotation(ClassElement view) {
    for (final annotation in view.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed!.type!.nameIfInterfaceType;

      if (annotationClass == 'DriftView') {
        return computed;
      }
    }

    return null;
  }

  /// Obtains the SQL schema name of a Dart-defined table.
  ///
  /// By default, we use the `snake_case` transformation of the classes' name.
  /// E.g. a class `class TrackedUsers extends Table` will yield a SQL table
  /// named `tracked_user`.
  /// The default behavior can be overridden by declaring a getter named
  /// `tableName` returning a direct string literal.
  Future<String> _sqlNameOfTable(ClassElement table) async {
    final defaultName = _defaultNameForTableOrView(table);

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
