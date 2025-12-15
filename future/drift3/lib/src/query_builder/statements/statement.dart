import '../compiler.dart';

abstract base class SqlStatement
    with DialectSpecificComponent
    implements SqlComponent {}
