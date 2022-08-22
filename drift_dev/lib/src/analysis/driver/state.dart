import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' show url;
import 'package:sqlparser/sqlparser.dart' hide AnalysisError;

import '../results/element.dart';
import '../results/file.dart';
import 'error.dart';

class FileState {
  final Uri ownUri;

  DiscoveredFileState? discovery;
  AnalyzedFile? results;

  final List<AnalysisError> errorsDuringDiscovery = [];
  final List<AnalysisError> errorsDuringAnalysis = [];

  FileState(this.ownUri);

  String get extension => url.extension(ownUri.path);
}

abstract class DiscoveredFileState {
  final List<DiscoveredElement> locallyDefinedElements;

  DiscoveredFileState(this.locallyDefinedElements);
}

class DiscoveredDriftFile extends DiscoveredFileState {
  final DriftFile ast;

  DiscoveredDriftFile(this.ast, super.locallyDefinedElements);
}

class DiscoveredDartLibrary extends DiscoveredFileState {
  final LibraryElement library;

  DiscoveredDartLibrary(this.library, super.locallyDefinedElements);
}

class NotADartLibrary extends DiscoveredFileState {
  NotADartLibrary() : super(const []);
}

class NoSuchFile extends DiscoveredFileState {
  NoSuchFile() : super(const []);
}

abstract class DiscoveredElement {
  final DriftElementId ownId;

  DiscoveredElement(this.ownId);
}
