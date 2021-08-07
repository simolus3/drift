import 'package:build/build.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';
import 'package:moor_generator/src/utils/type_utils.dart';
import 'package:moor_generator/writer.dart';
import 'package:source_gen/source_gen.dart';

class DaoGenerator extends Generator implements BaseGenerator {
  @override
  late MoorBuilder builder;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final parsed = await builder.analyzeDartFile(buildStep);
    final writer =
        builder.createWriter(nnbd: library.element.isNonNullableByDefault);

    for (final dao in parsed.declaredDaos) {
      final classScope = writer.child();
      final element = dao.fromClass;

      final daoName = element!.displayName;

      final dbTypeName = dao.dbClass.codeString(writer.generationOptions);
      classScope.leaf().write('mixin _\$${daoName}Mixin on '
          'DatabaseAccessor<$dbTypeName> {\n');

      for (final table in dao.tables) {
        final infoType = table.entityInfoName;
        final getterName = table.dbGetterName;
        classScope.leaf().write(
            '$infoType get $getterName => attachedDatabase.$getterName;\n');
      }

      for (final query in dao.queries ?? const <SqlQuery>[]) {
        QueryWriter(query, classScope.child()).write();
      }

      classScope.leaf().write('}');
    }

    return writer.writeGenerated();
  }
}
