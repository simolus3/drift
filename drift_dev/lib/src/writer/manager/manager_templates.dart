part of "database_manager_writer.dart";

/// A class which contains utility functions to generate manager class names
///
/// This is used by the [DatabaseManagerWriter] to generate code for the manager classes
class _ManagerCodeTemplates {
  _ManagerCodeTemplates(this._scope);

  /// A Scope class which contains the current scope of the generation
  ///
  /// Used to generating names which require import prefixes
  final Scope _scope;

  /// Returns the name of the manager class for a table
  ///
  /// This classes acts as container for all the table managers
  ///
  /// E.g. `AppDatabaseManager`
  String databaseManagerName(String dbClassName) {
    return '${dbClassName}Manager';
  }

  /// How the database will represented in the generated code
  ///
  /// When doing modular generation the table doesnt have direct access to the database class
  /// so it will use `GeneratedDatabase` as the generic type in such cases
  ///
  /// E.g. `i0.GeneratedDatabase` or `AppDatabase`
  String databaseType(TextEmitter leaf, String dbClassName) {
    return switch (_scope.generationOptions.isModular) {
      true => leaf.drift("GeneratedDatabase"),
      false => dbClassName,
    };
  }

  /// The code for the database manager getter which will be added to the main database class
  ///
  /// E.g. `AppDatabase get managers => AppDatabaseManager(this);`
  String databaseManagerGetter(String dbClassName) {
    return '${databaseManagerName(dbClassName)} get managers => ${databaseManagerName(dbClassName)}(this);';
  }

  /// The code for a root table manager getter which will be added to the database manager class
  ///
  /// E.g. `UserTableManager get todos => UserTableManager(_db,_db.todos);`
  String rootTableManagerGetter(
      DriftTable table, String rootTableManagerClass) {
    return '$rootTableManagerClass get ${table.dbGetterName} => $rootTableManagerClass(_db, _db.${table.dbGetterName});';
  }

  /// Returns the name of the root manager class for a table
  ///
  /// One of these classes is generated for each table in the database
  ///
  /// E.g. `\$UserTableManager`
  String rootTableManagerName(DriftTable table) {
    return '\$${table.entityInfoName}TableManager';
  }

  /// Returns the name of the manager class for a table
  ///
  /// When using modular generation the manager class will contain the correct prefix
  /// to access the table manager
  ///
  /// E.g. `i0.UserTableTableManager` or `\$UserTableTableManager`
  String rootTableManagerWithPrefix(DriftTable table, TextEmitter leaf) {
    return leaf
        .dartCode(leaf.generatedElement(table, rootTableManagerName(table)));
  }

  /// Returns the name of the processed table manager class for a table
  ///
  /// This does not contain any prefixes, as this will always be generated in the same file
  /// as the table manager and is not used outside of the file
  ///
  /// E.g. `$UserTableProcessedTableManager`
  String processedTableManagerName(DriftTable table) {
    return '\$${table.entityInfoName}ProcessedTableManager';
  }

  /// Class which represents a table in the database
  /// Contains the prefix if the generation is modular
  /// E.g. `i0.UserTable`
  String tableClassWithPrefix(DriftTable table, TextEmitter leaf) =>
      leaf.dartCode(leaf.entityInfoType(table));

  /// Class which represents a row in the table
  /// Contains the prefix if the generation is modular
  /// E.g. `i0.User`
  String rowClassWithPrefix(DriftTable table, TextEmitter leaf) =>
      leaf.dartCode(leaf.writer.rowType(table));

  /// Name of this tables filter composer class
  String filterComposerNameWithPrefix(DriftTable table, TextEmitter leaf) {
    return leaf
        .dartCode(leaf.generatedElement(table, filterComposerName(table)));
  }

  /// Name of this tables filter composer class
  String filterComposerName(
    DriftTable table,
  ) {
    return '\$${table.entityInfoName}FilterComposer';
  }

  /// Name of this tables ordering composer class
  String orderingComposerNameWithPrefix(DriftTable table, TextEmitter leaf) {
    return leaf
        .dartCode(leaf.generatedElement(table, orderingComposerName(table)));
  }

  /// Name of this tables ordering composer class
  String orderingComposerName(DriftTable table) {
    return '\$${table.entityInfoName}OrderingComposer';
  }

  /// Name of the typedef for the insert companion builder for a table
  ///
  /// This is the name of the typedef of a function that creates new rows in the table
  String insertCompanionBuilderTypeDef(DriftTable table) {
    return '\$${table.entityInfoName}InsertCompanionBuilder';
  }

  /// Name of the typedef for the update companion builder for a table
  ///
  /// This is the name of the typedef of a function that updates rows in the table
  String updateCompanionBuilderTypeDefName(DriftTable table) {
    return '\$${table.entityInfoName}UpdateCompanionBuilder';
  }

  /// Build the builder for a companion class
  /// This is used to build the insert and update companions
  /// Returns a tuple with the typedef and the builder
  /// Use [isUpdate] to determine if the builder is for an update or insert companion
  ({String typeDefinition, String companionBuilder}) companionBuilder(
      DriftTable table, TextEmitter leaf,
      {required bool isUpdate}) {
    // Get the name of the typedef
    final typedefName = isUpdate
        ? updateCompanionBuilderTypeDefName(table)
        : insertCompanionBuilderTypeDef(table);

    // Get the companion class name
    final companionClassName = leaf.dartCode(leaf.companionType(table));

    // Build the typedef and the builder in 3 parts
    // 1. The typedef definition
    // 2. The arguments for the builder
    // 3. The body of the builder
    final companionBuilderTypeDef =
        StringBuffer('typedef $typedefName = $companionClassName Function({');
    final companionBuilderArguments = StringBuffer('({');
    final StringBuffer companionBuilderBody;
    if (isUpdate) {
      companionBuilderBody = StringBuffer('=> $companionClassName(');
    } else {
      companionBuilderBody = StringBuffer('=> $companionClassName.insert(');
    }
    for (final column in UpdateCompanionWriter(table, _scope).columns) {
      final value = leaf.drift('Value');
      final param = column.nameInDart;
      final typeName = leaf.dartCode(leaf.dartType(column));

      companionBuilderBody.write('$param: $param,');

      // When writing an update companion builder, all fields are optional
      // they are all therefor defaulted to absent
      if (isUpdate) {
        companionBuilderTypeDef.write('$value<$typeName> $param,');
        companionBuilderArguments
            .write('$value<$typeName> $param = const $value.absent(),');
      } else {
        // Otherwise, for insert companions, required fields are required
        // and optional fields are defaulted to absent
        if (!column.isImplicitRowId &&
            table.isColumnRequiredForInsert(column)) {
          companionBuilderTypeDef.write('required $typeName $param,');
          companionBuilderArguments.write('required $typeName $param,');
        } else {
          companionBuilderTypeDef.write('$value<$typeName> $param,');
          companionBuilderArguments
              .write('$value<$typeName> $param = const $value.absent(),');
        }
      }
    }
    companionBuilderTypeDef.write('});');
    companionBuilderArguments.write('})');
    companionBuilderBody.write(")");
    return (
      typeDefinition: companionBuilderTypeDef.toString(),
      companionBuilder:
          companionBuilderArguments.toString() + companionBuilderBody.toString()
    );
  }

  /// Generic type arguments for the root and processed table manager
  String _tableManagerTypeArguments(
      DriftTable table, String dbClassName, TextEmitter leaf) {
    return """
    <${databaseType(leaf, dbClassName)},
    ${tableClassWithPrefix(table, leaf)},
    ${rowClassWithPrefix(table, leaf)},
    ${filterComposerNameWithPrefix(table, leaf)},
    ${orderingComposerNameWithPrefix(table, leaf)},
    ${processedTableManagerName(table)},

    ${insertCompanionBuilderTypeDef(table)},
    ${updateCompanionBuilderTypeDefName(table)}>""";
  }

  /// Code for getting a table from inside a composer
  /// handles modular generation correctly
  String _referenceTableFromComposer(DriftTable table, TextEmitter leaf) {
    if (_scope.generationOptions.isModular) {
      final extension = leaf.refUri(
          ModularAccessorWriter.modularSupport, 'ReadDatabaseContainer');
      final type = leaf.dartCode(leaf.entityInfoType(table));
      return "$extension(\$state.db).resultSet<$type>('${table.schemaName}')";
    } else {
      return '\$state.db.${table.dbGetterName}';
    }
  }

  /// Returns code for the root table manager class
  String rootTableManager({
    required DriftTable table,
    required String dbClassName,
    required TextEmitter leaf,
    required String updateCompanionBuilder,
    required String insertCompanionBuilder,
  }) {
    return """class ${rootTableManagerName(table)} extends ${leaf.drift("RootTableManager")}${_tableManagerTypeArguments(table, dbClassName, leaf)} {
    ${rootTableManagerName(table)}(${databaseType(leaf, dbClassName)} db, ${tableClassWithPrefix(table, leaf)} table) : super(
      ${leaf.drift("TableManagerState")}(
        db: db,
        table: table,
        filteringComposer: ${filterComposerNameWithPrefix(table, leaf)}(${leaf.drift("ComposerState")}(db, table)),
        orderingComposer: ${orderingComposerNameWithPrefix(table, leaf)}(${leaf.drift("ComposerState")}(db, table)),
        getChildManagerBuilder: (p) => ${processedTableManagerName(table)}(p),
        getUpdateCompanionBuilder: $updateCompanionBuilder,
        getInsertCompanionBuilder:$insertCompanionBuilder,));
        }
    """;
  }

  /// Returns code for the processed table manager class
  String processedTableManager({
    required DriftTable table,
    required String dbClassName,
    required TextEmitter leaf,
  }) {
    return """class ${processedTableManagerName(table)} extends ${leaf.drift("ProcessedTableManager")}${_tableManagerTypeArguments(table, dbClassName, leaf)} {
    ${processedTableManagerName(table)}(super.\$state);
      }
    """;
  }

  /// Returns the code for a tables filter composer
  String filterComposer({
    required DriftTable table,
    required TextEmitter leaf,
    required String dbClassName,
    required List<String> columnFilters,
  }) {
    return """class ${filterComposerName(table)} extends ${leaf.drift("FilterComposer")}<
        ${databaseType(leaf, dbClassName)},
        ${tableClassWithPrefix(table, leaf)}> {
        ${filterComposerName(table)}(super.\$state);
          ${columnFilters.join('\n')}
        }
      """;
  }

  /// Returns the code for a tables ordering composer
  String orderingComposer(
      {required DriftTable table,
      required TextEmitter leaf,
      required String dbClassName,
      required List<String> columnOrderings}) {
    return """class ${orderingComposerName(table)} extends ${leaf.drift("OrderingComposer")}<
        ${databaseType(leaf, dbClassName)},
        ${tableClassWithPrefix(table, leaf)}> {
        ${orderingComposerName(table)}(super.\$state);
          ${columnOrderings.join('\n')}
        }
      """;
  }

  /// Code for a filter for a standard column (no relations or type convertions)
  String standardColumnFilters(
      {required TextEmitter leaf,
      required DriftColumn column,
      required String type}) {
    final filterName = column.nameInDart;
    final columnGetter = column.nameInDart;

    return """${leaf.drift("ColumnFilters")}<$type> get $filterName => \$state.composableBuilder(
      column: \$state.table.$columnGetter,
      builder: (column, joinBuilders) => 
      ${leaf.drift("ColumnFilters")}(column, joinBuilders: joinBuilders));
      """;
  }

  /// Code for a filter for a column that has a type converter
  String columnWithTypeConverterFilters(
      {required TextEmitter leaf,
      required DriftColumn column,
      required String type}) {
    final filterName = column.nameInDart;
    final columnGetter = column.nameInDart;
    final converterType = leaf.dartCode(leaf.writer.dartType(column));
    final nonNullableConverterType = converterType.replaceFirst("?", "");
    return """
          ${leaf.drift("ColumnWithTypeConverterFilters")}<$converterType,$nonNullableConverterType,$type> get $filterName => \$state.composableBuilder(
      column: \$state.table.$columnGetter,
      builder: (column, joinBuilders) => 
      ${leaf.drift("ColumnWithTypeConverterFilters")}(column, joinBuilders: joinBuilders));
      """;
  }

  /// Code for a filter which works over a reference
  String relatedFitler(
      {required _Relation relation, required TextEmitter leaf}) {
    if (relation.isReverse) {
      return """
        ${leaf.drift("ComposableFilter")} ${relation.fieldName}(
          ${leaf.drift("ComposableFilter")}  Function( ${filterComposerNameWithPrefix(relation.referencedTable, leaf)} f) f
        ) {
          ${_referencedComposer(leaf: leaf, relation: relation, composerName: filterComposerNameWithPrefix(relation.referencedTable, leaf))}
          return f(composer);
        }
""";
    } else {
      return """
        ${filterComposerNameWithPrefix(relation.referencedTable, leaf)} get ${relation.fieldName} {
          ${_referencedComposer(leaf: leaf, relation: relation, composerName: filterComposerNameWithPrefix(relation.referencedTable, leaf))}
          return composer;
        }""";
    }
  }

  /// Code for a orderings for a standard column (no relations)
  String standardColumnOrderings(
      {required TextEmitter leaf,
      required DriftColumn column,
      required String type}) {
    final filterName = column.nameInDart;
    final columnGetter = column.nameInDart;

    return """${leaf.drift("ColumnOrderings")}<$type> get $filterName => \$state.composableBuilder(
      column: \$state.table.$columnGetter,
      builder: (column, joinBuilders) => 
      ${leaf.drift("ColumnOrderings")}(column, joinBuilders: joinBuilders));
      """;
  }

  /// Code for a ordering which works over a reference
  String relatedOrderings(
      {required _Relation relation, required TextEmitter leaf}) {
    assert(relation.isReverse == false,
        "Don't generate orderings for reverse relations");
    return """
        ${orderingComposerNameWithPrefix(relation.referencedTable, leaf)} get ${relation.fieldName} {
          ${_referencedComposer(leaf: leaf, relation: relation, composerName: orderingComposerNameWithPrefix(relation.referencedTable, leaf))}
          return composer;
        }""";
  }

  /// Code for creating a referenced composer, used by forward and reverse filters
  String _referencedComposer(
      {required _Relation relation,
      required TextEmitter leaf,
      required String composerName}) {
    return """
      final $composerName composer = \$state.composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.${relation.currentColumn.nameInDart},
      referencedTable: ${_referenceTableFromComposer(relation.referencedTable, leaf)},
      getReferencedColumn: (t) => t.${relation.referencedColumn.nameInDart},
      builder: (joinBuilder, parentComposers) => 
      $composerName(
        ${leaf.drift("ComposerState")}(
          \$state.db, ${_referenceTableFromComposer(relation.referencedTable, leaf)}, joinBuilder, parentComposers
        ))
              );""";
  }
}
