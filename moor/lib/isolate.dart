/// Contains utils to run moor databases in a background isolate. This API is
/// not supported on the web.
@moorDeprecated
library isolate;

import 'package:drift/isolate.dart';
import 'package:moor/src/deprecated.dart';

export 'package:drift/isolate.dart';

/// Defines utilities to run moor in a background isolate. In the operation mode
/// created by these utilities, there's a single background isolate doing all
/// the work. Any other isolate can use the [connect] method to obtain an
/// instance of a [GeneratedDatabase] class that will delegate its work onto a
/// background isolate. Auto-updating queries, and transactions work across
/// isolates, and the user facing api is exactly the same.
///
/// Please note that, while running moor in a background isolate can reduce
/// latency in foreground isolates (thus reducing UI lags), the overall
/// performance is going to be much worse as data has to be serialized and
/// deserialized to be sent over isolates.
/// Also, be aware that this api is not available on the web.
///
/// See also:
/// - [Isolate], for general information on multi threading in Dart.
/// - The [detailed documentation](https://moor.simonbinder.eu/docs/advanced-features/isolates),
///   which provides example codes on how to use this api.
@pragma('moor2drift', 'DriftIsolate')
typedef MoorIsolate = DriftIsolate;
