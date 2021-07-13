part of '../query_builder.dart';

/// Defines methods that operate on a column storing [String] values.
extension StringExpressionOperators on Expression<String?> {
  /// Whether this column matches the given pattern. For details on what patters
  /// are valid and how they are interpreted, check out
  /// [this tutorial](http://www.sqlitetutorial.net/sqlite-like/).
  Expression<bool?> like(String regex) {
    return _LikeOperator(this, Variable.withString(regex));
  }

  /// Matches this string against the regular expression in [regex].
  ///
  /// The [multiLine], [caseSensitive], [unicode] and [dotAll] parameters
  /// correspond to the parameters on [RegExp].
  ///
  /// Note that this function is only available when using `moor_ffi`. If you
  /// need to support the web or `moor_flutter`, consider using [like] instead.
  Expression<bool?> regexp(
    String regex, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) {
    // moor_ffi has a special regexp sql function that takes a third parameter
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
        'regexp_moor_ffi',
        [
          Variable.withString(regex),
          this,
          Variable.withInt(flags),
        ],
      );
    }

    // No special flags enabled, use the regular REGEXP operator
    return _LikeOperator(this, Variable.withString(regex), operator: 'REGEXP');
  }

  /// Whether this expression contains [substring].
  ///
  /// Note that this is case-insensitive for the English alphabet only.
  ///
  /// This is equivalent to calling [like] with `%<substring>%`.
  Expression<bool?> contains(String substring) {
    return like('%$substring%');
  }

  /// Uses the given [collate] sequence when comparing this column to other
  /// values.
  Expression<String> collate(Collate collate) {
    return _CollateOperator(this, collate);
  }

  /// Performs a string concatenation in sql by appending [other] to `this`.
  Expression<String> operator +(Expression<String?> other) {
    return _BaseInfixOperator(this, '||', other,
        precedence: Precedence.stringConcatenation);
  }

  /// Calls the sqlite function `UPPER` on `this` string. Please note that, in
  /// most sqlite installations, this only affects ascii chars.
  ///
  /// See also:
  ///  - https://www.w3resource.com/sqlite/core-functions-upper.php
  Expression<String> upper() {
    return FunctionCallExpression('UPPER', [this]);
  }

  /// Calls the sqlite function `LOWER` on `this` string. Please note that, in
  /// most sqlite installations, this only affects ascii chars.
  ///
  /// See also:
  ///  - https://www.w3resource.com/sqlite/core-functions-lower.php
  Expression<String> lower() {
    return FunctionCallExpression('LOWER', [this]);
  }

  /// Calls the sqlite function `LENGTH` on `this` string, which counts the
  /// number of characters in this string. Note that, in most sqlite
  /// installations, [length] may not support all unicode rules.
  ///
  /// See also:
  ///  - https://www.w3resource.com/sqlite/core-functions-length.php
  Expression<int?> get length {
    return FunctionCallExpression('LENGTH', [this]);
  }

  /// Removes spaces from both ends of this string.
  Expression<String?> trim() {
    return FunctionCallExpression('TRIM', [this]);
  }

  /// Removes spaces from the beginning of this string.
  Expression<String?> trimLeft() {
    return FunctionCallExpression('LTRIM', [this]);
  }

  /// Removes spaces from the end of this string.
  Expression<String?> trimRight() {
    return FunctionCallExpression('RTRIM', [this]);
  }
}

/// A `text LIKE pattern` expression that will be true if the first expression
/// matches the pattern given by the second expression.
class _LikeOperator extends Expression<bool?> {
  /// The target expression that will be tested
  final Expression<String?> target;

  /// The regex-like expression to test the [target] against.
  final Expression<String?> regex;

  /// The operator to use when matching. Defaults to `LIKE`.
  final String operator;

  @override
  final Precedence precedence = Precedence.comparisonEq;

  /// Perform a like operator with the target and the regex.
  _LikeOperator(this.target, this.regex, {this.operator = 'LIKE'});

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, target);
    context.writeWhitespace();
    context.buffer.write(operator);
    context.writeWhitespace();
    writeInner(context, regex);
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(target.hashCode, $mrjc(regex.hashCode, operator.hashCode)));

  @override
  bool operator ==(Object other) {
    return other is _LikeOperator &&
        other.target == target &&
        other.regex == regex &&
        other.operator == operator;
  }
}

/// Builtin collating functions from sqlite.
///
/// See also:
/// - https://www.sqlite.org/datatype3.html#collation
enum Collate {
  /// Instruct sqlite to compare string data using memcmp(), regardless of text
  /// encoding.
  binary,

  /// The same as [Collate.binary], except the 26 upper case characters of ASCII
  /// are folded to their lower case equivalents before the comparison is
  /// performed. Note that only ASCII characters are case folded. SQLite does
  /// not attempt to do full UTF case folding due to the size of the tables
  /// required.
  noCase,

  /// The same as [Collate.binary], except that trailing space characters are
  /// ignored.
  rTrim,
}

/// A `text COLLATE collate` expression in sqlite.
class _CollateOperator extends Expression<String> {
  /// The expression on which the collate function will be run
  final Expression inner;

  /// The [Collate] to use.
  final Collate collate;

  @override
  final Precedence precedence = Precedence.postfix;

  /// Constructs a collate expression on the [inner] expression and the
  /// [Collate].
  _CollateOperator(this.inner, this.collate);

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, inner);
    context.buffer..write(' COLLATE ')..write(_operatorNames[collate]);
  }

  @override
  int get hashCode => $mrjf($mrjc(inner.hashCode, collate.hashCode));

  @override
  bool operator ==(Object other) {
    return other is _CollateOperator &&
        other.inner == inner &&
        other.collate == collate;
  }

  static const Map<Collate, String> _operatorNames = {
    Collate.binary: 'BINARY',
    Collate.noCase: 'NOCASE',
    Collate.rTrim: 'RTRIM',
  };
}
