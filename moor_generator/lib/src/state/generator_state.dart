import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:moor/moor.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/state/session.dart';
import 'package:source_gen/source_gen.dart';

import 'options.dart';

GeneratorState _state;

/// Uses the created instance of the generator state or creates one via the
/// [create] callback if necessary.
GeneratorState useState(GeneratorState Function() create) {
  return _state ??= create();
}

class GeneratorState {
  final MoorOptions options;

  final Map<DartType, Future<SpecifiedTable>> _foundTables = {};
  final tableTypeChecker = const TypeChecker.fromRuntime(Table);

  GeneratorState(this.options);

  GeneratorSession startSession(BuildStep step) {
    return GeneratorSession(this, step);
  }

  /// Parses the [SpecifiedTable] from a [type]. As this operation is very
  /// expensive, we always try to only perform it once.
  ///
  /// The [resolve] function is responsible for performing the actual analysis
  /// and it will be called when the [type] has not yet been resolved.
  Future<SpecifiedTable> parseTable(
      DartType type, Future<SpecifiedTable> Function() resolve) {
    return _foundTables.putIfAbsent(type, resolve);
  }
}
