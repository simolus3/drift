import 'package:drift/drift.dart';

import 'compiler.dart';

/// Enumeration of different insert behaviors. See the documentation on the
/// individual fields for details.
enum InsertMode {
  /// A regular `INSERT INTO` statement. When a row with the same primary or
  /// unique key already exists, the insert statement will fail and an exception
  /// will be thrown. If the exception is caught, previous statements made in
  /// the same transaction will NOT be reverted.
  insert,

  /// Identical to [InsertMode.insertOrReplace], included for the sake of
  /// completeness.
  replace,

  /// Like [insert], but if a row with the same primary or unique key already
  /// exists, it will be deleted and re-created with the row being inserted.
  insertOrReplace,

  /// Similar to [InsertMode.insertOrAbort], but it will revert the surrounding
  /// transaction if a constraint is violated, even if the thrown exception is
  /// caught.
  insertOrRollback,

  /// Identical to [insert], included for the sake of completeness.
  insertOrAbort,

  /// Like [insert], but if multiple values are inserted with the same insert
  /// statement and one of them fails, the others will still be completed.
  insertOrFail,

  /// Like [insert], but failures will be ignored.
  insertOrIgnore;
}

/// Provides the SQLite-specific [mode] function for insert statements.
extension SetInsertMode<Row extends Object, RS extends GeneratedTable<Row, RS>>
    on InsertStatement<Row, RS> {
  /// Applies the [InsertMode] for this statement.
  ///
  /// This is a SQLite-specific API that can be used to customize how the insert
  /// statement behaves with conflicts. For a variant that is better suited for
  /// different SQL dialects, see [DoUpdate].
  InsertStatement<Row, RS> mode(InsertMode mode) {
    final options = dialectSpecificOptions.toBuilder();
    options[insertModeKey] = mode;
    return copyWith(dialectSpecificOptions: options.build());
  }
}
