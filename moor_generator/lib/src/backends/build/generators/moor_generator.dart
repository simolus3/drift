import 'package:build/build.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';
import 'package:moor_generator/src/writer/database_writer.dart';
import 'package:source_gen/source_gen.dart';

class MoorGenerator extends Generator implements BaseGenerator {
  @override
  MoorBuilder builder;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final parsed = await builder.analyzeDartFile(buildStep);
    final writer = builder.createWriter();

    if (parsed.declaredDatabases.isNotEmpty) {
      writer
          .leaf()
          .write('// ignore_for_file: unnecessary_brace_in_string_interps\n');
    }

    for (var db in parsed.declaredDatabases) {
      DatabaseWriter(db, writer.child()).write();
    }

    return writer.writeGenerated();
  }
}
