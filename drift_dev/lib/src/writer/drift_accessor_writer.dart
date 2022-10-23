import '../analysis/results/results.dart';
import 'database_writer.dart';
import 'queries/query_writer.dart';
import 'writer.dart';

class AccessorWriter {
  final AccessorGenerationInput input;
  final Scope scope;

  AccessorWriter(this.input, this.scope);

  void write() {
    final classScope = scope.child();

    final daoName = input.accessor.declaration.name!;
    final dbTypeName = classScope.dartCode(input.accessor.databaseClass);
    classScope.leaf().write('mixin _\$${daoName}Mixin on '
        'DatabaseAccessor<$dbTypeName> {\n');

    for (final entity in input.resolvedAccessor.availableElements
        .whereType<DriftElementWithResultSet>()) {
      final infoType = entity.entityInfoName;
      final getterName = entity.dbGetterName;
      classScope.leaf().write(
          '$infoType get $getterName => attachedDatabase.$getterName;\n');
    }

    for (final query in input.availableRegularQueries) {
      QueryWriter(classScope.child()).write(query);
    }

    classScope.leaf().write('}');
  }
}
