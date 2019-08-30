part of 'parser.dart';

const String startInt = 'integer';
const String startString = 'text';
const String startBool = 'boolean';
const String startDateTime = 'dateTime';
const String startBlob = 'blob';
const String startReal = 'real';

const Set<String> starters = {
  startInt,
  startString,
  startBool,
  startDateTime,
  startBlob,
  startReal,
};

const String _methodNamed = 'named';
const String _methodReferences = 'references';
const String _methodAutoIncrement = 'autoIncrement';
const String _methodWithLength = 'withLength';
const String _methodNullable = 'nullable';
const String _methodCustomConstraint = 'customConstraint';
const String _methodDefault = 'withDefault';
const String _methodMap = 'map';

/// Parses a single column defined in a Dart table. These columns are a chain
/// or [MethodInvocation]s. An example getter might look like this:
/// ```dart
/// IntColumn get id => integer().autoIncrement()();
/// ```
/// The last call `()` is a [FunctionExpressionInvocation], the entries for
/// before that (in this case `autoIncrement()` and `integer()` are a)
/// [MethodInvocation]. We work our way through that syntax until we hit a
/// method that starts the chain (contained in [starters]). By visiting all
/// the invocations on our way, we can extract the constraint for the column
/// (e.g. its name, whether it has auto increment, is a primary key and so on).
class ColumnParser {
  final MoorDartParser base;

  ColumnParser(this.base);

  SpecifiedColumn parse(MethodDeclaration getter, MethodElement element) {}
}
