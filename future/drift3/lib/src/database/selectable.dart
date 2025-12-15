import 'dart:async';

import '../utils/async_map.dart';
import '../utils/single_transformer.dart';

/// [Selectable] methods for returning multiple results.
///
/// Useful for refining the return type of a query, while still delegating
/// whether to [get] or [watch] results to the consuming code.
///
/// {@template drift_multi_selectable_example}
/// ```dart
/// /// Retrieve a page of [Todo]s.
/// MultiSelectable<Todo> pageOfTodos(int page, {int pageSize = 10}) {
///   return select(todos)..limit(pageSize, offset: page);
/// }
/// pageOfTodos(1).get();
/// pageOfTodos(1).watch();
/// ```
/// {@endtemplate}
///
/// See also: [SingleSelectable] and [SingleOrNullSelectable] for exposing
/// single value methods.
abstract interface class MultiSelectable<T> {
  /// Executes this statement and returns the result.
  Future<List<T>> get();

  /// Creates an auto-updating stream of the result that emits new items
  /// whenever any table used in this statement changes.
  Stream<List<T>> watch();
}

/// [Selectable] methods for returning or streaming single,
/// non-nullable results.
///
/// Useful for refining the return type of a query, while still delegating
/// whether to [getSingle] or [watchSingle] results to the consuming code.
///
/// {@template drift_single_selectable_example}
/// ```dart
/// // Retrieve a todo known to exist.
/// SingleSelectable<Todo> entryById(int id) {
///   return select(todos)..where((t) => t.id.equals(id));
/// }
/// final idGuaranteedToExist = 10;
/// entryById(idGuaranteedToExist).getSingle();
/// entryById(idGuaranteedToExist).watchSingle();
/// ```
/// {@endtemplate}
///
/// See also: [MultiSelectable] for exposing multi-value methods and
/// [SingleOrNullSelectable] for exposing nullable value methods.
abstract interface class SingleSelectable<T> {
  /// Executes this statement, like [Selectable.get], but only returns one
  /// value. the query returns no or too many rows, the returned future will
  /// complete with an error.
  ///
  /// {@template drift_single_query_expl}
  /// Be aware that this operation won't put a limit clause on this statement,
  /// if that's needed you would have to do use [SimpleSelectStatement.limit]:
  /// ```dart
  /// Future<TodoEntry> loadMostImportant() {
  ///   return (select(todos)
  ///    ..orderBy([(t) =>
  ///       OrderingTerm(expression: t.priority, mode: OrderingMode.desc)])
  ///    ..limit(1)
  ///   ).getSingle();
  /// }
  /// ```
  /// You should only use this method if you know the query won't have more than
  /// one row, for instance because you used `limit(1)` or you know the `where`
  /// clause will only allow one row.
  /// {@endtemplate}
  ///
  /// See also: [Selectable.getSingleOrNull], which returns `null` instead of
  /// throwing if the query completes with no rows.
  Future<T> getSingle();

  /// Creates an auto-updating stream of this statement, similar to
  /// [Selectable.watch]. However, it is assumed that the query will only emit
  /// one result, so instead of returning a `Stream<List<T>>`, this returns a
  /// `Stream<T>`. If, at any point, the query emits no or more than one rows,
  /// an error will be added to the stream instead.
  ///
  /// {@macro drift_single_query_expl}
  Stream<T> watchSingle();
}

/// [Selectable] methods for returning or streaming single,
/// nullable results.
///
/// Useful for refining the return type of a query, while still delegating
/// whether to [getSingleOrNull] or [watchSingleOrNull] result to the
/// consuming code.
///
/// {@template drift_single_or_null_selectable_example}
///```dart
/// // Retrieve a todo from an external link that may not be valid.
/// SingleOrNullSelectable<Todo> entryFromExternalLink(int id) {
///   return select(todos)..where((t) => t.id.equals(id));
/// }
/// final idFromEmailLink = 100;
/// entryFromExternalLink(idFromEmailLink).getSingleOrNull();
/// entryFromExternalLink(idFromEmailLink).watchSingleOrNull();
/// ```
/// {@endtemplate}
///
/// See also: [MultiSelectable] for exposing multi-value methods and
/// [SingleSelectable] for exposing non-nullable value methods.
abstract interface class SingleOrNullSelectable<T> {
  /// Executes this statement, like [Selectable.get], but only returns one
  /// value. If the result too many values, this method will throw. If no
  /// row is returned, `null` will be returned instead.
  ///
  /// {@macro drift_single_query_expl}
  ///
  /// See also: [Selectable.getSingle], which can be used if the query will
  /// always evaluate to exactly one row.
  Future<T?> getSingleOrNull();

  /// Creates an auto-updating stream of this statement, similar to
  /// [Selectable.watch]. However, it is assumed that the query will only
  /// emit one result, so instead of returning a `Stream<List<T>>`, this
  /// returns a `Stream<T?>`. If the query emits more than one row at
  /// some point, an error will be emitted to the stream instead.
  /// If the query emits zero rows at some point, `null` will be added
  /// to the stream instead.
  ///
  /// {@macro drift_single_query_expl}
  Stream<T?> watchSingleOrNull();
}

/// Abstract class for queries which can return one-time values or a stream
/// of values.
///
/// If you want to make your query consumable as either a [Future] or a
/// [Stream], you can refine your return type using one of Selectable's
/// base classes:
///
/// {@macro drift_multi_selectable_example}
/// {@macro drift_single_selectable_example}
/// {@macro drift_single_or_null_selectable_example}
abstract mixin class Selectable<T>
    implements
        MultiSelectable<T>,
        SingleSelectable<T>,
        SingleOrNullSelectable<T> {
  @override
  Future<List<T>> get();

  @override
  Stream<List<T>> watch();

  @override
  Future<T> getSingle() async {
    return (await get()).single;
  }

  @override
  Stream<T> watchSingle() {
    return watch().transform(singleElements());
  }

  @override
  Future<T?> getSingleOrNull() async {
    final list = await get();
    if (list.isEmpty) {
      return null;
    } else {
      return list.single;
    }
  }

  @override
  Stream<T?> watchSingleOrNull() {
    return watch().transform(singleElementsOrNull());
  }

  /// Maps this selectable by the [mapper] function.
  ///
  /// Each entry emitted by this [Selectable] will be transformed by the
  /// [mapper] and then emitted to the selectable returned.
  Selectable<N> map<N>(N Function(T) mapper) {
    return _MappedSelectable<T, N>(this, mapper);
  }

  /// Maps this selectable by the [mapper] function.
  ///
  /// Like [map] just async.
  Selectable<N> asyncMap<N>(FutureOr<N> Function(T) mapper) {
    return _AsyncMappedSelectable<T, N>(this, mapper);
  }
}

class _MappedSelectable<S, T> extends Selectable<T> {
  final Selectable<S> _source;
  final T Function(S) _mapper;

  _MappedSelectable(this._source, this._mapper);

  @override
  Future<List<T>> get() {
    return _source.get().then(_mapResults);
  }

  @override
  Stream<List<T>> watch() {
    return _source.watch().map(_mapResults);
  }

  List<T> _mapResults(List<S> results) => results.map(_mapper).toList();
}

class _AsyncMappedSelectable<S, T> extends Selectable<T> {
  final Selectable<S> _source;
  final FutureOr<T> Function(S) _mapper;

  _AsyncMappedSelectable(this._source, this._mapper);

  @override
  Future<List<T>> get() {
    return _source.get().then(_mapResults);
  }

  @override
  Stream<List<T>> watch() {
    return AsyncMapPerSubscription(
      _source.watch(),
    ).asyncMapPerSubscription(_mapResults);
  }

  Future<List<T>> _mapResults(List<S> results) async {
    return [for (final result in results) await _mapper(result)];
  }
}
