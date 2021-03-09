//@dart=2.9
import 'package:meta/meta.dart';
import 'package:moor_generator/src/writer/writer.dart';
import 'package:recase/recase.dart';

/// Writes the following dart code into the [buffer]:
/// ```
/// ReturnType _getterName;
/// ReturnType get getterName => _getterName ??= code;
/// ```
///
/// When we're writing nnbd-code, the following code will be emitted instead:
/// ```
/// late final ReturnType getterName = code;
/// ```
///
/// This means that [code] should be an expression without any trailing
/// semicolon.
void writeMemoizedGetter(
    {@required StringBuffer buffer,
    @required String getterName,
    @required String returnType,
    @required String code,
    @required GenerationOptions options,
    bool hasOverride}) {
  if (options.nnbd) {
    buffer.writeln('late final $returnType $getterName = $code;');
  } else {
    buffer.write('$returnType _$getterName;\n');
    if (hasOverride == true) {
      buffer.write('@override\n');
    }
    buffer.write('$returnType get $getterName => _$getterName ??= $code;');
  }
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
///
/// When we're emitting nnbd-code, this method will write
/// ```dart
/// late final ReturnType get getterName => _constructGetterName();
/// ReturnType _constructGetterName() {
///   code
/// }
/// ```
void writeMemoizedGetterWithBody(
    {@required StringBuffer buffer,
    @required String getterName,
    @required String returnType,
    @required String code,
    @required GenerationOptions options,
    bool hasOverride}) {
  final constructingMethod = '_construct${ReCase(getterName).pascalCase}';

  // We only need another field without nnbd
  if (!options.nnbd) buffer.write('$returnType _$getterName;\n');

  if (hasOverride == true) {
    buffer.write('@override\n');
  }
  if (options.nnbd) {
    buffer
        .writeln('late final $returnType $getterName = $constructingMethod();');
  } else {
    buffer
      ..write('$returnType get $getterName =>')
      ..writeln(' _$getterName ??= $constructingMethod();');
  }

  buffer
    ..write('$returnType $constructingMethod() {\n')
    ..write(code)
    ..writeln('\n}');
}
