import 'package:moor/moor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';
import 'package:moor_generator/src/writer/database_writer.dart';
import 'package:moor_generator/src/writer/writer.dart';
import 'package:source_gen/source_gen.dart';

class MoorGenerator extends GeneratorForAnnotation<UseMoor>
    implements BaseGenerator {
  @override
  MoorBuilder builder;

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final task = await builder.createDartTask(buildStep);

    if (element is! ClassElement) {
      task.reportError(ErrorInDartCode(
        severity: Severity.criticalError,
        message: 'This annotation can only be used on classes',
        affectedElement: element,
      ));
    }

    final database =
        await task.parseDatabase(element as ClassElement, annotation);

    task.printErrors();

    if (database.tables.isEmpty) return '';

    final writer = Writer(builder.options);
    writer
        .leaf()
        .write('// ignore_for_file: unnecessary_brace_in_string_interps\n');

    DatabaseWriter(database, writer.child()).write();

    return writer.writeGenerated();
  }
}
