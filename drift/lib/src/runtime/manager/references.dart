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
///
/// {@macro manager_internal_use_only}
///
/// # Prefetching
///
/// ### Problem
///
/// It's quite common that a user will want a model together with it's relations.
/// The simple option is to prefetch all of the users, and then run a 2nd request for each related group.
/// ```dart
/// final users = await users.withReferences().get()
/// for (final (user,refs) in users){
///   final group = await refs.groups.getSingle();
/// }
/// ```
/// The issue with the above code is that we could be setting ourselves up to do tons of queries.
///
/// ### Solution
///
/// There are two methods we use together to solve this.
/// Joins and Prefetches.
///
/// ##### Join
///
/// For fields which are foreign keys to other tables, we can just use a join to select the related field and get it all in one query
/// There are many examples how to do this in the drift documentation
///
/// ##### Prefetch
///
/// However, for reverse relations, we can't get it all in a single query.
/// We have to run 2 queries. Here is how it's done manually.
///
/// ```dart
/// final groups = await groups.get();
/// final groupIds = groups.map((group)=> group.id);
/// final users = await users.filter((f)=> f.group.id.isIn(groupIds)).get()
/// final groupsWithUsers = groups.map((group)=>(group,users.where((user)=> user.group == group.id)));
/// ```
///
/// We get all the users ahead of time, and then manually return each group with it's users using a `where(...)` filter.
///
/// We will call both of these "prefetch" throughout.
///
///
/// ### Manager API
///
/// This is quite verbose, and the manager api seeks to solve this for you.
/// The API looks like this:
/// ```dart
/// users.withReferences((prefetch) => prefetch(groups: true)).get()
/// ```
///
/// To do this there are a couple of things we need to do.
///
/// For references data we are getting via JOIN
///
/// 1. Before we even run a query with `users.withReferences((prefetch) => prefetch(group: true)).get()`, we need to put add a JOIN to this query.
/// 2. When we read back this result, we need to read the JOINed information back.
///
/// For referenced data we are getting with a prefetch:
///
/// 1. After we get all the results we need to run more queries, map the correct data, and inject it info each object.
///
/// We also have to do difference behavior depending of what was prefetched, so this is a pretty complex issue.
///
/// ### Implementation
///
/// We only need to do 2 things for this to work:
///
/// 1) Reference class
///
/// This class is kinda cool. It holds the original result of the query as a `TypedResult`, which is what drift uses to store the raw query.
/// But along with that, it has getters for prebuilt managers.
/// When `withReferences` is called, we return the dataclass, together with this.
///
/// To keep things simple for now, this is a reference class which has it's prefetching abilities removed
/// ```dart
/// final class $$ProductTableReferences
///     extends BaseReferences<_$TodoDb, $ProductTable, ProductData> {
///   $$ProductTableReferences(super.$_db, super.$_table, super.$_typedResult);
///
///   $$DepartmentTableProcessedTableManager? get department {
///     if ($_item.department == null) return null;
///     return  $$DepartmentTableTableManager($_db, $_db.department)
///         .filter((f) => f.id($_item.department!));
///  }
///
///   $$ListingTableProcessedTableManager get listings {
///     return  $$ListingTableTableManager($_db, $_db.listing)
///         .filter((f) => f.product.id($_item.id));
///   }
/// }
/// ```
/// You can see how this allow us to easily get managers which are configured special for this product.
///
/// However, imagine we added extra data to this `TypedResult` before, we could read it and put it in the new managers cache.
/// This is what the full code looks like for the reference class.
/// Keep in mind this class only reads data, we'll get to the writing soon.
///
///
/// ```dart
///
/// final class $$ProductTableReferences
///    extends BaseReferences<_$TodoDb, $ProductTable, ProductData> {
///  $$ProductTableReferences(super.$_db, super.$_table, super.$_typedResult);
///
///   /// When we do the join we will use this aliased table
///   static $DepartmentTable _departmentTable(_$TodoDb db) =>
///       db.department.createAlias(
///           $_aliasNameGenerator(db.product.department, db.department.id));
///
///   $$DepartmentTableProcessedTableManager? get department {
///     /// If we already know that this product has no department, we will return null
///     if ($_item.department == null) return null;
///     final manager = $$DepartmentTableTableManager($_db, $_db.department)
///         .filter((f) => f.id($_item.department!));
///
///     /// If we already joined the department table, then this will be the department for this product
///     final item = $_typedResult.readTableOrNull(_departmentTable($_db));
///     if (item == null) return manager;
///     return ProcessedTableManager(
///         manager.$state.copyWith(prefetchedData: [item]));
///   }
///   /// This is similar to [_departmentTable] , but fot the listings.
///   /// This is a reverse relation, so we won't be using this to create a joined query.
///   /// But we will still use it to read and write into the `TypedResult` (`TypedResult` is a glorified `Map`, it's key needs to be a certain kind of class [ResultSetImplementation] with a generic, that's all `MultiTypedResultKey` does)
///   static MultiTypedResultKey<$ListingTable, List<ListingData>> _listingsTable(
///           _$TodoDb db) =>
///       MultiTypedResultKey.fromTable(db.listing,
///           aliasName: $_aliasNameGenerator(db.product.id, db.listing.product));
///
///   $$ListingTableProcessedTableManager get listings {
///     final manager = $$ListingTableTableManager($_db, $_db.listing)
///         .filter((f) => f.product.id($_item.id));
///     /// If we have done any prefetches, these listings will be in the typed result
///     /// We will take them out and put them in the new manager
///     final cache = $_typedResult.readTableOrNull(_listingsTable($_db));
///     return ProcessedTableManager(
///         manager.$state.copyWith(prefetchedData: cache));
///   }
/// }
/// ```
/// ### Hooks
/// OK, we can see how we read references, but how does the manager actually fetch these results and add them to the `TypedResult` class?
/// For that we use the `PrefetchedHooks` class and some callbacks.
///
/// So let's start at the beginning.
/// ```
/// products.withReferences((prefetch) => prefetch(listings: true));
/// ```
/// This `prefetch` function is declared on the generated manager and returns a `PrefetchedHooks`.
/// Here is an example so we can walk through this
/// ```
/// prefetchHooksCallback: ({department = false, listings = false}) {
///           return PrefetchHooks(
///             /// This field holds a function which will add the join if the user adds it to the prefetch
///             addJoins: <
///                 /// The generics here are kinda messy,
///                 /// but it's declaring a function that takes a TableManagerState and returns a TableManagerState with some changes.
///                 T extends TableManagerState<
///                     dynamic,
///                     dynamic,
///                     dynamic,
///                     dynamic,
///                     dynamic,
///                     dynamic,
///                     dynamic,
///                     dynamic,
///                     dynamic,
///                     dynamic>>(state) {
///               /// If the user did `prefetch(department: true)` then a join will be added to the query
///               if (department) {
///                 state = state.withJoin(
///                   currentTable: table,
///                   currentColumn: table.department,
///                   // This `$$ProductTableReferences._departmentTable(db)` was declared above. It's an aliased copy of the department table.
///                   referencedTable:
///                       $$ProductTableReferences._departmentTable(db),
///                   referencedColumn:
///                       $$ProductTableReferences._departmentTable(db).id,
///                 ) as T;
///               }
///
///               /// Listings aren't going to use a join, so we will skip it here, and instead to it later
///
///               return state;
///             },
///             /// This callback takes care of doing the additional queries needed to get reverse referenced data.
///             /// `items` is the products as a list of `TypedResult`, this function will add referenced data to these `TypedResult` using the above created
///             /// MultiTypedResultKey as keys.
///             withPrefetches: (items) async {
///
///               /// If `listings` is true, this function will do the hard work we mentioned above, but under the scenes
///               /// It will:
///               ///  1) Create a query of ALL the listings for ALL of the products / `items`
///               ///  2) Use a map filter to get the correct listings for each individual item (referencedItemsForCurrentItem)
///               ///  3) Add it the the `TypedResult` object.
///               items = await typedResultsWithPrefetched(
///                   doPrefetch: listings,
///                   currentTable: table,
///                   referencedTable:
///                       $$ProductTableReferences._listingsTable(db),
///                   managerFromTypedResult: (p0) =>
///                       $$ProductTableReferences(db, table, p0).listings,
///                   referencedItemsForCurrentItem: (item, referencedItems) =>
///                       referencedItems.where((e) => e.product == item.id),
///                   typedResults: items);
///               return items;
///             },
///           );
///         },
/// ```
///
/// So once we run `withReferences`, we now have a `PrefetchHooks` class in the manager which will run these callbacks, thereby filling `TypedResult` with the
/// data we need. So now when we run
/// ```dart
///   $$ListingTableProcessedTableManager get listings {
///     final manager = $$ListingTableTableManager($_db, $_db.listing)
///         .filter((f) => f.product.id($_item.id));
///     /// If we have done any prefetches, these listings will be in the typed result
///     /// We will take them out and put them in the new manager
///     final cache = $_typedResult.readTableOrNull(_listingsTable($_db));
///     return ProcessedTableManager(
///         manager.$state.copyWith(prefetchedData: cache));
///   }
/// }
/// ```
/// from above, we will get a manager that has prefetchedData included.
///
/// {@macro manager_internal_use_only}
base class BaseReferences<$Database extends GeneratedDatabase,
    $Table extends Table, $Dataclass> {
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
///
/// Here is an example.
/// Let's say we wanted to get all the groups, with their users.
/// We need to:
///   1) Then run a 2nd query to get all the users who are in the groups. (Users who are'nt any groups will be ignored)
///   2) Add the users from the group into the groups `TypedResult`
///   3) Return the groups with the listings
///
/// Manually this would look like:
///
/// ```dart
/// final groups = await groups.get();
/// final groupIds = groups.map((group)=> group.id);
/// final users = await users.filter((f)=> f.group.id.isIn(groupIds)).get()
/// final groupsWithUsers = groups.map((group)=>(group,users.where((user)=> user.group == group.id)));
/// ```
///
///
/// Arguments:
///   - [typedResults] is the raw result of the query, together with [currentTable] we can read it's results
///   - [doPrefetch] is a bool which will only perform the prefetch if true.
///   - [managerFromTypedResult] is the equivalent of:
///     ```dart
///     final groups = await groups.withReferences().get();
///     for (final (group, refs) in groups){
///         /// Manager with a filter to only get the users of this group.
///         refs.users;
///     }
///     ```
///     What we do, is collect all the filters from all of these `refs.users` and
///     combine them with an OR operator to create a query which gets all the users
///     [managerFromTypedResult] is the function which turns a single `group` into `refs.users`
///   - [referencedTable] is a `MultiTypedResultKey` which is to write the results to the `TypedResult` object,
///     This same class will be used in the `BaseReferences` class to read from the `TypedResult`.
///   - [referencedItemsForCurrentItem] is the callback which does the mapping.
///     It is the equivalent of`users.where((user)=> user.group == group.id)`.
///
/// This function is used by the generated code and should not be used directly.
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
