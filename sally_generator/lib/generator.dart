import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sally_generator/src/sally_generator.dart';

Builder sallyBuilder(BuilderOptions _) =>
    SharedPartBuilder([SallyGenerator()], 'sally');
