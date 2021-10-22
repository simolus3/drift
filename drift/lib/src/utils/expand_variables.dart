/// Used by generated code.
String $expandVar(int start, int amount) {
  final buffer = StringBuffer();

  for (var x = 0; x < amount; x++) {
    buffer.write('@${start + x}');
    if (x != amount - 1) {
      buffer.write(', ');
    }
  }

  return buffer.toString();
}
