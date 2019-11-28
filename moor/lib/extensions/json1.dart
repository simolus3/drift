/// Experimental bindings to the [json1](https://www.sqlite.org/json1.html)
/// sqlite extension.
///
/// Note that the json1 extension might not be available on all runtimes. In
/// particular, it can only work reliably on Android when using the
/// [moor_ffi](https://moor.simonbinder.eu/docs/other-engines/vm/) and it might
/// not work on older iOS versions.
@experimental
library json1;

import 'package:meta/meta.dart';
import '../moor.dart';

/// Defines extensions on string expressions to support the json1 api from Dart.
extension JsonExtensions on Expression<String, StringType> {
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
  Expression<int, IntType> jsonArrayLength([String path]) {
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
  /// Note that, since the return type of this function is dynamic, it can't be
  /// used in [JoinedSelectStatement.addColumns]. It's also recommended to use
  /// [Expression.equalsExp] with an explicit [Variable] instead of
  /// [Expression.equals].
  Expression jsonExtract(String path) {
    return FunctionCallExpression('json_extract', [
      this,
      Variable.withString(path),
    ]);
  }
}
