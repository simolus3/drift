import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

void expectEquals(dynamic a, dynamic expected) {
  expect(a, equals(expected));
  expect(a.hashCode, equals(expected.hashCode));
}

void expectNotEquals(dynamic a, dynamic expected) {
  expect(a, isNot(equals(expected)));
  expect(a.hashCode, isNot(equals(expected.hashCode)));
}

/// Matcher for [SqlComponent]-subclasses. Expect that a component generates the
/// matching [sql] and, optionally, the matching [variables].
Matcher generates(dynamic sql, [dynamic variables = isEmpty]) {
  return _GeneratesSqlMatcher(
    wrapMatcher(sql),
    wrapMatcher(variables),
    const SqliteDialect(),
  );
}

Matcher generatesWithOptions(
  dynamic sql, {
  dynamic variables = isEmpty,
  DriftDialect dialect = const SqliteDialect(),
}) {
  return _GeneratesSqlMatcher(
      wrapMatcher(sql), wrapMatcher(variables), dialect);
}

class _GeneratesSqlMatcher extends Matcher {
  final Matcher _matchSql;
  final Matcher? _matchVariables;

  final DriftDialect dialect;

  _GeneratesSqlMatcher(this._matchSql, this._matchVariables, this.dialect);

  @override
  Description describe(Description description) {
    description = description.add('generates sql ').addDescriptionOf(_matchSql);

    if (_matchVariables != null) {
      description = description
          .add(' and variables that ')
          .addDescriptionOf(_matchVariables);
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
          sql, mismatchDescription, matchState['sql_match'] as Map, verbose);
    }
    if (matchState.containsKey('vars')) {
      final vars = matchState['vars'] as List;

      mismatchDescription =
          mismatchDescription.add('generated variables $vars, which ');
      mismatchDescription = _matchVariables!.describeMismatch(
          vars, mismatchDescription, matchState['vars_match'] as Map, verbose);
    }
    return mismatchDescription;
  }

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! SqlComponent) {
      matchState['wrong_type'] = true;
      return false;
    }

    final statement = dialect.compile(item);

    var matches = true;

    final sqlMatchState = <String, Object?>{};
    if (!_matchSql.matches(statement.sql, sqlMatchState)) {
      matchState['sql'] = statement.sql;
      matchState['sql_match'] = sqlMatchState;
      matches = false;
    }

    final argsMatchState = <Object?, Object?>{};
    if (_matchVariables != null &&
        !_matchVariables.matches(statement.variables, argsMatchState)) {
      matchState['vars'] = statement.variables;
      matchState['vars_match'] = argsMatchState;
      matches = false;
    }

    return matches;
  }
}
