const _hashCombine = '\$mrjc';
const _hashFinish = '\$mrjf';

class HashCodeWriter {
  /// Writes an expression to calculate a hash code of an object that consists
  /// of the [fields].
  void writeHashCode(List<String> fields, StringBuffer into) {
    if (fields.isEmpty) {
      into.write('identityHashCode(this)');
    } else if (fields.length == 1) {
      into.write('$_hashFinish(${fields.last}.hashCode)');
    } else {
      into.write('$_hashFinish(');
      _writeInner(fields, into, 0);
      into.write(')');
    }
  }

  /// recursively writes a "combine(a, combine(b, c)))" expression
  void _writeInner(List<String> fields, StringBuffer into, int index) {
    if (index == fields.length - 1) {
      into.write('${fields.last}.hashCode');
    } else {
      into.write('$_hashCombine(${fields[index]}.hashCode, ');
      _writeInner(fields, into, index + 1);
      into.write(')');
    }
  }
}
