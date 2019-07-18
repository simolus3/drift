import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/model/specified_database.dart';
import 'package:moor_generator/src/state/session.dart';
import 'package:source_gen/source_gen.dart';

class UseMoorParser {
  final GeneratorSession session;

  UseMoorParser(this.session);

  /// If [element] has a `@UseMoor` annotation, parses the database model
  /// declared by that class and the referenced tables.
  Future<SpecifiedDatabase> parseDatabase(
      ClassElement element, ConstantReader annotation) {
    final tableTypes =
        annotation.peek('tables').listValue.map((obj) => obj.toTypeValue());
  }
}
