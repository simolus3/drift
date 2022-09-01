const int _maxArgsToObjectHash = 20;

class EqualityField {
  /// The Dart expression evaluating the field to include in the hash / equals
  /// check.
  final String lexeme;

  /// Whether the field is a list that can't be compared with `==` directly.
  final bool isList;

  EqualityField(this.lexeme, {this.isList = false});
}

/// Writes an expression to calculate a hash code of an object that consists
/// of the [fields].
void writeHashCode(List<EqualityField> fields, StringBuffer into) {
  if (fields.isEmpty) {
    into.write('identityHashCode(this)');
  } else if (fields.length == 1) {
    final field = fields[0];

    if (field.isList) {
      into.write('\$driftBlobEquality.hash(${field.lexeme})');
    } else {
      into.write('${field.lexeme}.hashCode');
    }
  } else {
    final needsHashAll = fields.length > _maxArgsToObjectHash;

    into.write(needsHashAll ? 'Object.hashAll([' : 'Object.hash(');
    var first = true;
    for (final field in fields) {
      if (!first) into.write(', ');

      if (field.isList) {
        into.write('\$driftBlobEquality.hash(${field.lexeme})');
      } else {
        into.write(field.lexeme);
      }

      first = false;
    }

    into.write(needsHashAll ? '])' : ')');
  }
}

/// Writes a operator == override for a class consisting of the [fields] into
/// the buffer provided by [into].
void overrideEquals(
    Iterable<EqualityField> fields, String className, StringBuffer into) {
  into
    ..writeln('@override')
    ..write('bool operator ==(Object other) => ')
    ..write('identical(this, other) || (other is $className');

  if (fields.isNotEmpty) {
    into
      ..write(' && ')
      ..write(fields.map((field) {
        final lexeme = field.lexeme;

        if (field.isList) {
          return '\$driftBlobEquality.equals(other.$lexeme, this.$lexeme)';
        } else {
          return 'other.$lexeme == this.$lexeme';
        }
      }).join(' && '));
  }

  into.writeln(');');
}
