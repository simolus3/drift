import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

typedef SelectableProvider<T> = ProviderListenable<AsyncValue<T>>;

SelectableProvider<List<T>> queryProviderImpl<T>(
    Selectable<T> Function(Ref) create,
    {String? name}) {
  return StreamProvider.autoDispose(name: name, (ref) {
    return create(ref).watch();
  });
}

SelectableProvider<T?> queryProviderImplSingleOrNull<T>(
    Selectable<T> Function(Ref) create,
    {String? name}) {
  return StreamProvider.autoDispose(name: name, (ref) {
    return create(ref).watchSingleOrNull();
  });
}

// ignore: subtype_of_sealed_class
abstract base class SelectableProviderFamily<T, Arg>
    extends Family<AsyncValue<List<T>>> {
  @override
  final String name;
  final ProviderOrFamily _database;
  final Selectable<T> Function(Ref, Arg) _create;

  SelectableProviderFamily(
      {required String $name,
      required ProviderOrFamily $database,
      required Selectable<T> Function(Ref, Arg) $create})
      : name = $name,
        _database = $database,
        _create = $create;

  @override
  Iterable<ProviderOrFamily> get allTransitiveDependencies =>
      [_database, ...?_database.allTransitiveDependencies];

  @override
  Iterable<ProviderOrFamily> get dependencies => [_database];

  @override
  ProviderBase<AsyncValue<List<T>>> getProviderOverride(
      // ignore: library_private_types_in_public_api
      covariant _SelectableProvider<T, Arg> provider) {
    return create(provider._arg);
  }

  @protected
  ProviderBase<AsyncValue<List<T>>> create(Arg args) {
    return _SelectableProvider(_create, args, name: name);
  }
}

// ignore: subtype_of_sealed_class
abstract base class SelectableSingleProviderFamily<T, Arg>
    extends Family<AsyncValue<T?>> {
  @override
  final String name;
  final ProviderOrFamily _database;
  final Selectable<T> Function(Ref, Arg) _create;

  SelectableSingleProviderFamily(
      {required String $name,
      required ProviderOrFamily $database,
      required Selectable<T> Function(Ref, Arg) $create})
      : name = $name,
        _database = $database,
        _create = $create;

  @override
  Iterable<ProviderOrFamily> get allTransitiveDependencies =>
      [_database, ...?_database.allTransitiveDependencies];

  @override
  Iterable<ProviderOrFamily> get dependencies => [_database];

  @override
  ProviderBase<AsyncValue<T?>> getProviderOverride(
      // ignore: library_private_types_in_public_api
      covariant _SelectableSingleOrNullProvider<T, Arg> provider) {
    return create(provider._arg);
  }

  @protected
  ProviderBase<AsyncValue<T?>> create(Arg args) {
    return _SelectableSingleOrNullProvider(_create, args, name: name);
  }
}

// ignore: subtype_of_sealed_class
final class _SelectableProvider<T, Arg>
    extends AutoDisposeStreamProvider<List<T>> {
  final Arg _arg;

  _SelectableProvider(Selectable<T> Function(Ref, Arg) create, this._arg,
      {super.name})
      : super((ref) {
          return create(ref, _arg).watch();
        });
}

// ignore: subtype_of_sealed_class
final class _SelectableSingleOrNullProvider<T, Arg>
    extends AutoDisposeStreamProvider<T?> {
  final Arg _arg;

  _SelectableSingleOrNullProvider(
      Selectable<T> Function(Ref, Arg) create, this._arg,
      {super.name})
      : super((ref) {
          return create(ref, _arg).watchSingleOrNull();
        });
}
