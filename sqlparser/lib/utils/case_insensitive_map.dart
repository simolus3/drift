import 'dart:collection';

/// A map from strings to [T] where keys are compared without case sensitivity.
class CaseInsensitiveMap<K extends String?, T> extends MapBase<K, T> {
  final Map<K, T> _normalized = {};

  CaseInsensitiveMap();

  factory CaseInsensitiveMap.of(Map<K, T> other) {
    final map = CaseInsensitiveMap<K, T>();
    other.forEach((key, value) {
      map[key] = value;
    });

    return map;
  }

  @override
  T? operator [](Object? key) {
    if (key is String?) {
      return _normalized[key?.toLowerCase()];
    } else {
      return null;
    }
  }

  @override
  void operator []=(K key, T value) {
    _normalized[key?.toLowerCase() as K] = value;
  }

  @override
  void clear() {
    _normalized.clear();
  }

  @override
  Iterable<K> get keys => _normalized.keys;

  @override
  T? remove(Object? key) {
    if (key is String?) {
      return _normalized.remove(key?.toLowerCase());
    }
    return null;
  }
}
