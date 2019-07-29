import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/src/model/specified_database.dart';
import 'package:moor_generator/src/state/session.dart';
import 'package:source_gen/source_gen.dart';

class UseMoorParser {
  final GeneratorSession session;

  UseMoorParser(this.session);

  /// If [element] has a `@UseMoor` annotation, parses the database model
  /// declared by that class and the referenced tables.
  Future<SpecifiedDatabase> parseDatabase(
      ClassElement element, ConstantReader annotation) async {
    // the types declared in UseMoor.tables
    final tableTypes =
        annotation.peek('tables').listValue.map((obj) => obj.toTypeValue());
    final queryStrings = annotation.peek('queries')?.mapValue ?? {};
    final includes = annotation
            .read('include')
            .objectValue
            .toSetValue()
            ?.map((e) => e.toStringValue()) ??
        {};

    final parsedTables = await session.parseTables(tableTypes, element);
    parsedTables.addAll(await session.resolveIncludes(includes));

    final parsedQueries =
        await session.parseQueries(queryStrings, parsedTables);
    final daoTypes = _readDaoTypes(annotation);

    return SpecifiedDatabase(element, parsedTables, daoTypes, parsedQueries);
  }

  List<DartType> _readDaoTypes(ConstantReader annotation) {
    return annotation
        .peek('daos')
        .listValue
        .map((obj) => obj.toTypeValue())
        .toList();
  }
}
