import 'package:drift/drift.dart';

/// Provides additional options to [regexp] that are only available when using
/// SQLite.
extension SqliteSpecificStringOperators on Expression<String> {
  /// Matches this string against the regular expression in [regex].
  ///
  /// The [multiLine], [caseSensitive], [unicode] and [dotAll] parameters
  /// correspond to the parameters on [RegExp].
  ///
  /// Note that this function is only available when using a `NativeDatabase`.
  /// If you need to support the web or `moor_flutter`, consider using [like]
  /// instead.
  Expression<bool> regexp(
    String regex, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) {
    // We have a special regexp sql function that takes a third parameter
    // to encode flags. If the least significant bit is set, multiLine is
    // enabled. The next three bits enable case INSENSITIVITY (it's sensitive
    // by default), unicode and dotAll.
    var flags = 0;

    if (multiLine) {
      flags |= 1;
    }
    if (!caseSensitive) {
      flags |= 2;
    }
    if (unicode) {
      flags |= 4;
    }
    if (dotAll) {
      flags |= 8;
    }

    if (flags != 0) {
      return FunctionCallExpression<bool>(
        'regexp_drift',
        [
          Variable.withString(regex),
          this,
          Variable.withInt(flags),
        ],
      );
    }

    // No special flags enabled, use the regular REGEXP operator
    return BinaryExpression(
        this, BinaryOperator.regexp, Variable.withString(regex));
  }
}
