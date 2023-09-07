/// Provides [withoutPrefix], a method useful to interpret SQL results.
extension RemovePrefix on Map<String, Object?> {
  /// Returns a map of all keys starting with the table prefix, but with the
  /// prefix removed.
  Map<String, Object?> withoutPrefix(String? tablePrefix) {
    if (tablePrefix != null) {
      final actualPrefix = '$tablePrefix.';
      final prefixLength = actualPrefix.length;

      return {
        for (final MapEntry(:key, :value) in entries)
          if (key.startsWith(actualPrefix)) key.substring(prefixLength): value,
      };
    } else {
      return this;
    }
  }
}
