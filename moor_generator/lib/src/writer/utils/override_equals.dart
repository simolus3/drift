//@dart=2.9
/// Writes a operator == override for a class consisting of the [fields] into
/// the buffer provided by [into].
void overrideEquals(
    Iterable<String> fields, String className, StringBuffer into) {
  into
    ..write('@override\nbool operator ==(dynamic other) => ')
    ..write('identical(this, other) || (other is $className');

  if (fields.isNotEmpty) {
    into
      ..write(' && ')
      ..write(fields.map((field) {
        return 'other.$field == this.$field';
      }).join(' && '));
  }

  into.write(');\n');
}
