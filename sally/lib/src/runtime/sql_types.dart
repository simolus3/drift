/// A type that can be mapped from Dart to sql. The generic type parameter here
/// denotes the resolved dart type.
abstract class SqlType<T> {
  const SqlType();

  /// Maps the [content] to a value that we can send together with a prepared
  /// statement to represent the given value.
  dynamic mapToSqlVariable(T content);

  /// Maps the given content to a sql literal that can be included in the query
  /// string.
  String mapToSqlConstant(T content);

  /// Maps the response from sql back to a readable dart type.
  T mapFromDatabaseResponse(dynamic response);
}

/// A mapper for boolean values in sql. Booleans are represented as integers,
/// where 0 means false and any other value means true.
class BoolType extends SqlType<bool> {
  const BoolType();

  @override
  bool mapFromDatabaseResponse(response) {
    return !(response == 0);
  }

  @override
  String mapToSqlConstant(bool content) {
    return content ? '1' : '0';
  }

  @override
  mapToSqlVariable(bool content) {
    return content ? 1 : 0;
  }
}

class StringType extends SqlType<String> {
  const StringType();

  @override
  String mapFromDatabaseResponse(response) => response as String;

  @override
  String mapToSqlConstant(String content) {
    // TODO: implement mapToSqlConstant
    return null;
  }

  @override
  mapToSqlVariable(String content) => content;
}

class IntType extends SqlType<int> {
  const IntType();

  @override
  int mapFromDatabaseResponse(response) => response as int;

  @override
  String mapToSqlConstant(int content) => content.toString();

  @override
  mapToSqlVariable(int content) {
    return content;
  }
}
