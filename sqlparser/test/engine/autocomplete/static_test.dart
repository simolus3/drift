import 'package:sqlparser/src/engine/autocomplete/engine.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('suggests a CREATE an empty file', () {
    final suggestions = completionsFor('^');

    expect(suggestions.anchor, 0);
    expect(suggestions, suggests('CREATE'));
  });

  test('suggests CREATE TABLE completion after CREATE', () async {
    final suggestions = completionsFor('CREATE ^');

    expect(suggestions.anchor, 7);
    expect(suggestions, suggests('TABLE'));
  });

  test('suggests completions for started keywords', () {
    final suggestions = completionsFor('creat^');

    expect(suggestions.anchor, 0);
    expect(suggestions, suggests('CREATE'));
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
