// Adapted from https://github.com/dart-lang/coverage/blob/master/bin/format_coverage.dart
// because that file doesn't work with the output of the test package.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:coverage/coverage.dart';
import 'package:path/path.dart' as p;

// ignore_for_file: avoid_print

final File outputFile = File('lcov.info');

Future<void> main() async {
  if (outputFile.existsSync()) {
    outputFile.deleteSync();
  }

  await runForProject('moor');
  await runForProject('moor_ffi');
  await runForProject('sqlparser');
}

Future runForProject(String projectName) async {
  final files = filesToProcess(projectName);
  print('$projectName: Collecting across ${files.length} files');

  final hitmap = await parseCoverage(files, 1);

  final resolver = Resolver(packagesPath: p.join(projectName, '.packages'));

  final output =
      await LcovFormatter(resolver, reportOn: [p.join(projectName, 'lib')])
          .format(hitmap);

  await outputFile.writeAsString(output, mode: FileMode.append);
}

List<File> filesToProcess(String moorSubproject) {
  final filePattern = RegExp(r'^.*\.json$');
  final coverageOutput = p.join(moorSubproject, 'coverage', 'test');

  if (FileSystemEntity.isDirectorySync(coverageOutput)) {
    return Directory(coverageOutput)
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => filePattern.hasMatch(p.basename(e.path)))
        .toList();
  }
  throw AssertionError('Moor subproject at $moorSubproject does not exist');
}
