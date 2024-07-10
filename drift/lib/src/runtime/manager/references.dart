part of 'manager.dart';

/// A simple function for generating aliases for referenced columns
///
/// This function is used internally by generated code and should not be used directly.
// ignore: non_constant_identifier_names
String $_aliasNameGenerator(
    GeneratedColumn currentColumn, GeneratedColumn referencedColumn) {
  return '${currentColumn.tableName}__${currentColumn.name}__${referencedColumn.tableName}__${referencedColumn.name}';
}

/// Base class for the "WithReference" classes
///
/// When a user calls `withReferences` on a manager, the item is returned, along with an instance of this
/// class which contains getters for the referenced tables manager which are pre-filtered to the item.
/// So the following:
/// ```dart
/// final (group,refs) = await groups.filter((f) => f.id(5)).withReferences().getSingle()
/// final usersInGroup = refs.users.get() // filter((f) => f.group(group.id)) is already applied
/// ```
/// is short for:
/// ```dart
/// final group = await groups.filter((f) => f.id(5)).getSingle()
/// final usersInGroup = await users.filter((f) => f.group(group.id)).get()
/// ```
/// {@macro manager_internal_use_only}
class BaseReferences<$Database extends GeneratedDatabase, $Table extends Table,
    $Dataclass> {
  /// The database instance
  // ignore: non_constant_identifier_names
  final $Database $_db;

  /// The table of this item
  // ignore: non_constant_identifier_names
  final TableInfo<$Table, $Dataclass> $_table;

  /// The raw [TypedResult] for this item
  // ignore: non_constant_identifier_names
  final TypedResult $_typedResult;

  // The item these references are for
  // ignore: public_member_api_docs, non_constant_identifier_names
  late final $Dataclass $_item = $_typedResult.readTable($_table);

  /// Create a [BaseReferences] class
  // ignore: non_constant_identifier_names
  BaseReferences(this.$_db, this.$_table, this.$_typedResult);
}

/// Type definition for a function that transforms the state of a manager
typedef StateTransformer = T Function<
    T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic,
        dynamic, dynamic, dynamic, dynamic, dynamic>>(T $state);

T _defaultStateTransformer<
    T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic,
        dynamic, dynamic, dynamic, dynamic, dynamic>>(T $state) {
  return $state;
}

/// Type definition for a function which transforms a List of TypedResults
typedef TypedResultTransformer = Future<List<TypedResult>> Function(
    List<TypedResult> results);

/// When a user requests that certain fields are prefetched, we create a [PrefetchHooks] class for the manager.
/// This class has hooks for adding joins to the query before the query is executed, and for running prefetches after the query is executed.
/// {@macro manager_internal_use_only}
class PrefetchHooks {
  /// This callback is used to add joins to the query before it is executed.
  late final StateTransformer withJoins;

  /// This callback is used to prefetch referenced data and insert it into the TypedResult object.
  late final TypedResultTransformer withPrefetches;

  /// Create a [PrefetchHooks] object
  PrefetchHooks(
      {StateTransformer? addJoins, TypedResultTransformer? withPrefetches}) {
    withJoins = addJoins ?? _defaultStateTransformer;
    this.withPrefetches = withPrefetches ?? (results) async => results;
  }
}

/// This class is used to convert a table which expects a single dataclass per row into a table that can contain a multiple dataclasses per row.
/// However when we prefetch multiple references, we need to store them in a list, which isn't supported by the referenced table class.
/// For single references, we use original referenced table as a key in the TypedResult._parsedData object.
/// {@macro manager_internal_use_only}
class MultiTypedResultKey<$Table extends Table, $Dataclass>
    implements ResultSetImplementation<$Table, $Dataclass> {
  @override
  final List<GeneratedColumn<Object>> $columns;

  @override
  final $Table asDslTable;

  @override
  final DatabaseConnectionUser attachedDatabase;

  @override
  final Map<String, GeneratedColumn<Object>> columnsByName;

  @override
  final String entityName;

  @override
  FutureOr<$Dataclass> map(Map<String, dynamic> data, {String? tablePrefix}) =>
      _mapFunction(data, tablePrefix: tablePrefix);

  final FutureOr<$Dataclass> Function(Map<String, dynamic> data,
      {String? tablePrefix}) _mapFunction;

  @override
  String get aliasedName => entityName;

  @override
  MultiTypedResultKey<$Table, $Dataclass> createAlias(String alias) {
    return MultiTypedResultKey._(
      $columns: $columns,
      asDslTable: asDslTable,
      attachedDatabase: attachedDatabase,
      columnsByName: columnsByName,
      entityName: alias,
      mapFunction: _mapFunction,
    );
  }

  const MultiTypedResultKey._(
      {required this.$columns,
      required this.asDslTable,
      required this.attachedDatabase,
      required this.columnsByName,
      required this.entityName,
      required FutureOr<$Dataclass> Function(Map<String, dynamic>,
              {String? tablePrefix})
          mapFunction})
      : _mapFunction = mapFunction;

  /// Create a [MultiTypedResultKey] from a table
  static MultiTypedResultKey<$Table, List<$Dataclass>>
      fromTable<$Table extends Table, $Dataclass>(
          TableInfo<$Table, $Dataclass> table,
          {required String aliasName}) {
    return MultiTypedResultKey<$Table, List<$Dataclass>>._(
      $columns: table.$columns,
      asDslTable: table.asDslTable,
      attachedDatabase: table.attachedDatabase,
      columnsByName: table.columnsByName,
      entityName: aliasName,

      /// This table is used a key for a map and should never be used to read data
      /// However, in case it is, we will map a single item to a list of items
      mapFunction: (Map<String, dynamic> data, {String? tablePrefix}) {
        final singleResult = table.map(data, tablePrefix: tablePrefix);
        if (singleResult is $Dataclass) {
          return [singleResult];
        } else {
          return singleResult.then(
            (value) => [value],
          );
        }
      },
    );
  }

  /// Only use the entity name as the hashcode
  @override
  int get hashCode => entityName.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is MultiTypedResultKey<$Table, $Dataclass>) {
      return other.entityName == entityName;
    }
    return false;
  }
}

/// This function is used to prefetch referenced data for a list of TypedResults.
/// And then insert the prefetched data into the TypedResult object using the [MultiTypedResultKey] as a key.
Future<List<TypedResult>> typedResultsWithPrefetched<
        $CurrentDataclass,
        $CurrentTable extends Table,
        $ReferencedDataclass,
        $ReferencedTable extends Table>(
    {required bool doPrefetch,
    required ProcessedTableManager<
                dynamic,
                dynamic,
                $ReferencedDataclass,
                dynamic,
                dynamic,
                dynamic,
                dynamic,
                dynamic,
                $ReferencedDataclass,
                dynamic>
            Function(TypedResult)
        managerFromTypedResult,
    required List<TypedResult> typedResults,
    required TableInfo<$CurrentTable, $CurrentDataclass> currentTable,
    required MultiTypedResultKey referencedTable,
    required Iterable<$ReferencedDataclass> Function(
            $CurrentDataclass item, List<$ReferencedDataclass> referencedItems)
        referencedItemsForCurrentItem}) async {
  if (!doPrefetch || typedResults.isEmpty) {
    return typedResults;
  } else {
    final managers = typedResults.map(managerFromTypedResult);
    // Combine all the referenced managers into 1 large query which will return all the
    // referenced items in one go.
    final manager = managers.reduce((value, element) => value._filter(
        (_) => ComposableFilter._(element.$state.filter, {}),
        _BooleanOperator.or));
    final referencedItems = await manager.get(distinct: true);

    // Put each of these referenced items into the typed results
    return typedResults.map((e) {
      final item = e.readTable(currentTable);
      final refs =
          referencedItemsForCurrentItem(item, referencedItems).toList();
      e.addData(referencedTable, refs);
      return e;
    }).toList();
  }
}
