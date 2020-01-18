import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/engine/autocomplete/engine.dart';
import 'package:test/test.dart';

/// Parses the [moorFile] and computes available autocomplete suggestions at the
/// position of a `^` character in the source.
ComputedSuggestions completionsFor(String moorFile) {
  final position = moorFile.indexOf('^');
  final engine = SqlEngine.withOptions(EngineOptions(useMoorExtensions: true));

  final result = engine.parseMoorFile(moorFile.replaceFirst('^', ''));
  return result.autoCompleteEngine.suggestCompletions(position - 1);
}

Matcher hasCode(String code) => _SuggestionWithCode(code);
Matcher suggests(String code) => _SuggestsMatcher(contains(hasCode(code)));
Matcher suggestsAll(List<String> codes) {
  return _SuggestsMatcher(containsAll(codes.map(hasCode)));
}

class _SuggestionWithCode extends Matcher {
  final Matcher codeMatcher;

  _SuggestionWithCode(dynamic code) : codeMatcher = wrapMatcher(code);

  @override
  Description describe(Description description) {
    return description.add('suggests ').addDescriptionOf(codeMatcher);
  }

  @override
  bool matches(dynamic item, Map matchState) {
    return item is Suggestion && codeMatcher.matches(item.code, matchState);
  }
}

class _SuggestsMatcher extends CustomMatcher {
  _SuggestsMatcher(matcher)
      : super('Suggestions containing', 'suggestions', matcher);

  @override
  List<Suggestion> featureValueOf(dynamic actual) {
    if (actual is ComputedSuggestions) {
      return actual.suggestions;
    }
    return null;
  }
}
