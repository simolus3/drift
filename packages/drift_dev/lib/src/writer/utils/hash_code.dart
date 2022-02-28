class HashCodeWriter {
  static const int _maxArgsToObjectHash = 20;

  const HashCodeWriter();

  /// Writes an expression to calculate a hash code of an object that consists
  /// of the [fields].
  void writeHashCode(List<String> fields, StringBuffer into) {
    if (fields.isEmpty) {
      into.write('identityHashCode(this)');
    } else if (fields.length == 1) {
      into.write('${fields[0]}.hashCode');
    } else {
      final needsHashAll = fields.length > _maxArgsToObjectHash;

      into.write(needsHashAll ? 'Object.hashAll([' : 'Object.hash(');
      var first = true;
      for (final field in fields) {
        if (!first) into.write(', ');

        into.write(field);
        first = false;
      }

      into.write(needsHashAll ? '])' : ')');
    }
  }
}
