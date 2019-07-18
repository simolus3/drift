import 'package:moor/moor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/model/specified_database.dart';
import 'package:moor_generator/src/state/generator_state.dart';
import 'package:moor_generator/src/state/options.dart';
import 'package:moor_generator/src/writer/database_writer.dart';
import 'package:source_gen/source_gen.dart';

import 'model/sql_query.dart';
import 'parser/sql/sql_parser.dart';

class MoorGenerator extends GeneratorForAnnotation<UseMoor> {
  final MoorOptions options;
  MoorGenerator(this.options);

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final state = useState(() => GeneratorState(options));
    final session = state.startSession(buildStep);

    final tableTypes =
        annotation.peek('tables').listValue.map((obj) => obj.toTypeValue());
    final daoTypes = annotation
        .peek('daos')
        .listValue
        .map((obj) => obj.toTypeValue())
        .toList();
    final queries = annotation.peek('queries')?.mapValue ?? {};

    final tablesForThisDb = await session.parseTables(tableTypes, element);
    var resolvedQueries = <SqlQuery>[];

    if (queries.isNotEmpty) {
      final parser = SqlParser(session, tablesForThisDb, queries)..parse();

      resolvedQueries = parser.foundQueries;
    }

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

    if (tablesForThisDb.isEmpty) return '';

    final specifiedDb = SpecifiedDatabase(
        element as ClassElement, tablesForThisDb, daoTypes, resolvedQueries);

    final buffer = StringBuffer()
      ..write('// ignore_for_file: unnecessary_brace_in_string_interps\n');

    DatabaseWriter(specifiedDb, options).write(buffer);

    return buffer.toString();
  }
}
