/// Provides utilities around sql keywords, like optional escaping etc.
@Deprecated('Drift is no longer using this library and will remove it in the '
    'next breaking release')
library drift.sqlite_keywords;

import 'package:drift/drift.dart';

/// A set of SQL keywords.
///
/// Drift will escape column names and identifiers that appear in this set.
const baseKeywords = {
  'ADD',
  'ABORT',
  'ACTION',
  'AFTER',
  'ALL',
  'ALTER',
  'ALWAYS',
  'ANALYZE',
  'AND',
  'AS',
  'ASC',
  'ATTACH',
  'AUTOINCREMENT',
  'BEFORE',
  'BEGIN',
  'BETWEEN',
  'BY',
  'CASCADE',
  'CASE',
  'CAST',
  'CHECK',
  'COLLATE',
  'COLUMN',
  'COMMIT',
  'CONFLICT',
  'CONSTRAINT',
  'CREATE',
  'CROSS',
  'CURRENT',
  'CURRENT_DATE',
  'CURRENT_TIME',
  'CURRENT_TIMESTAMP',
  'DATABASE',
  'DEFAULT',
  'DEFERRABLE',
  'DEFERRED',
  'DELETE',
  'DESC',
  'DETACH',
  'DISTINCT',
  'DO',
  'DROP',
  'EACH',
  'ELSE',
  'END',
  'ESCAPE',
  'EXCEPT',
  'EXCLUDE',
  'EXCLUSIVE',
  'EXISTS',
  'EXPLAIN',
  'FAIL',
  'FALSE',
  'FILTER',
  'FIRST',
  'FOLLOWING',
  'FOR',
  'FOREIGN',
  'FROM',
  'FULL',
  'GENERATED',
  'GLOB',
  'GROUP',
  'GROUPS',
  'HAVING',
  'IF',
  'IGNORE',
  'IMMEDIATE',
  'IN',
  'INDEX',
  'INDEXED',
  'INITIALLY',
  'INNER',
  'INSERT',
  'INSTEAD',
  'INTERSECT',
  'INTO',
  'IS',
  'ISNULL',
  'JOIN',
  'KEY',
  'LAST',
  'LEFT',
  'LIKE',
  'LIMIT',
  'MATCH',
  'NATURAL',
  'NO',
  'NOT',
  'NOTHING',
  'NOTNULL',
  'NULL',
  'NULLS',
  'OF',
  'OFFSET',
  'ON',
  'OR',
  'ORDER',
  'OTHERS',
  'OUTER',
  'OVER',
  'PARTITION',
  'PLAN',
  'PRAGMA',
  'PRECEDING',
  'PRIMARY',
  'QUERY',
  'RAISE',
  'RANGE',
  'RECURSIVE',
  'REFERENCES',
  'REGEXP',
  'REINDEX',
  'RELEASE',
  'RENAME',
  'REPLACE',
  'RIGHT',
  'RESTRICT',
  'ROLLBACK',
  'ROW',
  'ROWID',
  'ROWS',
  'SAVEPOINT',
  'SELECT',
  'SET',
  'TABLE',
  'TEMP',
  'TEMPORARY',
  'THEN',
  'TIES',
  'TO',
  'TRANSACTION',
  'TRIGGER',
  'TRUE',
  'UNBOUNDED',
  'UNION',
  'UNIQUE',
  'UPDATE',
  'USING',
  'VACUUM',
  'VALUES',
  'VIEW',
  'VIRTUAL',
  'WHEN',
  'WHERE',
  'WINDOW',
  'WITH',
  'WITHOUT',
};

/// Contains a set of all sqlite keywords, according to
/// https://www.sqlite.org/lang_keywords.html. Drift will use this list to
/// escape keywords.
const sqliteKeywords = baseKeywords;

/// A set of keywords that need to be escaped on sqlite and aren't contained
/// in [baseKeywords].
const additionalSqliteKeywords = <String>{};

/// A set of keywords that need to be escaped on postgres and aren't contained
/// in [baseKeywords].
const additionalPostgresKeywords = <String>{
  'ANY',
  'ARRAY',
  'ASYMMETRIC',
  'BINARY',
  'BOTH',
  'CURRENT_USER',
  'ILIKE',
  'LEADING',
  'LOCALTIME',
  'LOCALTIMESTAMP',
  'GRANT',
  'ONLY',
  'OVERLAPS',
  'PLACING',
  'SESSION_USER',
  'SIMILAR',
  'SOME',
  'SYMMETRIC',
  'TRAILING',
  'USER',
};

/// Returns whether [s] is an sql keyword by comparing it to the
/// [sqliteKeywords].
bool isSqliteKeyword(String s) => sqliteKeywords.contains(s.toUpperCase());

final _notInKeyword = RegExp('[^A-Za-z_0-9]');

/// Escapes [s] by wrapping it in backticks if it's an sqlite keyword.
String escapeIfNeeded(String s, [SqlDialect dialect = SqlDialect.sqlite]) {
  final inUpperCase = s.toUpperCase();
  var isKeyword = baseKeywords.contains(inUpperCase);

  if (dialect == SqlDialect.postgres) {
    isKeyword |= additionalPostgresKeywords.contains(inUpperCase);
  }

  if (isKeyword || _notInKeyword.hasMatch(s)) return '"$s"';
  return s;
}
