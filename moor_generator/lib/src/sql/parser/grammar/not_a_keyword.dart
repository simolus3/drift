import 'package:moor/sqlite_keywords.dart';
import 'package:petitparser/petitparser.dart';

/// A parser that accepts any word as long as it's not a sql keyword.
class NotAKeywordParser extends Parser<String> {
  final Parser<String> _inner = word().star().flatten();

  @override
  Parser<String> copy() {
    return this;
  }

  @override
  Result<String> parseOn(Context context) {
    final innerResult = _inner.parseOn(context);

    if (innerResult.isFailure) {
      return innerResult;
    }

    if (sqliteKeywords.contains(innerResult.value.toUpperCase())) {
      return innerResult.failure('did not expect a sqlite keyword');
    }

    return innerResult;
  }
}
