import 'package:build/build.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';
import 'package:moor_generator/src/writer/queries/query_writer.dart';
import 'package:source_gen/source_gen.dart';

class DaoGenerator extends Generator implements BaseGenerator {
  @override
  MoorBuilder builder;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final parsed = await builder.analyzeDartFile(buildStep);
    final writer = builder.createWriter();

    for (var dao in parsed.declaredDaos) {
      final classScope = writer.child();
      final element = dao.fromClass;

      final daoName = element.displayName;

      classScope.leaf().write('mixin _\$${daoName}Mixin on '
          'DatabaseAccessor<${dao.dbClass.displayName}> {\n');

      for (var table in dao.tables) {
        final infoType = table.tableInfoName;
        final getterName = table.tableFieldName;
        classScope
            .leaf()
            .write('$infoType get $getterName => db.$getterName;\n');
      }

      final writtenMappingMethods = <String>{};
      for (var query in dao.resolvedQueries) {
        QueryWriter(query, classScope.child(), writtenMappingMethods).write();
      }

      classScope.leaf().write('}');
    }

    return writer.writeGenerated();
  }
}
