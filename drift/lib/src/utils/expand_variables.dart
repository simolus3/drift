/// Used by generated code.
String $expandVar(int start, int amount, [bool compatibleMode = false]) {
  final buffer = StringBuffer();
  final mark = compatibleMode ? '@' : '?';

  for (var x = 0; x < amount; x++) {
    buffer.write('$mark${start + x}');
    if (x != amount - 1) {
      buffer.write(', ');
    }
  }

  return buffer.toString();
}
