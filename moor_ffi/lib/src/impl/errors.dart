part of 'database.dart';

class SqliteException implements Exception {
  final String message;
  final String explanation;

  SqliteException(this.message, [this.explanation]);

  factory SqliteException._fromErrorCode(Pointer<types.Database> db,
      [int code]) {
    // We don't need to free the pointer returned by sqlite3_errmsg: "Memory to
    // hold the error message string is managed internally. The application does
    // not need to worry about freeing the result."
    // https://www.sqlite.org/c3ref/errcode.html
    final dbMessage = bindings.sqlite3_errmsg(db).readString();

    String explanation;
    if (code != null) {
      explanation = bindings.sqlite3_errstr(code).readString();
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
