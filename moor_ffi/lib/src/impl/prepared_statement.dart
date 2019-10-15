part of 'database.dart';

class PreparedStatement implements BasePreparedStatement {
  final Pointer<types.Statement> _stmt;
  final Database _db;
  bool _closed = false;

  bool _bound = false;
  final List<Pointer> _allocatedWhileBinding = [];

  PreparedStatement._(this._stmt, this._db);

  @override
  void close() {
    if (!_closed) {
      _reset();
      bindings.sqlite3_finalize(_stmt);
      _db._handleStmtFinalized(this);
    }
    _closed = true;
  }

  void _ensureNotFinalized() {
    if (_closed) {
      throw StateError('Tried to operate on a released prepared statement');
    }
  }

  @override
  Result select([List<dynamic> params]) {
    _ensureNotFinalized();
    _reset();
    _bindParams(params);

    final columnCount = bindings.sqlite3_column_count(_stmt);
    // not using a Map<String, int> for indexed because column names are not
    // guaranteed to be unique
    final names = List<String>(columnCount);
    final rows = <List<dynamic>>[];

    for (var i = 0; i < columnCount; i++) {
      // name pointer doesn't need to be disposed, that happens when we finalize
      names[i] =
          bindings.sqlite3_column_name(_stmt, i).load<CBlob>().readString();
    }

    while (_step() == Errors.SQLITE_ROW) {
      rows.add([for (var i = 0; i < columnCount; i++) _readValue(i)]);
    }

    return Result(names, rows);
  }

  dynamic _readValue(int index) {
    final type = bindings.sqlite3_column_type(_stmt, index);
    switch (type) {
      case Types.SQLITE_INTEGER:
        return bindings.sqlite3_column_int(_stmt, index);
      case Types.SQLITE_FLOAT:
        return bindings.sqlite3_column_double(_stmt, index);
      case Types.SQLITE_TEXT:
        final length = bindings.sqlite3_column_bytes(_stmt, index);
        return bindings
            .sqlite3_column_text(_stmt, index)
            .load<CBlob>()
            .readAsStringWithLength(length);
      case Types.SQLITE_BLOB:
        final length = bindings.sqlite3_column_bytes(_stmt, index);
        return bindings
            .sqlite3_column_blob(_stmt, index)
            .load<CBlob>()
            .read(length);
      case Types.SQLITE_NULL:
      default:
        return null;
    }
  }

  @override
  void execute([List<dynamic> params]) {
    _ensureNotFinalized();
    _reset();
    _bindParams(params);

    final result = _step();

    if (result != Errors.SQLITE_OK && result != Errors.SQLITE_DONE) {
      throw SqliteException._fromErrorCode(_db._db, result);
    }
  }

  void _reset() {
    if (_bound) {
      bindings.sqlite3_reset(_stmt);
      _bound = false;
    }
    for (var pointer in _allocatedWhileBinding) {
      pointer.$free();
    }
    _allocatedWhileBinding.clear();
  }

  void _bindParams(List<dynamic> params) {
    if (params != null && params.isNotEmpty) {
      // variables in sqlite are 1-indexed
      for (var i = 1; i <= params.length; i++) {
        final param = params[i - 1];

        if (param == null) {
          bindings.sqlite3_bind_null(_stmt, i);
        } else if (param is int) {
          bindings.sqlite3_bind_int(_stmt, i, param);
        } else if (param is num) {
          bindings.sqlite3_bind_double(_stmt, i, param.toDouble());
        } else if (param is String) {
          final ptr = CBlob.allocateString(param);
          _allocatedWhileBinding.add(ptr);

          bindings.sqlite3_bind_text(_stmt, i, ptr, -1, nullptr);
        } else if (param is Uint8List) {
          // todo we just have a null pointer param.isEmpty. I guess we have
          // to use sqlite3_bind_zeroblob for that?
          final ptr = CBlob.allocate(param);
          _allocatedWhileBinding.add(ptr);

          bindings.sqlite3_bind_blob(_stmt, i, ptr, param.length, nullptr);
        }
      }
    }
    _bound = true;
  }

  int _step() => bindings.sqlite3_step(_stmt);
}
