import 'package:moor/moor.dart';
import 'package:test/test.dart';

/// Matcher for [Component]-subclasses. Expect that a component generates the
/// matching [sql] and, optionally, the matching [variables].
Matcher generates(dynamic sql, [dynamic variables]) {
  final variablesMatcher = variables != null ? wrapMatcher(variables) : null;
  return _GeneratesSqlMatcher(wrapMatcher(sql), variablesMatcher);
}

class _GeneratesSqlMatcher extends Matcher {
  final Matcher _matchSql;
  final Matcher _matchVariables;

  _GeneratesSqlMatcher(this._matchSql, this._matchVariables);

  @override
  Description describe(Description description) {
    description = description.add('generates sql ').addDescriptionOf(_matchSql);

    if (_matchVariables != null) {
      description =
          description.add('and variables').addDescriptionOf(_matchVariables);
    }
    return description;
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (matchState.containsKey('wrong_type')) {
      mismatchDescription = mismatchDescription.add('is not of type component');
    }
    if (matchState.containsKey('sql')) {
      final sql = matchState['sql'] as String;

      mismatchDescription = mismatchDescription.add('generated $sql, which ');
      mismatchDescription = _matchSql.describeMismatch(
          sql, mismatchDescription, matchState, verbose);
    }
    if (matchState.containsKey('vars')) {
      final vars = matchState['vars'] as List;

      mismatchDescription = mismatchDescription.add('generated $vars, which ');
      mismatchDescription = _matchVariables.describeMismatch(
          vars, mismatchDescription, matchState, verbose);
    }
    return mismatchDescription;
  }

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Component) {
      addStateInfo(matchState, {'wrong_type': true});
      return false;
    }

    final component = item as Component;
    final ctx = GenerationContext(SqlTypeSystem.defaultInstance, null);
    component.writeInto(ctx);

    var matches = true;

    if (!_matchSql.matches(ctx.sql, matchState)) {
      addStateInfo(matchState, {'sql': ctx.sql});
      matches = false;
    }

    if (_matchVariables != null &&
        !_matchVariables.matches(ctx.boundVariables, matchState)) {
      addStateInfo(matchState, {'vars': ctx.boundVariables});
      matches = false;
    }

    return matches;
  }
}
