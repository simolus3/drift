part of 'database.dart';

class SqliteException implements Exception {
  final String message;
  final String explanation;

  SqliteException(this.message, [this.explanation]);

  factory SqliteException._fromErrorCode(DatabasePointer db, [int code]) {
    final dbMessage = CString.fromC(bindings.sqlite3_errmsg(db).cast());
    String explanation;
    if (code != null) {
      explanation = CString.fromC(bindings.sqlite3_errstr(code).cast());
    }

    return SqliteException(dbMessage, explanation);
  }

  @override
  String toString() {
    if (explanation == null) {
      return 'SqliteException: $message';
    } else {
      return 'SqliteException: $message, $explanation';
    }
  }
}
