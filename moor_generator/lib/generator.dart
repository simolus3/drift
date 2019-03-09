import 'package:build/build.dart';
import 'package:moor_generator/src/dao_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:moor_generator/src/moor_generator.dart';

Builder moorBuilder(BuilderOptions _) =>
    SharedPartBuilder([MoorGenerator(), DaoGenerator()], 'moor');
