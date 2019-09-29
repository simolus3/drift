import 'dart:io';

import 'package:coverage/coverage.dart';

// note that this script will be run from the parent directory (the root of the
// moor repo)
Future main() async {
  final resolver = Resolver(packagesPath: 'moor/.packages');

  final coverage = await parseCoverage([
    File('moor/coverage.json'),
    File('sqlparser/coverage.json'),
  ], 1);

  // report coverage for the moor and moor_generator package
  final lcov = await LcovFormatter(
    resolver,
    reportOn: [
      'moor/lib/',
      'sqlparser/lib',
    ],
    basePath: '.',
  ).format(coverage);

  File('lcov.info').writeAsStringSync(lcov);
}
