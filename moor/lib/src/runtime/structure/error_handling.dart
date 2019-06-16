import 'package:moor/moor.dart';

/// Additional information that is passed to [GeneratedColumn]s when verifying
/// data to provide more helpful error messages.
class VerificationMeta {
  /// The dart getter name of the property being validated.
  final String dartGetterName;

  const VerificationMeta(this.dartGetterName);
}

/// Returned by [GeneratedColumn.isAcceptableValue] to provide a description
/// when a valid is invalid.
class VerificationResult {
  final bool success;
  final String message;

  const VerificationResult(this.success, this.message);
  const VerificationResult.success()
      : success = true,
        message = null;
  const VerificationResult.failure(this.message) : success = false;
}

class VerificationContext {
  final Map<VerificationMeta, VerificationResult> _errors = {};

  bool get dataValid => _errors.isEmpty;

  void handle(VerificationMeta meta, VerificationResult result) {
    if (!result.success) {
      _errors[meta] = result;
    }
  }

  void throwIfInvalid(dynamic dataObject) {
    if (dataValid) return;

    final messageBuilder =
        StringBuffer('Sorry, $dataObject cannot be used for that because: \n');

    _errors.forEach((meta, result) {
      messageBuilder.write('• ${meta.dartGetterName}: ${result.message}\n');
    });

    throw InvalidDataException(messageBuilder.toString());
  }
}
