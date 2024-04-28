@moorDeprecated
library moor;

import 'package:drift/drift.dart';

import 'src/deprecated.dart';

export 'package:drift/drift.dart'
    hide
        GroupByBuilder,
        DriftRuntimeOptions,
        driftRuntimeOptions,
        DriftDatabase,
        DriftAccessor,
        DriftWrappedException,
        JoinBuilder,
        Queryset,
        ComposableOrdering,
        OrderingBuilder,
        Composer,
        BaseTableManager;

/// Use this class as an annotation to inform moor_generator that a database
/// class should be generated using the specified [DriftDatabase.tables].
///
/// To write a database class, first annotate an empty class with
/// [DriftDatabase] and run the build runner using
/// `dart pub run build_runner build`.
/// Moor will have generated a class that has the same name as your database
/// class, but with `_$` as a prefix. You can now extend that class and provide
/// a [QueryExecutor] to use moor:
/// ```dart
/// class MyDatabase extends _$MyDatabase { // _$MyDatabase was generated
///   MyDatabase():
///     super(FlutterQueryExecutor.inDatabaseFolder(path: 'path.db'));
/// }
/// ```
@pragma('moor2drift', 'DriftDatabase')
@moorDeprecated
typedef UseMoor = DriftDatabase;

/// Annotation to use on classes that implement [DatabaseAccessor]. It specifies
/// which tables should be made available in this dao.
///
/// To write a dao, you'll first have to write a database class. See
/// [DriftDatabase] for instructions on how to do that. Then, create an empty
/// class that is annotated with [DriftAccessor] and extends [DatabaseAccessor].
/// For instance, if you have a class called `MyDatabase`, this could look like
/// this:
/// ```dart
/// @DriftAccessor()
/// class MyDao extends DatabaseAccessor<MyDatabase> {
///   MyDao(MyDatabase db) : super(db);
/// }
/// ```
/// After having run the build step once more, moor will have generated a mixin
/// called `_$MyDaoMixin`. Change your class definition to
/// `class MyDao extends DatabaseAccessor<MyDatabase> with _$MyDaoMixin` and
/// you're ready to make queries inside your dao. You can obtain an instance of
/// that dao by using the getter that will be generated inside your database
/// class.
///
/// See also:
/// - https://drift.simonbinder.eu/daos/
@pragma('moor2drift', 'DriftAccessor')
@moorDeprecated
typedef UseDao = DriftAccessor;

/// A wrapper class for internal exceptions thrown by the underlying database
/// engine when moor can give additional context or help.
///
/// For instance, when we know that an invalid statement has been constructed,
/// we catch the database exception and try to explain why that has happened.
@pragma('moor2drift', 'DriftWrappedException')
@moorDeprecated
typedef MoorWrappedException = DriftWrappedException;

/// Defines additional runtime behavior for moor. Changing the fields of this
/// class is rarely necessary.
@pragma('moor2drift', 'DriftRuntimeOptions')
@moorDeprecated
typedef MoorRuntimeOptions = DriftRuntimeOptions;

/// Stores the [MoorRuntimeOptions] describing global moor behavior across
/// databases.
///
/// Note that is is adapting this behavior is rarely needed.
@pragma('moor2drift', 'driftRuntimeOptions')
@moorDeprecated
MoorRuntimeOptions get moorRuntimeOptions => driftRuntimeOptions;

@pragma('moor2drift', 'driftRuntimeOptions')
@moorDeprecated
set moorRuntimeOptions(MoorRuntimeOptions o) => driftRuntimeOptions = o;

/// For use by generated code in calculating hash codes. Do not use directly.
int $mrjc(int hash, int value) {
  // Jenkins hash "combine".
  hash = 0x1fffffff & (hash + value);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

/// For use by generated code in calculating hash codes. Do not use directly.
int $mrjf(int hash) {
  // Jenkins hash "finish".
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}
