import 'package:build/build.dart';
import 'package:moor_generator/src/dao_generator.dart';
import 'package:moor_generator/src/options.dart';
import 'package:moor_generator/src/shared_state.dart';
import 'package:source_gen/source_gen.dart';
import 'package:moor_generator/src/moor_generator.dart';

Builder moorBuilder(BuilderOptions options) {
  final writeFromString =
      options.config['write_from_json_string_constructor'] as bool ?? false;
  final parsedOptions = MoorOptions(writeFromString);
  final state = SharedState(parsedOptions);

  return SharedPartBuilder([MoorGenerator(state), DaoGenerator()], 'moor');
}
