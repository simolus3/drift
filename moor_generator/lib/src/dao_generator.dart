import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor/moor.dart';
import 'package:moor_generator/src/state/generator_state.dart';
import 'package:moor_generator/src/state/options.dart';
import 'package:moor_generator/src/writer/query_writer.dart';
import 'package:moor_generator/src/writer/result_set_writer.dart';
import 'package:source_gen/source_gen.dart';

import 'model/sql_query.dart';

class DaoGenerator extends GeneratorForAnnotation<UseDao> {
  final MoorOptions options;

  DaoGenerator(this.options);

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final state = useState(() => GeneratorState(options));
    final session = state.startSession(buildStep);

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          'This annotation can only be used on classes',
          element: element);
    }

    final targetClass = element as ClassElement;
    final parsedDao = await session.parseDao(targetClass, annotation);

    final dbType = targetClass.supertype;
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

    // finally, we can write the mixin
    final buffer = StringBuffer();

    final daoName = targetClass.displayName;

    buffer.write('mixin _\$${daoName}Mixin on '
        'DatabaseAccessor<${dbImpl.displayName}> {\n');

    for (var table in parsedDao.tables) {
      final infoType = table.tableInfoName;
      final getterName = table.tableFieldName;
      buffer.write('$infoType get $getterName => db.$getterName;\n');
    }

    final writtenMappingMethods = <String>{};
    for (var query in parsedDao.queries) {
      QueryWriter(query, session, writtenMappingMethods).writeInto(buffer);
    }

    buffer.write('}');

    // if the queries introduced additional classes, also write those
    for (final query in parsedDao.queries) {
      if (query is SqlSelectQuery && query.resultSet.matchingTable == null) {
        ResultSetWriter(query).write(buffer);
      }
    }

    return buffer.toString();
  }
}
