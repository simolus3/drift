import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';

typedef SelectableProvider<T> = ProviderListenable<AsyncValue<T>>;
typedef SelectableProviderFamily<T, Arg>
    = AutoDisposeStreamProviderFamily<T, Arg>;

SelectableProvider<List<T>> queryProviderImpl<T>(
    Selectable<T> Function(Ref) create) {
  return StreamProvider.autoDispose((ref) {
    return create(ref).watch();
  });
}

SelectableProviderFamily<List<T>, Args> queryProviderFamilyImpl<T, Args>(
    Selectable<T> Function(Ref, Args) create) {
  return StreamProvider.autoDispose.family((ref, arg) {
    return create(ref, arg).watch();
  });
}
