String asDartLiteral(String value) {
  final escaped = escapeForDart(value);
  return "'$escaped'";
}

String escapeForDart(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\$', '\\\$')
      .replaceAll('\r', '\\r')
      .replaceAll('\n', '\\n');
}
