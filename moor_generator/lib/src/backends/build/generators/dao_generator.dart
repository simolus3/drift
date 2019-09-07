import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor/moor.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';
import 'package:moor_generator/src/writer/queries/query_writer.dart';
import 'package:moor_generator/src/writer/writer.dart';
import 'package:source_gen/source_gen.dart';

class DaoGenerator extends GeneratorForAnnotation<UseDao>
    implements BaseGenerator {
  @override
  MoorBuilder builder;

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final task = await builder.createDartTask(buildStep);

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          'This annotation can only be used on classes',
          element: element);
    }

    final targetClass = element as ClassElement;
    final parsedDao = await task.parseDao(targetClass, annotation);

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
    final writer = Writer(builder.options);
    final classScope = writer.child();

    final daoName = targetClass.displayName;

    classScope.leaf().write('mixin _\$${daoName}Mixin on '
        'DatabaseAccessor<${dbImpl.displayName}> {\n');

    for (var table in parsedDao.tables) {
      final infoType = table.tableInfoName;
      final getterName = table.tableFieldName;
      classScope.leaf().write('$infoType get $getterName => db.$getterName;\n');
    }

    final writtenMappingMethods = <String>{};
    for (var query in parsedDao.queries) {
      QueryWriter(query, classScope.child(), writtenMappingMethods).write();
    }

    classScope.leaf().write('}');

    return writer.writeGenerated();
  }
}
