import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;

void main() async {
  final self = Platform.script.toFilePath();
  final contexts = AnalysisContextCollection(includedPaths: [p.dirname(self)]);
  final context = contexts.contextFor(self);

  final otherLibrary = await context.currentSession
      .getResolvedLibrary(p.normalize(p.join(self, '../drift_dev.dart')));
  otherLibrary as ResolvedLibraryResult;
  final typeProvider = otherLibrary.typeProvider;
  final typeSystem = otherLibrary.units.first.typeSystem;

  final thisLibrary = await context.currentSession.getResolvedLibrary(self);
  thisLibrary as ResolvedLibraryResult;

  final myList = thisLibrary.element.getClass('MyList')!;
  final coreList = typeProvider.listElement;
  final myListAsCoreList = myList.thisType.asInstanceOf(coreList)!;

  final intFromList = myListAsCoreList.typeArguments.single;
  final actualInt = typeProvider.intType;

  print(intFromList == actualInt);
}

class MyList extends ListBase<int> {
  @override
  int length = 0;

  @override
  int operator [](int index) {
    throw UnimplementedError();
  }

  @override
  void operator []=(int index, int value) {}
}
