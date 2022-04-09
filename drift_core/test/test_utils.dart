import 'package:drift_core/dialect/sqlite3.dart' as sql;
import 'package:drift_core/drift_core.dart';
import 'package:test/expect.dart';

class Users extends SchemaTable {
  SchemaColumn<int> get id => column('id', sql.integer);
  SchemaColumn<String> get username => column('name', sql.text);

  @override
  List<SchemaColumn> get columns => [id, username];

  @override
  String get tableName => 'users';
}

class Groups extends SchemaTable {
  SchemaColumn<int> get admin => column('admin', sql.integer);
  SchemaColumn<String> get description => column('description', sql.text);

  @override
  List<SchemaColumn> get columns => [admin];
  @override
  String get tableName => 'groups';
}

/// Matcher for [SqlComponent]-subclasses. Expect that a component generates the
/// matching [sql] and, optionally, the matching [variables].
Matcher generates(dynamic sql, [dynamic variables = isEmpty]) {
  final variablesMatcher = variables != null ? wrapMatcher(variables) : isEmpty;
  return _GeneratesSqlMatcher(wrapMatcher(sql), variablesMatcher);
}

class _GeneratesSqlMatcher extends Matcher {
  final Matcher _matchSql;
  final Matcher? _matchVariables;

  _GeneratesSqlMatcher(this._matchSql, this._matchVariables);

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

    final ctx = GenerationContext(sql.dialect);
    item.writeInto(ctx);

    var matches = true;

    final sqlMatchState = {};
    if (!_matchSql.matches(ctx.sql, sqlMatchState)) {
      matchState['sql'] = ctx.sql;
      matchState['sql_match'] = sqlMatchState;
      matches = false;
    }

    final argsMatchState = {};
    final boundVariables = [
      for (final bound in ctx.boundVariables) bound.value
    ];
    if (_matchVariables != null &&
        !_matchVariables!.matches(boundVariables, argsMatchState)) {
      matchState['vars'] = boundVariables;
      matchState['vars_match'] = argsMatchState;
      matches = false;
    }

    return matches;
  }
}
