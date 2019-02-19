/// Thrown when one attempts to insert or update invalid data into a table.
class InvalidDataException implements Exception {
  final String message;

  InvalidDataException(this.message);
}
