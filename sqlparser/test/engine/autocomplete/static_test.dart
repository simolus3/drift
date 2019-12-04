import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/engine/autocomplete/engine.dart';
import 'package:test/test.dart';

void main() {
  test('suggests a CREATE TABLE statements for an empty file', () {
    final engine = SqlEngine(useMoorExtensions: true);
    final parseResult = engine.parseMoorFile('');

    final suggestions = parseResult.autoCompleteEngine.suggestCompletions(0);

    expect(suggestions.anchor, 0);
    expect(suggestions.suggestions, contains(hasCode('CREATE')));
  });

  test('suggests completions for started expressions', () {
    final engine = SqlEngine(useMoorExtensions: true);
    final parseResult = engine.parseMoorFile('creat');

    final suggestions = parseResult.autoCompleteEngine.suggestCompletions(0);

    expect(suggestions.anchor, 0);
    expect(suggestions.suggestions, contains(hasCode('CREATE')));
  });
}

dynamic hasCode(code) => SuggestionWithCode(code);

class SuggestionWithCode extends Matcher {
  final Matcher codeMatcher;

  SuggestionWithCode(dynamic code) : codeMatcher = wrapMatcher(code);

  @override
  Description describe(Description description) {
    return description.add('suggests ').addDescriptionOf(codeMatcher);
  }

  @override
  bool matches(item, Map matchState) {
    return item is Suggestion && codeMatcher.matches(item.code, matchState);
  }
}
