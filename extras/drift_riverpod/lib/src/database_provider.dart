import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';

final class DriftNotifier<T extends GeneratedDatabase> extends Notifier<T> {
  final T Function(Ref) _create;

  DriftNotifier._(this._create);

  void _closeCurrent() {
    state.close();
  }

  @override
  T build() {
    ref.onDispose(_closeCurrent);
    return _create(ref);
  }

  void replace(T database) {
    _closeCurrent();
    state = database;
  }
}

extension type DriftProvider<T extends GeneratedDatabase>._(
        NotifierProvider<DriftNotifier<T>, T> _)
    implements NotifierProvider<DriftNotifier<T>, T> {
  factory DriftProvider(T Function(Ref ref) create) {
    return DriftProvider._(NotifierProvider(() {
      return DriftNotifier._(create);
    }));
  }
}
