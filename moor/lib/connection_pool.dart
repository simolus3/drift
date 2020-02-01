/// Support library to support pooled connections with moor.
///
/// Note that using a pooled connection is not necessary for most moor apps.
@experimental
library connection_pool;

import 'package:meta/meta.dart';
import 'package:moor/backends.dart';
import 'package:moor/moor.dart';

part 'src/runtime/executor/connection_pool_impl.dart';

/// A query executor for moor that delegates work to multiple executors.
abstract class MultiExecutor extends QueryExecutor {
  /// Creates a query executor that will delegate work to different executors.
  ///
  /// Updating statements, or statements that run in a transaction, will be run
  /// with [write]. Select statements outside of a transaction are executed on
  /// [read].
  factory MultiExecutor(
      {@required QueryExecutor read, @required QueryExecutor write}) {
    return _MultiExecutorImpl(read, write);
  }

  MultiExecutor._();
}
