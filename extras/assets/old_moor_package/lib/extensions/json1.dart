/// Experimental bindings to the [json1](https://www.sqlite.org/json1.html)
/// sqlite extension.
///
/// Note that the json1 extension might not be available on all runtimes. In
/// particular, it can only work reliably on Android when using the
/// [moor_ffi](https://drift.simonbinder.eu/docs/other-engines/vm/) and it might
/// not work on older iOS versions.
@experimental
@moorDeprecated
library json1;

import 'package:meta/meta.dart';
import 'package:moor/src/deprecated.dart';

export 'package:drift/extensions/json1.dart';
