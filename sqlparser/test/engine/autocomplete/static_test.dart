import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/engine/autocomplete/engine.dart';
import 'package:test/test.dart';

final _moorOptions = EngineOptions(useMoorExtensions: true);

void main() {
  test('suggests a CREATE an empty file', () {
    final engine = SqlEngine.withOptions(_moorOptions);
    final parseResult = engine.parseMoorFile('');

    final suggestions = parseResult.autoCompleteEngine.suggestCompletions(0);

    expect(suggestions.anchor, 0);
    expect(suggestions.suggestions, contains(hasCode('CREATE')));
    expect(suggestions.suggestions, contains(hasCode('CREATE')));
  });

  test('suggests CREATE TABLE completion after CREATE', () async {
    final engine = SqlEngine.withOptions(_moorOptions);
    final parseResult = engine.parseMoorFile('CREATE ');

    final suggestions = parseResult.autoCompleteEngine.suggestCompletions(7);

    expect(suggestions.anchor, 7);
    expect(suggestions.suggestions, contains(hasCode('TABLE')));
  });

  test('suggests completions for started keywords', () {
    final engine = SqlEngine.withOptions(_moorOptions);
    final parseResult = engine.parseMoorFile('creat');

    final suggestions = parseResult.autoCompleteEngine.suggestCompletions(0);

    expect(suggestions.anchor, 0);
    expect(suggestions.suggestions, contains(hasCode('CREATE')));
  });
}

dynamic hasCode(dynamic code) => SuggestionWithCode(code);

class SuggestionWithCode extends Matcher {
  final Matcher codeMatcher;

  SuggestionWithCode(dynamic code) : codeMatcher = wrapMatcher(code);

  @override
  Description describe(Description description) {
    return description.add('suggests ').addDescriptionOf(codeMatcher);
  }

  @override
  bool matches(dynamic item, Map matchState) {
    return item is Suggestion && codeMatcher.matches(item.code, matchState);
  }
}
