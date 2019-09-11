import 'package:meta/meta.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/model/specified_db_classes.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:sqlparser/sqlparser.dart';

abstract class FileResult {}

class ParsedDartFile extends FileResult {
  final LibraryElement library;

  final List<SpecifiedTable> declaredTables;
  final List<SpecifiedDao> declaredDaos;
  final List<SpecifiedDatabase> declaredDatabases;

  Iterable<SpecifiedDbAccessor> get dbAccessors =>
      declaredDatabases.cast<SpecifiedDbAccessor>().followedBy(declaredDaos);

  ParsedDartFile(
      {@required this.library,
      this.declaredTables = const [],
      this.declaredDaos = const [],
      this.declaredDatabases = const []});
}

class ParsedMoorFile extends FileResult {
  final ParseResult parseResult;
  MoorFile get parsedFile => parseResult.rootNode as MoorFile;
  final List<SpecifiedTable> declaredTables;

  ParsedMoorFile(this.parseResult, {this.declaredTables = const []});
}
