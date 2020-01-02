part of 'parser.dart';

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
class VariableParser {
  final MoorDartParser base;

  VariableParser(this.base);

  MoorVariable parse(PropertyInducingElement element) {
    ParsedLibraryResult parsedLibResult = element.session.getParsedLibraryByElement(element.library);
    ElementDeclarationResult elDeclarationResult = parsedLibResult.getElementDeclaration(element);

	String value;

	final parts = elDeclarationResult.node.toSource().split("= ");
	if(parts.length == 2){
		value = parts[1];
	}

    return MoorVariable(
      type: element.type.name,
      name: element.name,
	  value: value,
      declaration: DartColumnDeclaration(element, base.step.file),
    );
  }
}
