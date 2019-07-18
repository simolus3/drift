import 'package:moor/moor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/state/errors.dart';
import 'package:moor_generator/src/state/generator_state.dart';
import 'package:moor_generator/src/state/options.dart';
import 'package:moor_generator/src/writer/database_writer.dart';
import 'package:source_gen/source_gen.dart';

class MoorGenerator extends GeneratorForAnnotation<UseMoor> {
  final MoorOptions options;
  MoorGenerator(this.options);

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final state = useState(() => GeneratorState(options));
    final session = state.startSession(buildStep);

    if (element is! ClassElement) {
      session.errors.add(MoorError(
        critical: true,
        message: 'This annotation can only be used on classes',
        affectedElement: element,
      ));
    }

    final database =
        await session.parseDatabase(element as ClassElement, annotation);

    if (session.errors.errors.isNotEmpty) {
      print('Warning: There were some errors while running '
          'moor_generator on ${buildStep.inputId.path}:');

      for (var error in session.errors.errors) {
        print(error.message);

        if (error.affectedElement != null) {
          final span = spanForElement(error.affectedElement);
          print('${span.start.toolString}\n${span.highlight()}');
        }
      }
    }

    if (database.tables.isEmpty) return '';

    final buffer = StringBuffer()
      ..write('// ignore_for_file: unnecessary_brace_in_string_interps\n');

    DatabaseWriter(database, options).write(buffer);

    return buffer.toString();
  }
}
