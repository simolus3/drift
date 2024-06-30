// ignore_for_file: unnecessary_this

part of "database_manager_writer.dart";

class _TableManagerWriter {
  /// The table that this manager is for
  final DriftTable table;

  /// Current generation scope
  final Scope scope;

  /// The name of the database class
  ///
  /// This does not contain any prefixes, use the [_templates] to get the correct name
  /// to use in the generated code
  final String dbClassName;

  final List<DriftTable> otherTables;

  _TableManagerWriter(
      {required this.table,
      required this.scope,
      required this.dbClassName,
      required this.otherTables});

  _ManagerCodeTemplates get _templates => _ManagerCodeTemplates(scope);

  void write(TextEmitter leaf) {
    // Write the typedefs for the companion builders
    final (
      typeDefinition: insertCompanionBuilderTypeDef,
      companionBuilder: insertCompanionBuilder
    ) = _templates.companionBuilder(table, leaf, isUpdate: false);
    final (
      typeDefinition: updateCompanionBuilderTypeDef,
      companionBuilder: updateCompanionBuilder
    ) = _templates.companionBuilder(table, leaf, isUpdate: true);

    leaf.writeln(insertCompanionBuilderTypeDef);
    leaf.writeln(updateCompanionBuilderTypeDef);

    // Gather the relationships to and from this table
    List<_Relation> relations =
        table.columns.map((e) => _getRelationForColumn(e)).nonNulls.toList();

    for (var otherTable in otherTables) {
      final otherTableRelations = otherTable.columns
          .map((e) => _getRelationForColumn(e))
          .nonNulls
          .toList();
      // Filter out the ones that don't point to the current table,
      // and then swap so that `currentTable` is the same as this classes table
      final reverseRelations = otherTableRelations
          .where((element) => element.swaped().currentTable.equals(table))
          .map((e) => e.swaped());
      relations.addAll(reverseRelations);
    }

    // Get all the field names that could be added for this class
    // Including ones that access relations
    final allFieldNames = <String>[];
    for (var column in table.columns) {
      // Only add columns that arent relations
      if (_getRelationForColumn(column) == null) {
        allFieldNames.add(column.nameInDart);
      }
    }
    for (var relation in relations) {
      allFieldNames.add(relation.fieldName);
    }

    // Use the above list to remove any relations whose names cause clashing
    relations = relations.where((relation) {
      final fieldNameCount = allFieldNames
          .where((fieldName) => fieldName == relation.fieldName)
          .length;
      if (fieldNameCount != 1) {
        print(
            "Duplicate orderings/filters detected for field \"${relation.fieldName}\" on table \"${table.entityInfoName}\"."
            " Filter and orderings for this field wont be generated."
            " Use the @ReferenceName() annotation to resolve this issue."
            " See https://drift.simonbinder.eu/docs/manager/#name-clashes for more information");
        return false;
      }
      return true;
    }).toList();

    // Remove any relations where the type isnt exactly the same (num and int)
    // This is caused by using different type converters
    relations = relations.where((relation) {
      String typeForColumn(DriftColumn column) {
        return column.typeConverter?.dartType.getDisplayString(
                withNullability: false) ?? // ignore: deprecated_member_use
            leaf.dartCode(leaf.innerColumnType(column.sqlType));
      }

      final currentType = typeForColumn(relation.currentColumn);
      final referencedType = typeForColumn(relation.referencedColumn);
      if (currentType != referencedType) {
        print(
            "\"${relation.currentTable.baseDartName}.${relation.currentColumn.nameInSql}\" has a type of \"$currentType\""
            " and \"${relation.referencedTable.baseDartName}.${relation.referencedColumn.nameInSql}\" has a type of \"$referencedType\"."
            " This is caused by using different type converters for the columns."
            " Filters, orderings and reference getters for this relation wont be generated.");
        return false;
      }
      return true;
    }).toList();

    final columnFilters = <String>[];
    final columnOrderings = <String>[];

    for (var column in table.columns) {
      // Skip columns that have a relation,
      // they will be generated later
      final relation = _getRelationForColumn(column);
      if (relation != null) {
        continue;
      }
      // The type that this column is (int, string, etc)
      final type = leaf.dartCode(leaf.innerColumnType(column.sqlType));
      if (column.typeConverter != null) {
        columnFilters.add(_templates.columnWithTypeConverterFilters(
            column: column, leaf: leaf, type: type));
      } else {
        columnFilters.add(_templates.standardColumnFilters(
            column: column, leaf: leaf, type: type));
      }
      columnOrderings.add(_templates.standardColumnOrderings(
          column: column, leaf: leaf, type: type));
    }

    for (var relation in relations) {
      columnFilters
          .add(_templates.relatedFilter(leaf: leaf, relation: relation));
      // Don't generate reverse ordering, only regular ones
      if (!relation.isReverse) {
        columnOrderings
            .add(_templates.relatedOrderings(leaf: leaf, relation: relation));
      }
    }

    leaf.write(_templates.filterComposer(
        table: table,
        leaf: leaf,
        dbClassName: dbClassName,
        columnFilters: columnFilters));
    leaf.write(_templates.orderingComposer(
        table: table,
        leaf: leaf,
        dbClassName: dbClassName,
        columnOrderings: columnOrderings));
    if (!scope.generationOptions.isModular && relations.isNotEmpty) {
      leaf.write(_templates.rowClassWithReferences(
          currentTable: table,
          relations: relations,
          leaf: leaf,
          dbClassName: dbClassName));
    }

    // Write the root and processed table managers
    leaf.write(_templates.rootTableManager(
        table: table,
        dbClassName: dbClassName,
        leaf: leaf,
        updateCompanionBuilder: updateCompanionBuilder,
        createCompanionBuilder: insertCompanionBuilder,
        relations: relations));
    leaf.write(_templates.processedTableManagerTypeDef(
        table: table,
        dbClassName: dbClassName,
        leaf: leaf,
        relations: relations));
  }
}

/// A helper class for holding table relations
class _Relation {
  DriftColumn currentColumn;
  DriftColumn referencedColumn;
  DriftTable get currentTable => currentColumn.owner as DriftTable;
  DriftTable get referencedTable => referencedColumn.owner as DriftTable;
  final bool isReverse;
  _Relation(
      {required this.currentColumn,
      required this.referencedColumn,
      this.isReverse = false});

  /// Returna copy of this class with the current and referenced columns swaped
  /// this is commonly used when finding reverse references
  _Relation swaped() {
    return _Relation(
        currentColumn: referencedColumn,
        referencedColumn: currentColumn,
        isReverse: !isReverse);
  }

  /// What field name to use when generating filters/ordering for this column
  ///
  /// E.G todoRefs, category, categories
  String get fieldName {
    return switch (isReverse) {
      false => currentColumn.nameInDart,
      true =>
        referencedColumn.referenceName ?? "${referencedTable.dbGetterName}Refs"
    };
  }
}

// Helper for checking if a table is the same as another
extension on DriftTable {
  bool equals(other) {
    if (identical(this, other)) {
      return true;
    } else if (other is! DriftTable) {
      return false;
    } else {
      return other.entityInfoName == this.entityInfoName;
    }
  }
}

// Utility function to get the referenced table and column
_Relation? _getRelationForColumn(DriftColumn column) {
  final referencedCol = column.constraints
      .whereType<ForeignKeyReference>()
      .firstOrNull
      ?.otherColumn;
  if (referencedCol != null && referencedCol.owner is DriftTable) {
    final relation =
        _Relation(currentColumn: column, referencedColumn: referencedCol);
    return relation;
  } else {
    return null;
  }
}
