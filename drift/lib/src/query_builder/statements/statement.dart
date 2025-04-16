import 'package:meta/meta.dart';

import '../compiler.dart';

@immutable
abstract base class SqlStatement
    with DialectSpecificComponent
    implements SqlComponent {}
