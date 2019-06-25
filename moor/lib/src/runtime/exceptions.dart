/// Thrown when one attempts to insert or update invalid data into a table.
class InvalidDataException implements Exception {
  final String message;

  InvalidDataException(this.message);

  @override
  String toString() {
    return 'InvalidDataException: $message';
  }
}

/// A wrapper class for internal exceptions thrown by the underlying database
/// engine when moor can give additional context or help.
///
/// For instance, when we know that an invalid statement has been constructed,
/// we catch the database exception and try to explain why that has happened.
class MoorWrappedException implements Exception {
  final String message;
  final dynamic cause;
  final StackTrace trace;

  MoorWrappedException({this.message, this.cause, this.trace});

  @override
  String toString() {
    return '$cause at \n$trace\nMoor detected a possible cause for this: $message';
  }
}
