import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:recase/recase.dart';
import 'package:sally/sally.dart';
import 'package:sally_generator/src/model/specified_table.dart';
import 'package:source_gen/source_gen.dart';

class DaoGenerator extends GeneratorForAnnotation<UseDao> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final tableTypes =
        annotation.peek('tables').listValue.map((obj) => obj.toTypeValue());

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          'This annotation can only be used on classes',
          element: element);
    }

    final enclosingClass = element as ClassElement;

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

    // finally, we can write the mixin
    final buffer = StringBuffer();

    final daoName = enclosingClass.displayName;

    buffer.write('mixin _${daoName}Mixin on '
        'DatabaseAccessor<${dbImpl.displayName}> {\n');

    for (var table in tableTypes) {
      final infoType =
          tableInfoNameForTableClass(table.element as ClassElement);
      final getterName = ReCase(table.name).camelCase;

      buffer.write('$infoType get $getterName => db.$getterName;\n');
    }

    buffer.write('}');

    return buffer.toString();
  }
}
