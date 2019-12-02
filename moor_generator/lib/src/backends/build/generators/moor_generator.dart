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
      writer.leaf().write(
          '// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this, always_specify_types, implicit_dynamic_parameter, sort_constructors_first, implicit_dynamic_map_literal, avoid_renaming_method_parameters, sort_constructors_first, lines_longer_than_80_chars\n');
    }

    for (var db in parsed.declaredDatabases) {
      DatabaseWriter(db, writer.child()).write();
    }

    return writer.writeGenerated();
  }
}
