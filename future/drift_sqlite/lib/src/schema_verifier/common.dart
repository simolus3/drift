import 'package:meta/meta.dart';

import 'find_differences.dart';

/// Options that control how schemas are compared to find mismatches.
final class ValidationOptions {
  /// When enabled (defaults to `false`), validate that no furhter tables,
  /// triggers or views apart from those expected exist.
  final bool validateDropped;

  /// When enabled (defualts to `true`), validate column constraints.
  ///
  /// When disabled, schema verification passes even without
  final bool validateColumnConstraints;

  /// @nodoc
  const ValidationOptions({
    this.validateDropped = false,
    this.validateColumnConstraints = true,
  });
}

@internal
void verify({
  required SyntacticSchema referenceSchema,
  required SyntacticSchema actualSchema,
  required ValidationOptions options,
}) {
  final result = actualSchema.compareTo(
    expected: referenceSchema,
    options: options,
  );

  if (!result.areEqual) {
    throw SchemaMismatch(result.describe());
  }
}

/// Thrown when the actual schema differs from the expected schema.
final class SchemaMismatch implements Exception {
  /// A message listing schema differences in a human-readable format.
  final String explanation;

  /// @nodoc
  SchemaMismatch(this.explanation);

  @override
  String toString() {
    return 'Schema does not match\n$explanation';
  }
}
