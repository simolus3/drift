import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/parser/sql/sql_parser.dart';
import 'package:moor_generator/src/shared_state.dart';
import 'package:moor/moor.dart';
import 'package:moor_generator/src/writer/query_writer.dart';
import 'package:moor_generator/src/writer/result_set_writer.dart';
import 'package:source_gen/source_gen.dart';

import 'model/sql_query.dart';

class DaoGenerator extends GeneratorForAnnotation<UseDao> {
  final SharedState state;

  DaoGenerator(this.state);

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final tableTypes =
        annotation.peek('tables').listValue.map((obj) => obj.toTypeValue());
    final parsedTables =
        tableTypes.map((type) => state.parseType(type, element)).toList();
    final queries = annotation.peek('queries')?.listValue ?? [];

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          'This annotation can only be used on classes',
          element: element);
    }

    final enclosingClass = element as ClassElement;
    var resolvedQueries = <SqlQuery>[];

    final dbType = enclosingClass.supertype;
    if (dbType.name != 'DatabaseAccessor') {
      throw InvalidGenerationSourceError(
          'This class must directly inherit from DatabaseAccessor',
          element: element);
    }

    // inherits from DatabaseAccessor<T>, we want to know which T
    final dbImpl = dbType.typeArguments.single;
    if (dbImpl.isDynamic) {
      throw InvalidGenerationSourceError(
          'This class must inherit from DatabaseAccessor<T>, where T is an '
          'actual type of a database.',
          element: element);
    }

    if (queries.isNotEmpty) {
      final parser = SqlParser(state, parsedTables, queries)..parse();

      resolvedQueries = parser.foundQueries;
    }

    // finally, we can write the mixin
    final buffer = StringBuffer();

    final daoName = enclosingClass.displayName;

    buffer.write('mixin _\$${daoName}Mixin on '
        'DatabaseAccessor<${dbImpl.displayName}> {\n');

    for (var table in parsedTables) {
      final infoType = table.tableInfoName;
      final getterName = table.tableFieldName;
      buffer.write('$infoType get $getterName => db.$getterName;\n');
    }

    for (var query in resolvedQueries) {
      QueryWriter(query).writeInto(buffer);
    }

    buffer.write('}');

    // if the queries introduced additional classes, also write those
    for (final query in resolvedQueries) {
      if (query is SqlSelectQuery && query.resultSet.matchingTable == null) {
        ResultSetWriter(query).write(buffer);
      }
    }

    return buffer.toString();
  }
}
