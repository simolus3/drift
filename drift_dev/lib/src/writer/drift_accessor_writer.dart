import '../analysis/results/results.dart';
import 'database_writer.dart';
import 'modules.dart';
import 'queries/query_writer.dart';
import 'writer.dart';

class AccessorWriter {
  final AccessorGenerationInput input;
  final Scope scope;

  AccessorWriter(this.input, this.scope);

  void write() {
    final classScope = scope.child();

    final daoName = input.accessor.declaration.name!;

    final prefix = scope.generationOptions.isModular ? '' : r'_';
    classScope.leaf()
      ..write('mixin $prefix\$${daoName}Mixin on ')
      ..writeDriftRef('DatabaseAccessor<')
      ..writeDart(input.accessor.databaseClass)
      ..writeln('> {');

    for (final entity in input.resolvedAccessor.availableElements
        .whereType<DriftElementWithResultSet>()) {
      final infoType = scope.entityInfoType(entity);
      final getterName = entity.dbGetterName;

      classScope.leaf()
        ..writeDart(infoType)
        ..writeln(' get $getterName => attachedDatabase.$getterName;');
    }

    for (final query in input.availableRegularQueries) {
      QueryWriter(classScope.child()).write(query);
    }

    if (scope.generationOptions.isModular) {
      for (final import in input.resolvedAccessor.knownImports) {
        classScope.writeGetterForIncludedDriftFile(import, input.driver,
            isAccessor: true);
      }
    }

    classScope.leaf().write('}');
  }
}
