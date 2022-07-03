import 'package:build/build.dart';
import 'package:drift_dev/src/backends/build/drift_builder.dart';
import 'package:drift_dev/src/utils/type_utils.dart';
import 'package:drift_dev/writer.dart';
import 'package:source_gen/source_gen.dart';

import '../../../model/base_entity.dart';

class DaoGenerator extends Generator implements BaseGenerator {
  @override
  late DriftBuilder builder;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final parsed = await builder.analyzeDartFile(buildStep);
    final writer = builder.createWriter();

    for (final dao in parsed.declaredDaos) {
      final classScope = writer.child();
      final element = dao.fromClass;

      final daoName = element!.displayName;

      final dbTypeName = dao.dbClass.codeString(writer.generationOptions);
      classScope.leaf().write('mixin _\$${daoName}Mixin on '
          'DatabaseAccessor<$dbTypeName> {\n');

      for (final entity in dao.entities.whereType<DriftEntityWithResultSet>()) {
        final infoType = entity.entityInfoName;
        final getterName = entity.dbGetterName;
        classScope.leaf().write(
            '$infoType get $getterName => attachedDatabase.$getterName;\n');
      }

      dao.queries
          ?.forEach((query) => QueryWriter(classScope.child()).write(query));

      classScope.leaf().write('}');
    }

    return writer.writeGenerated();
  }
}
