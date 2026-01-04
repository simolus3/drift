import '../analysis/results/results.dart';
import 'database_writer.dart';
import 'manager/database_manager_writer.dart';
import 'modules.dart';
import 'queries/query_writer.dart';
import 'writer.dart';

class AccessorWriter {
  final AccessorGenerationInput input;
  final Scope scope;

  AccessorWriter(this.input, this.scope);

  void write() {
    final classScope = scope.child();
    final isModular = scope.generationOptions.isModular;
    final elements = input.resolvedAccessor.availableElements;

    final daoName = input.accessor.declaration.name!;

    final prefix = isModular ? '' : r'_';
    final mixinName = '$prefix\$${daoName}Mixin';
    classScope.leaf()
      ..write('mixin $mixinName on ')
      ..writeDriftRef('DatabaseAccessor<')
      ..writeDart(input.accessor.databaseClass)
      ..writeln('> {');

    for (final entity in input.resolvedAccessor.availableElements
        .whereType<DriftElementWithResultSet>()) {
      final infoType = scope.entityInfoType(entity);
      final getterName = entity.dbGetterName;

      final getterText = classScope.leaf()
        ..writeDart(infoType)
        ..writeln(' get $getterName =>');

      if (isModular) {
        getterText
          ..writeDart(getterText.referenceElement(entity, 'attachedDatabase'))
          ..writeln(';');
      } else {
        getterText.writeln('attachedDatabase.$getterName;');
      }
    }

    for (final query in input.availableRegularQueries) {
      QueryWriter(classScope.child()).write(query);
    }

    if (isModular) {
      for (final import in input.resolvedAccessor.knownImports) {
        classScope.writeGetterForIncludedDriftFile(import, input.driver!,
            isAccessor: true);
      }
    }

    if (scope.options.generateManager) {
      final managerWriter = DatabaseManagerWriter(scope.child(), daoName,
          accessorMixin: mixinName);
      for (var table in elements.whereType<DriftTable>()) {
        managerWriter.addTable(table);
      }

      managerWriter.writeDatabaseManager();
      classScope.leaf().writeln(managerWriter.databaseManagerGetter);
    }

    classScope.leaf().write('}');
  }
}
