/// Thrown when one attempts to insert or update invalid data into a table.
class InvalidDataException implements Exception {
  /// A message explaining why the data couldn't be inserted into the database.
  final String message;

  /// Construct a new [InvalidDataException] from the [message].
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
  /// Contains a possible description of why the underlying [cause] occurred,
  /// for instance because a moor api was misused.
  final String message;

  /// The underlying exception caught by moor
  final dynamic cause;

  /// The original stacktrace when caught by moor
  final StackTrace trace;

  /// Creates a new [MoorWrappedException] to provide additional details about
  /// an underlying error from the database.
  MoorWrappedException({this.message, this.cause, this.trace});

  @override
  String toString() {
    return '$cause at \n$trace\nMoor detected a possible cause for this: $message';
  }
}
