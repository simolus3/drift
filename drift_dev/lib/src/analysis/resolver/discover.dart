import 'package:sqlparser/sqlparser.dart' hide AnalysisError;

import '../driver/driver.dart';
import '../driver/error.dart';
import '../driver/state.dart';
import '../results/element.dart';
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
          _file.discovery = DiscoveredDartLibrary(library, []);
        } catch (e, s) {
          _driver.backend.log
              .fine('Could not read Dart library from ${_file.ownUri}', e, s);
          _file.discovery = NotADartLibrary();
        }
        break;
      case '.drift':
      case '.moor':
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
          }
        }

        _file.discovery = DiscoveredDriftFile(
          ast: parsed.rootNode as DriftFile,
          imports: imports,
          locallyDefinedElements: pendingElements,
        );
        break;
    }
  }
}
