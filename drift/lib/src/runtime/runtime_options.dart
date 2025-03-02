import 'package:drift/drift.dart';

/// Defines additional runtime behavior for drift. Changing the fields of this
/// class is rarely necessary.
class DriftRuntimeOptions {
  /// Don't warn when a database class isn't used as singleton.
  bool dontWarnAboutMultipleDatabases = false;

  /// The [ValueSerializer] that will be used by default in [LegacyDataClass.toJson].
  ValueSerializer defaultSerializer = const ValueSerializer.defaults();

  /// The function used by drift to emit debug prints.
  ///
  /// This is the function used with `logStatements: true` on databases and
  /// `debugLog` on isolates.
  void Function(String) debugPrint = (text) =>
      RegExp('.{1,300}').allMatches(text).map((m) => m.group(0)).forEach(print);
}

/// Stores the [DriftRuntimeOptions] describing global drift behavior across
/// databases.
///
/// Note that is is adapting this behavior is rarely needed.
DriftRuntimeOptions driftRuntimeOptions = DriftRuntimeOptions();
