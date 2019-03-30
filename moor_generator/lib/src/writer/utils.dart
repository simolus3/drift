import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

/// Writes the following dart code into the [buffer]:
/// ```
/// ReturnType _getterName;
/// ReturnType get getterName => _getterName ??= code;
/// ```
/// This means that [code] should be an expression without any trailing
/// semicolon.
void writeMemoizedGetter(
    {@required StringBuffer buffer,
    @required String getterName,
    @required String returnType,
    @required String code,
    bool hasOverride}) {
  buffer.write('$returnType _$getterName;\n');
  if (hasOverride == true) {
    buffer.write('@override\n');
  }
  buffer.write('$returnType get $getterName => _$getterName ??= $code;');
}

/// Writes the following dart code into the [buffer]:
/// ```
/// ReturnType _getterName;
/// ReturnType get getterName => _getterName ??= _constructGetterName();
/// ReturnType _constructGetterName() {
///   code
/// }
/// ```
/// This means that the generated code will also be responsible for writing the
/// return statement and more.
void writeMemoizedGetterWithBody(
    {@required StringBuffer buffer,
    @required String getterName,
    @required String returnType,
    @required String code,
    bool hasOverride}) {
  final constructingMethod = '_construct${ReCase(getterName).pascalCase}';

  buffer.write('$returnType _$getterName;\n');
  if (hasOverride == true) {
    buffer.write('@override\n');
  }
  buffer
    ..write('$returnType get $getterName =>')
    ..write(' _$getterName ??= $constructingMethod();\n')
    ..write('$returnType $constructingMethod() {\n')
    ..write(code)
    ..write('\n}');
}
