/// Experimental bindings to the [json1](https://www.sqlite.org/json1.html)
/// sqlite extension.
///
/// Note that the json1 extension might not be available on all runtimes.
/// When using this library, it is recommended to use a `NativeDatabase` with
/// a dependency on `sqlite3_flutter_libs`.
@experimental
library json1;

import 'package:meta/meta.dart';
import '../drift.dart';

/// Defines extensions on string expressions to support the json1 api from Dart.
extension JsonExtensions on Expression<String> {
  /// Reads `this` expression as a JSON structure and outputs the JSON in a
  /// minified format.
  ///
  /// For details, see https://www.sqlite.org/json1.html#jmini.
  Expression<String> json() {
    return FunctionCallExpression('json', [this]);
  }

  /// Reads `this` expression as a JSON structure and outputs the JSON in a
  /// binary format internal to sqlite3.
  ///
  /// For details, see https://www.sqlite.org/json1.html#jminib.
  Expression<Uint8List> jsonb() {
    return FunctionCallExpression('jsonb', [this]);
  }

  /// Assuming that this string is a json array, returns the length of this json
  /// array.
  ///
  /// The [path] parameter is optional. If it's set, it must refer to a valid
  /// path in this json that will be used instead of `this`. See the
  /// [sqlite documentation](https://www.sqlite.org/json1.html#path_arguments)
  /// for details. If [path] is an invalid path, this expression can cause an
  /// error when run by sqlite.
  ///
  /// For this method to be valid, `this` must be a string representing a valid
  /// json array. Otherwise, sqlite will report an error when attempting to
  /// evaluate this expression.
  ///
  /// See also:
  ///  - the [sqlite documentation for this function](https://www.sqlite.org/json1.html#the_json_array_length_function)
  Expression<int> jsonArrayLength([String? path]) {
    return FunctionCallExpression('json_array_length', [
      this,
      if (path != null) Variable.withString(path),
    ]);
  }

  /// Assuming that this string is a json object or array, extracts a part of
  /// this structure identified by [path].
  ///
  /// For more details on how to format the [path] argument, see the
  /// [sqlite documentation](https://www.sqlite.org/json1.html#path_arguments).
  ///
  /// Evaluating this expression will cause an error if [path] has an invalid
  /// format or `this` isn't well-formatted json.
  ///
  /// Note that the [T] type parameter has to be set if this function is used
  /// in [JoinedSelectStatement.addColumns] or compared via [Expression.equals].
  /// The [T] parameter denotes the mapped Dart type for this expression,
  /// such as [String].
  Expression<T> jsonExtract<T extends Object>(String path) {
    return FunctionCallExpression('json_extract', [
      this,
      Variable.withString(path),
    ]).dartCast<T>();
  }

  /// Calls the `json_each` table-valued function on `this` string, optionally
  /// using [path] as the root path.
  ///
  /// This can be used to join every element in a JSON structure to a drift
  /// query.
  ///
  /// See also: The [sqlite3 documentation](https://sqlite.org/json1.html#jeach)
  /// and [JsonTableFunction].
  JsonTableFunction jsonEach(DatabaseConnectionUser database, [String? path]) {
    return JsonTableFunction._(database, functionName: 'json_each', arguments: [
      this,
      if (path != null) Variable(path),
    ]);
  }

  /// Calls the `json_tree` table-valued function on `this` string, optionally
  /// using [path] as the root path.
  ///
  /// This can be used to join every element in a JSON structure to a drift
  /// query.
  ///
  /// See also: The [sqlite3 documentation](https://sqlite.org/json1.html#jeach)
  /// and [JsonTableFunction].
  JsonTableFunction jsonTree(DatabaseConnectionUser database, [String? path]) {
    return JsonTableFunction._(database, functionName: 'json_tree', arguments: [
      this,
      if (path != null) Variable(path),
    ]);
  }
}

/// Defines extensions for the binary `JSONB` format introduced in sqlite3
/// version 3.45.
///
/// For details, see https://www.sqlite.org/json1.html#jsonb
extension JsonbExtensions on Expression<Uint8List> {
  /// Reads this binary JSONB structure and emits its textual representation as
  /// minified JSON.
  ///
  /// For details, see https://www.sqlite.org/json1.html#jmini.
  Expression<String> json() {
    return dartCast<String>().json();
  }

  /// Assuming that `this` is an expression evaluating to a binary JSONB array,
  /// returns the length of the array.
  ///
  /// See [JsonExtensions.jsonArrayLength] for more details and
  /// https://www.sqlite.org/json1.html#jsonb for details on jsonb.
  Expression<int> jsonArrayLength([String? path]) {
    // the function accepts both formats, and this way we avoid some duplicate
    // code.
    return dartCast<String>().jsonArrayLength(path);
  }

  /// Assuming that `this` is an expression evaluating to a binary JSONB object
  /// or array, extracts the part of the structure identified by [path].
  ///
  /// For more details, see [JsonExtensions.jsonExtract] or
  /// https://www.sqlite.org/json1.html#jex.
  Expression<T> jsonExtract<T extends Object>(String path) {
    return dartCast<String>().jsonExtract(path);
  }

  /// Calls the `json_each` table-valued function on `this` binary JSON buffer,
  /// optionally using [path] as the root path.
  ///
  /// See [JsonTableFunction] and [JsonExtensions.jsonEach] for more details.
  JsonTableFunction jsonEach(DatabaseConnectionUser database, [String? path]) {
    return dartCast<String>().jsonEach(database, path);
  }

  /// Calls the `json_tree` table-valued function on `this` binary JSON buffer,
  /// optionally using [path] as the root path.
  ///
  /// See [JsonTableFunction] and [JsonExtensions.jsonTree] for more details.
  JsonTableFunction jsonTree(DatabaseConnectionUser database, [String? path]) {
    return dartCast<String>().jsonTree(database, path);
  }
}

/// Calls [json table-valued functions](https://sqlite.org/json1.html#jeach) in
/// drift.
///
/// With [JsonExtensions.jsonEach] and [JsonExtensions.jsonTree], a JSON value
/// can be used a table-like structure available in queries and joins.
///
/// For an example and more details, see the [drift documentation](https://drift.simonbinder.eu/docs/advanced-features/joins/#json-support)
final class JsonTableFunction extends TableValuedFunction<JsonTableFunction> {
  JsonTableFunction._(
    super.attachedDatabase, {
    required super.functionName,
    required super.arguments,
    super.alias,
  }) : super(
          columns: [
            GeneratedColumn<DriftAny>('key', alias ?? functionName, true,
                type: DriftSqlType.any),
            GeneratedColumn<DriftAny>('value', alias ?? functionName, true,
                type: DriftSqlType.any),
            GeneratedColumn<String>('type', alias ?? functionName, true,
                type: DriftSqlType.string),
            GeneratedColumn<DriftAny>('atom', alias ?? functionName, true,
                type: DriftSqlType.any),
            GeneratedColumn<int>('id', alias ?? functionName, true,
                type: DriftSqlType.int),
            GeneratedColumn<int>('parent', alias ?? functionName, true,
                type: DriftSqlType.int),
            GeneratedColumn<String>('fullkey', alias ?? functionName, true,
                type: DriftSqlType.string),
            GeneratedColumn<String>('path', alias ?? functionName, true,
                type: DriftSqlType.string),
          ],
        );

  Expression<T> _col<T extends Object>(String name) {
    return columnsByName[name]! as Expression<T>;
  }

  /// The JSON key under which this element can be found in its parent, or
  /// `null` if this is the root element.
  ///
  /// Child elements of objects have a string key, elements in arrays are
  /// represented by their index.
  Expression<DriftAny> get key => _col('key');

  /// The value for the current value.
  ///
  /// Scalar values are returned directly, objects and arrays are returned as
  /// JSON strings.
  Expression<DriftAny> get value => _col('value');

  /// The result of calling [`sqlite3_type`](https://sqlite.org/json1.html#the_json_type_function)
  /// on this JSON element.
  Expression<String> get type => _col('type');

  /// The [value], or `null` if this is not a scalar value (so either an object
  /// or an array).
  Expression<DriftAny> get atom => _col('atom');

  /// An id uniquely identifying this element in the original JSON tree.
  Expression<int> get id => _col('id');

  /// The [id] of the parent of this element.
  Expression<int> get parent => _col('parent');

  /// The JSON key that can be passed to functions like
  /// [JsonExtensions.jsonExtract] to find this value.
  Expression<String> get fullKey => _col('fullkey');

  /// Similar to [fullKey], but relative to the `root` argument passed to
  /// [JsonExtensions.jsonEach] or [JsonExtensions.jsonTree].
  Expression<String> get path => _col('path');

  @override
  ResultSetImplementation<JsonTableFunction, TypedResult> createAlias(
      String alias) {
    return JsonTableFunction._(
      attachedDatabase,
      functionName: entityName,
      arguments: arguments,
      alias: alias,
    );
  }
}
