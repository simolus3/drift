import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/model/specified_dao.dart';
import 'package:moor_generator/src/state/session.dart';
import 'package:source_gen/source_gen.dart';

class UseDaoParser {
  final GeneratorSession session;

  UseDaoParser(this.session);

  /// If [element] has a `@UseDao` annotation, parses the database model
  /// declared by that class and the referenced tables.
  Future<SpecifiedDao> parseDao(
      ClassElement element, ConstantReader annotation) async {
    final tableTypes =
        annotation.peek('tables').listValue.map((obj) => obj.toTypeValue());
    final queryStrings = annotation.peek('queries')?.mapValue ?? {};

    final parsedTables = await session.parseTables(tableTypes, element);
    final parsedQueries =
        await session.parseQueries(queryStrings, parsedTables);

    return SpecifiedDao(element, parsedTables, parsedQueries);
  }
}
