/// Mixin for types that can have arbitrary metadata on them.
mixin HasMetaMixin {
  final Map<Type, dynamic> _metadata = {};

  /// Returns the metadata of type [T] that might have been set on this node, or
  /// null if none was found.
  /// Nodes can have arbitrary annotations on them set via [setMeta] and
  /// obtained via [meta]. This mechanism is used to, for instance, attach
  /// variable scopes to a subtree.
  T meta<T>() {
    return _metadata[T] as T;
  }

  /// Sets the metadata of type [T] to the specified [value].
  /// Nodes can have arbitrary annotations on them set via [setMeta] and
  /// obtained via [meta]. This mechanism is used to, for instance, attach
  /// variable scopes to a subtree.
  void setMeta<T>(T value) {
    _metadata[T] = value;
  }
}
