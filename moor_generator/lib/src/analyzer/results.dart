import 'package:meta/meta.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/model/specified_dao.dart';
import 'package:moor_generator/src/model/specified_database.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:sqlparser/sqlparser.dart';

abstract class ParsedFile {}

class ParsedDartFile extends ParsedFile {
  final LibraryElement library;

  final List<SpecifiedTable> declaredTables;
  final List<SpecifiedDao> declaredDaos;
  final List<SpecifiedDatabase> declaredDatabases;

  ParsedDartFile(
      {@required this.library,
      this.declaredTables = const [],
      this.declaredDaos = const [],
      this.declaredDatabases = const []});
}

class ParsedMoorFile extends ParsedFile {
  final ParseResult parseResult;
  MoorFile get parsedFile => parseResult.rootNode as MoorFile;
  final List<SpecifiedTable> declaredTables;

  ParsedMoorFile(this.parseResult, {this.declaredTables = const []});
}
