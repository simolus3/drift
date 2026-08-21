import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

const defaultDialect = SqliteDialect.withOptions();

void expectEquals(Object? actual, Object? expected) {
  expect(actual, equals(expected));
  expect(actual.hashCode, equals(expected.hashCode));
}

void expectNotEquals(Object? actual, Object? expected) {
  expect(actual, isNot(equals(expected)));
  expect(actual.hashCode, isNot(equals(expected.hashCode)));
}

/// Matcher for [Component]-subclasses. Expect that a component generates the
/// matching [sql] and, optionally, the matching [variables].
Matcher generates(dynamic sql, [dynamic variables = isEmpty]) {
  return generatesWithDialect(
    sql,
    variables: variables,
    dialect: defaultDialect,
  );
}

Matcher generatesWithDialect(
  dynamic sql, {
  dynamic variables = isEmpty,
  required DriftDialect dialect,
}) {
  return _GeneratesSqlMatcher(
    wrapMatcher(sql),
    wrapMatcher(variables),
    dialect,
  );
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
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (matchState.containsKey('wrong_type')) {
      mismatchDescription = mismatchDescription.add('is not of type component');
    }
    if (matchState.containsKey('sql')) {
      final sql = matchState['sql'] as String;

      mismatchDescription = mismatchDescription.add('generated $sql, which ');
      mismatchDescription = _matchSql.describeMismatch(
        sql,
        mismatchDescription,
        matchState['sql_match'] as Map,
        verbose,
      );
    }
    if (matchState.containsKey('vars')) {
      final vars = matchState['vars'] as List;

      mismatchDescription = mismatchDescription.add(
        'generated variables $vars, which ',
      );
      mismatchDescription = _matchVariables!.describeMismatch(
        vars,
        mismatchDescription,
        matchState['vars_match'] as Map,
        verbose,
      );
    }
    return mismatchDescription;
  }

  @override
  bool matches(dynamic item, Map<Object?, Object?> matchState) {
    if (item is! SqlComponent) {
      matchState['wrong_type'] = true;
      return false;
    }

    final result = dialect.compile(item);

    var matches = true;

    final sqlMatchState = <String, Object?>{};
    if (!_matchSql.matches(result.sql, sqlMatchState)) {
      matchState['sql'] = result.sql;
      matchState['sql_match'] = sqlMatchState;
      matches = false;
    }

    final argsMatchState = <Object?, Object?>{};
    if (_matchVariables != null &&
        !_matchVariables.matches(
          result.variables.map((e) => e.rawValue),
          argsMatchState,
        )) {
      matchState['vars'] = result.variables;
      matchState['vars_match'] = argsMatchState;
      matches = false;
    }

    return matches;
  }
}

Matcher isStatementInBatch(int sqlIndex, List<Object?> variables) {
  return isA<StatementInBatch>()
      .having((e) => e.sqlIndex, 'sqlIndex', sqlIndex)
      .having(
        (e) => e.info.variables.map((v) => v.rawValue).toList(),
        'variables',
        variables,
      );
}
