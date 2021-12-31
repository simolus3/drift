import 'package:convert/convert.dart';
import 'package:drift/drift.dart';

part 'custom_type.dart';
part 'type_system.dart';

const _deprecated =
    Deprecated('Types will be removed in drift 5, use the methods on '
        'SqlTypeSystem instead.');

/// A type that can be mapped from Dart to sql. The generic type parameter [T]
/// denotes the resolved dart type.
@_deprecated
abstract class SqlType<T> {
  /// Constant constructor so that subclasses can be constant
  const SqlType();

  /// The name of this type in sql, such as `TEXT`.
  String sqlName(SqlDialect dialect);

  /// Maps the [content] to a value that we can send together with a prepared
  /// statement to represent the given value.
  dynamic mapToSqlVariable(T? content);

  /// Maps the given content to a sql literal that can be included in the query
  /// string.
  String? mapToSqlConstant(T? content);

  /// Maps the response from sql back to a readable dart type.
  T? mapFromDatabaseResponse(dynamic response);
}

/// A mapper for boolean values in sql. Booleans are represented as integers,
/// where 0 means false and any other value means true.
@_deprecated
class BoolType extends SqlType<bool> {
  /// Constant constructor used by the type system
  const BoolType();

  @override
  String sqlName(SqlDialect dialect) =>
      dialect == SqlDialect.sqlite ? 'INTEGER' : 'integer';

  @override
  bool? mapFromDatabaseResponse(dynamic response) {
    // ignore: avoid_returning_null
    if (response == null) return null;
    if (response is String) {
      return response.toUpperCase().compareTo('TRUE') == 0;
    }
    return response != 0;
  }

  @override
  String mapToSqlConstant(bool? content) {
    if (content == null) {
      return 'NULL';
    }
    return content ? '1' : '0';
  }

  @override
  int? mapToSqlVariable(bool? content) {
    if (content == null) {
      // ignore: avoid_returning_null
      return null;
    }
    return content ? 1 : 0;
  }
}

/// Mapper for string values in sql.
@_deprecated
class StringType extends SqlType<String> {
  /// Constant constructor used by the type system
  const StringType();

  @override
  String sqlName(SqlDialect dialect) =>
      dialect == SqlDialect.sqlite ? 'TEXT' : 'text';

  @override
  String? mapFromDatabaseResponse(dynamic response) => response?.toString();

  @override
  String mapToSqlConstant(String? content) {
    if (content == null) return 'NULL';

    // From the sqlite docs: (https://www.sqlite.org/lang_expr.html)
    // A string constant is formed by enclosing the string in single quotes (').
    // A single quote within the string can be encoded by putting two single
    // quotes in a row - as in Pascal. C-style escapes using the backslash
    // character are not supported because they are not standard SQL.
    final escapedChars = content.replaceAll('\'', '\'\'');
    return "'$escapedChars'";
  }

  @override
  String? mapToSqlVariable(String? content) => content;
}

/// Maps [int] values from and to sql
@_deprecated
class IntType extends SqlType<int> {
  /// Constant constructor used by the type system
  const IntType();

  @override
  String sqlName(SqlDialect dialect) =>
      dialect == SqlDialect.sqlite ? 'INTEGER' : 'bigint';

  @override
  int? mapFromDatabaseResponse(dynamic response) {
    if (response == null || response is int?) return response as int?;
    return int.parse(response.toString());
  }

  @override
  String mapToSqlConstant(int? content) => content?.toString() ?? 'NULL';

  @override
  int? mapToSqlVariable(int? content) {
    return content;
  }
}

/// Maps [DateTime] values from and to sql
@_deprecated
class DateTimeType extends SqlType<DateTime> {
  /// Constant constructor used by the type system
  const DateTimeType();

  @override
  String sqlName(SqlDialect dialect) =>
      dialect == SqlDialect.sqlite ? 'INTEGER' : 'integer';

  @override
  DateTime? mapFromDatabaseResponse(dynamic response) {
    if (response == null) return null;

    final unixSeconds = response as int;

    return DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
  }

  @override
  String mapToSqlConstant(DateTime? content) {
    if (content == null) return 'NULL';

    return (content.millisecondsSinceEpoch ~/ 1000).toString();
  }

  @override
  int? mapToSqlVariable(DateTime? content) {
    // ignore: avoid_returning_null
    if (content == null) return null;

    return content.millisecondsSinceEpoch ~/ 1000;
  }
}

/// Maps [Uint8List] values from and to sql
@_deprecated
class BlobType extends SqlType<Uint8List> {
  /// Constant constructor used by the type system
  const BlobType();

  @override
  String sqlName(SqlDialect dialect) =>
      dialect == SqlDialect.sqlite ? 'BLOB' : 'bytea';

  @override
  Uint8List? mapFromDatabaseResponse(dynamic response) {
    if (response is String) {
      final list = response.codeUnits;
      return Uint8List.fromList(list);
    }
    return response as Uint8List?;
  }

  @override
  String mapToSqlConstant(Uint8List? content) {
    if (content == null) return 'NULL';
    // BLOB literals are string literals containing hexadecimal data and
    // preceded by a single "x" or "X" character. Example: X'53514C697465'
    return "x'${hex.encode(content)}'";
  }

  @override
  Uint8List? mapToSqlVariable(Uint8List? content) => content;
}

/// Maps [double] values from and to sql
@_deprecated
class RealType extends SqlType<double> {
  /// Constant constructor used by the type system
  const RealType();

  @override
  String sqlName(SqlDialect dialect) =>
      dialect == SqlDialect.sqlite ? 'REAL' : 'float8';

  @override
  double? mapFromDatabaseResponse(dynamic response) {
    return (response as num?)?.toDouble();
  }

  @override
  String mapToSqlConstant(num? content) {
    if (content == null) {
      return 'NULL';
    }
    return content.toString();
  }

  @override
  num? mapToSqlVariable(num? content) => content;
}
