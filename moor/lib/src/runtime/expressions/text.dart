import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/expression.dart';
import 'package:moor/src/types/sql_types.dart';

/// A `text LIKE pattern` expression that will be true if the first expression
/// matches the pattern given by the second expression.
class LikeOperator extends Expression<bool, BoolType> {
  final Expression<String, StringType> target;
  final Expression<String, StringType> regex;

  LikeOperator(this.target, this.regex);

  @override
  void writeInto(GenerationContext context) {
    target.writeInto(context);
    context.buffer.write(' LIKE ');
    regex.writeInto(context);
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
class CollateOperator extends Expression<String, StringType> {
  final Expression inner;
  final Collate collate;

  CollateOperator(this.inner, this.collate);

  @override
  void writeInto(GenerationContext context) {
    inner.writeInto(context);
    context.buffer..write(' COLLATE ')..write(_operatorNames[collate]);
  }

  static const Map<Collate, String> _operatorNames = {
    Collate.binary: 'BINARY',
    Collate.noCase: 'NOCASE',
    Collate.rTrim: 'RTRIM',
  };
}
