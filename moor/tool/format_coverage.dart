import 'dart:io';

import 'package:coverage/coverage.dart';

Future main() async {
  Directory.current = Directory.current.parent;

  final resolver = Resolver(
    packagesPath: 'moor/.packages',
  );

  final potentialFiles = [
    File('moor/coverage.json'),
    File('sqlparser/coverage.json'),
  ];

  final existingFiles = [
    for (var file in potentialFiles) if (file.existsSync()) file
  ];

  final coverage = await parseCoverage(existingFiles, 1);

  // report coverage for the moor and moor_generator package
  final lcov = await LcovFormatter(
    resolver,
    reportOn: [
      'moor/lib/',
      'moor_generator/lib',
      'sqlparser/lib',
    ],
    basePath: '.',
  ).format(coverage);

  File('lcov.info').writeAsStringSync(lcov);
}
