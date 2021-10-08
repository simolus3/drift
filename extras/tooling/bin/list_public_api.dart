import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;

/// Lists all top-level API members of a package.
Future<void> main() async {
  final dir = Directory.current.path;
  final context =
      AnalysisContextCollection(includedPaths: [dir]).contextFor(dir);

  final names = <String>{};

  await for (final libFile in Directory(p.join(dir, 'lib')).list()) {
    final result = await context.currentSession.getUnitElement(libFile.path);

    if (result is UnitElementResult) {
      final ns = result.element.library.exportNamespace;
      names.addAll(ns.definedNames.keys);
    } else {
      stderr.writeln('Could not analyze ${libFile.path}');
    }
  }

  await stderr.flush();
  names.forEach(print);
}
