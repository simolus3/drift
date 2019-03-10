import 'package:meta/meta.dart';

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
