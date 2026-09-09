/// Bindings to the [fts5](https://www.sqlite.org/fts5.html) sqlite extension,
/// which provides full-text search functionality.
///
/// The extension members in this library assume that the table they're used
/// with was created as an fts5 virtual table. In a drift file, such tables are
/// declared like this:
///
/// ```sql
/// CREATE VIRTUAL TABLE email USING fts5(sender, title, body);
/// ```
///
/// With that table, a full-text search could look like this:
///
/// ```dart
/// final query = select(emails)
///   ..where(emails.match('hello NEAR world'))
///   ..orderBy([(u) => OrderingTerm(expression: emails.rank)]);
/// ```
library;

import '../drift.dart';

/// Support for [full-text search](https://www.sqlite.org/fts5.html) queries
/// on fts5 tables.
///
/// See the [sqlite documentation](https://www.sqlite.org/fts5.html) for
/// details on the fts5 query syntax and its auxiliary functions.
extension Fts5Extensions on VirtualTableInfo {
  /// A reference to this fts5 table as an sql expression.
  ///
  /// fts5 adds a hidden column named after the table itself to every virtual
  /// table. That column is the left operand of the `MATCH` operator and the
  /// first argument of the fts5 auxiliary functions.
  /// Note that the hidden column keeps the name of the original table even
  /// when the table is used with an alias, which is why [entityName] and not
  /// [aliasedName] is used as the column name here.
  GeneratedColumn<String> get _tableReference => GeneratedColumn<String>(
    entityName,
    aliasedName,
    true,
    type: DriftSqlType.string,
  );

  /// Whether this table contains a row matching the fts5 [query] string.
  ///
  /// The [query] uses the
  /// [fts5 query syntax](https://www.sqlite.org/fts5.html#full_text_query_strings),
  /// it is sent to the database as a variable so that it's safe to construct
  /// it from user input.
  ///
  /// ```dart
  /// select(emails)..where(emails.match('hello NEAR world'));
  /// ```
  ///
  /// To restrict a search to individual columns, use the column filter syntax
  /// of the fts5 query language, e.g. `emails.match('{title body} : hello')`.
  ///
  /// See also:
  ///  - [matchExp], which is like this method but supports arbitrary
  ///    expressions as the query.
  Expression<bool> match(String query) => matchExp(Variable.withString(query));

  /// Whether this table contains a row matching the fts5 query given as an
  /// sql [expression].
  ///
  /// See [match] for more details.
  Expression<bool> matchExp(Expression<String> expression) {
    return _Fts5MatchExpression(_tableReference, expression);
  }

  /// Returns the text of [column] with a match found by an fts5 query wrapped
  /// in [before] and [after].
  ///
  /// The [column] must be a column of this fts5 table, otherwise an
  /// [ArgumentError] is thrown. The [before] and [after] markers are typically
  /// html or markdown tags used to highlight the matching terms.
  ///
  /// When [column] doesn't contain a match for the query of the surrounding
  /// statement, its text is returned as it is. This expression only evaluates
  /// to `null` when the value of [column] is `null` itself, which can happen
  /// for tables storing their contents in another table.
  ///
  /// ```dart
  /// selectOnly(emails)
  ///   ..where(emails.match('reminder'))
  ///   ..addColumns([
  ///     emails.highlight(emails.title, before: '<b>', after: '</b>'),
  ///   ]);
  /// ```
  ///
  /// See the
  /// [sqlite documentation](https://www.sqlite.org/fts5.html#the_highlight_function)
  /// for details.
  Expression<String> highlight(
    GeneratedColumn<String> column, {
    required String before,
    required String after,
  }) {
    return FunctionCallExpression<String>('highlight', [
      _tableReference,
      Variable.withInt(_columnIndex(column)),
      Variable.withString(before),
      Variable.withString(after),
    ]);
  }

  /// Like [highlight], but only reports a [tokenCount] tokens of text around
  /// each match, separated by [ellipsis] when text was omitted.
  ///
  /// When [column] doesn't contain a match for the query of the surrounding
  /// statement, its text is returned as it is. This expression only evaluates
  /// to `null` when the value of [column] is `null` itself, which can happen
  /// for tables storing their contents in another table.
  ///
  /// ```dart
  /// selectOnly(emails)
  ///   ..addColumns([
  ///     emails.snippet(
  ///       emails.title,
  ///       before: '<b>',
  ///       after: '</b>',
  ///       ellipsis: '…',
  ///       tokenCount: 64,
  ///     ),
  ///   ]);
  /// ```
  ///
  /// See the
  /// [sqlite documentation](https://www.sqlite.org/fts5.html#the_snippet_function)
  /// for details.
  Expression<String> snippet(
    GeneratedColumn<String> column, {
    required String before,
    required String after,
    required String ellipsis,
    required int tokenCount,
  }) {
    return FunctionCallExpression<String>('snippet', [
      _tableReference,
      Variable.withInt(_columnIndex(column)),
      Variable.withString(before),
      Variable.withString(after),
      Variable.withString(ellipsis),
      Variable.withInt(tokenCount),
    ]);
  }

  /// The [bm25](https://www.sqlite.org/fts5.html#the_bm25_function) relevance
  /// of a match found by an fts5 query.
  ///
  /// The optional [weights] can be used to assign different weights to the
  /// columns of this table, in the order in which they were declared. An
  /// omitted weight defaults to `1.0`. At most one weight per column may be
  /// given.
  ///
  /// Matches with a higher relevance evaluate to smaller values, so ordering
  /// by this expression in ascending order returns the best matches first.
  ///
  /// ```dart
  /// select(emails)
  ///   ..where(emails.match('hello'))
  ///   ..orderBy([(u) => OrderingTerm(expression: emails.bm25())]);
  /// ```
  ///
  /// With default weights, this is the same as [rank].
  Expression<double> bm25({List<double> weights = const []}) {
    return FunctionCallExpression<double>('bm25', [
      _tableReference,
      for (final weight in weights) Variable.withReal(weight),
    ]);
  }

  /// The relevance of a match found by an fts5 query, as computed by [bm25]
  /// with default weights.
  ///
  /// This is a hidden column that sqlite adds to every fts5 table. It can only
  /// be used in statements that also use [match] on this table.
  ///
  /// Matches with a higher relevance evaluate to smaller values, so ordering
  /// by this expression in ascending order returns the best matches first.
  ///
  /// ```dart
  /// select(emails)
  ///   ..where(emails.match('hello'))
  ///   ..orderBy([(u) => OrderingTerm(expression: emails.rank)]);
  /// ```
  ///
  /// See the
  /// [sqlite documentation](https://www.sqlite.org/fts5.html#the_bm25_function)
  /// for details.
  Expression<double> get rank => GeneratedColumn<double>(
    'rank',
    aliasedName,
    true,
    type: DriftSqlType.double,
  );

  /// The index of [column] in the `USING fts5(...)` declaration of this table,
  /// as used by the fts5 auxiliary functions. Columns are matched by name,
  /// since aliases of a table create fresh instances but keep the column names.
  int _columnIndex(GeneratedColumn<String> column) {
    final index = $columns.indexWhere((c) => c.$name == column.$name);
    if (index == -1) {
      throw ArgumentError.value(
        column,
        'column',
        'Not a column of the fts5 table $entityName',
      );
    }
    return index;
  }
}

/// An `fts_table MATCH query` expression.
class _Fts5MatchExpression extends Expression<bool> {
  /// The hidden column referencing the fts5 table to search.
  final GeneratedColumn<String> table;

  /// The fts5 query string.
  final Expression<String> query;

  @override
  final Precedence precedence = Precedence.comparisonEq;

  _Fts5MatchExpression(this.table, this.query);

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, table);
    context.writeWhitespace();
    context.buffer.write('MATCH');
    context.writeWhitespace();
    writeInner(context, query);
  }

  @override
  int get hashCode => Object.hash(table, query);

  @override
  bool operator ==(Object other) {
    return other is _Fts5MatchExpression &&
        other.table == table &&
        other.query == query;
  }
}
