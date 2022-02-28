import 'data_verification.dart';

/// Thrown when one attempts to insert or update invalid data into a table.
class InvalidDataException implements Exception {
  /// A message explaining why the data couldn't be inserted into the database.
  final String message;

  /// All errors that were found in this [InvalidDataException].
  final Map<VerificationMeta, VerificationResult> errors;

  /// Construct a new [InvalidDataException] from the [message].
  InvalidDataException(this.message, [this.errors = const {}]);

  @override
  String toString() {
    return 'InvalidDataException: $message';
  }
}

/// A wrapper class for internal exceptions thrown by the underlying database
/// engine when drift can give additional context or help.
///
/// For instance, when we know that an invalid statement has been constructed,
/// we catch the database exception and try to explain why that has happened.
class DriftWrappedException implements Exception {
  /// Contains a possible description of why the underlying [cause] occurred,
  /// for instance because a drift api was misused.
  final String message;

  /// The underlying exception caught by drift
  final Object? cause;

  /// The original stacktrace when caught by drift
  final StackTrace? trace;

  /// Creates a new [DriftWrappedException] to provide additional details about
  /// an underlying error from the database.
  DriftWrappedException({required this.message, this.cause, this.trace});

  @override
  String toString() {
    return '$cause at \n$trace\n'
        'Drift detected a possible cause for this: $message';
  }
}

/// Exception thrown by drift when rolling back a transaction fails.
///
/// When using a `transaction` block, transactions are automatically rolled back
/// when the inner block throws an exception.
/// If sending the `ROLLBACK TRANSACTION` command fails as well, drift reports
/// both that and the initial error with a [CouldNotRollBackException].
class CouldNotRollBackException implements Exception {
  /// The original exception that caused the transaction to be rolled back.
  final Object cause;

  /// The [StackTrace] of the original [cause].
  final StackTrace originalStackTrace;

  /// The exception thrown by the database implementation when attempting to
  /// issue the `ROLLBACK` command.s
  final Object exception;

  /// Creates a [CouldNotRollBackException] from the [cause], its
  /// [originalStackTrace] and the [exception].
  CouldNotRollBackException(
      this.cause, this.originalStackTrace, this.exception);

  @override
  String toString() {
    return 'CouldNotRollBackException: $exception. \n'
        'For context: The transaction was rolled back because of $cause, which '
        'was thrown here: \n$originalStackTrace';
  }
}
