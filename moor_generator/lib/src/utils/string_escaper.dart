String asDartLiteral(String value) {
  final escaped = value.replaceAll("'", "\\'").replaceAll('\n', '\\n');
  return "'$escaped'";
}
