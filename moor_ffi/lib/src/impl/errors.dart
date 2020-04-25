part of 'database.dart';

class SqliteException implements Exception {
  final String message;
  final String explanation;

  /// SQLite extended result code.
  ///
  /// As defined in https://sqlite.org/rescode.html, it represent an error code,
  /// providing some idea of the cause of the failure.
  final int extendedResultCode;

  /// SQLite primary result code.
  ///
  /// As defined in https://sqlite.org/rescode.html, it represent an error code,
  /// providing some idea of the cause of the failure.
  int get resultCode => extendedResultCode & 0xFF;

  SqliteException(this.extendedResultCode, this.message, [this.explanation]);

  factory SqliteException._fromErrorCode(Pointer<types.Database> db, int code) {
    // We don't need to free the pointer returned by sqlite3_errmsg: "Memory to
    // hold the error message string is managed internally. The application does
    // not need to worry about freeing the result."
    // https://www.sqlite.org/c3ref/errcode.html
    final dbMessage = bindings.sqlite3_errmsg(db).readString();

    String explanation;
    if (code != null) {
      // Getting hold of more explanatory error code as SQLITE_IOERR error group
      // has an extensive list of extended error codes
      final extendedCode = bindings.sqlite3_extended_errcode(db);
      final errStr = bindings.sqlite3_errstr(extendedCode).readString();

      explanation = '$errStr (code $extendedCode)';
    }

    return SqliteException(code, dbMessage, explanation);
  }

  @override
  String toString() {
    if (explanation == null) {
      return 'SqliteException($extendedResultCode): $message';
    } else {
      return 'SqliteException($extendedResultCode): $message, $explanation';
    }
  }
}
