/// Superclass for all exceptions thrown by drift.
///
/// Note that drift also throws [Error] instances in case of API misuse.
sealed class DriftException implements Exception {}

/// Exception thrown by drift when rolling back a transaction fails.
///
/// When using a `transaction` block, transactions are automatically rolled back
/// when the inner block throws an exception.
/// If sending the `ROLLBACK TRANSACTION` command fails as well, drift reports
/// both that and the initial error with a [CouldNotRollBackException].
class CouldNotRollBackException implements DriftException {
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
    this.cause,
    this.originalStackTrace,
    this.exception,
  );

  @override
  String toString() {
    return 'CouldNotRollBackException: $exception. \n'
        'For context: The transaction was rolled back because of $cause, which '
        'was thrown here: \n$originalStackTrace';
  }
}
