import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;

const _version = '3390300';
const _year = '2022';
const _url = 'https://www.sqlite.org/$_year/sqlite-autoconf-$_version.tar.gz';

Future<void> main(List<String> args) async {
  if (args.contains('version')) {
    print(_version);
    exit(0);
  }

  final driftDirectory = p.dirname(p.dirname(Platform.script.toFilePath()));
  final target = p.join(driftDirectory, '.dart_tool', 'sqlite3');
  final versionFile = File(p.join(target, 'version'));

  final needsDownload = args.contains('--force') ||
      !versionFile.existsSync() ||
      versionFile.readAsStringSync() != _version;

  if (!needsDownload) {
    print('Not doing anything as sqlite3 has already been downloaded. Use '
        '--force to re-compile it.');
    exit(0);
  }

  print('Downloading and compiling sqlite3 for drift test');

  final temporaryDir =
      await Directory.systemTemp.createTemp('drift-compile-sqlite3');
  final temporaryDirPath = temporaryDir.path;

  // Compiling on Windows is ugly because we need users to have Visual Studio
  // installed and all those tools activated in the current shell.
  // Much easier to just download precompiled builds.
  if (Platform.isWindows) {
    const windowsUri =
        'https://www.sqlite.org/$_year/sqlite-dll-win64-x64-$_version.zip';
    final sqlite3Zip = p.join(temporaryDirPath, 'sqlite3.zip');
    final client = Client();
    final response = await client.send(Request('GET', Uri.parse(windowsUri)));
    if (response.statusCode != 200) {
      print(
          'Could not download $windowsUri, status code ${response.statusCode}');
      exit(1);
    }
    await response.stream.pipe(File(sqlite3Zip).openWrite());

    final inputStream = InputFileStream(sqlite3Zip);
    final archive = ZipDecoder().decodeBuffer(inputStream);

    for (final file in archive.files) {
      if (file.isFile && file.name == 'sqlite3.dll') {
        final outputStream = OutputFileStream(p.join(target, 'sqlite3.dll'));

        file.writeContent(outputStream);
        outputStream.close();
      }
    }

    await File(p.join(target, 'version')).writeAsString(_version);
    exit(0);
  }

  await _run('curl $_url --output sqlite.tar.gz',
      workingDirectory: temporaryDirPath);
  await _run('tar zxvf sqlite.tar.gz', workingDirectory: temporaryDirPath);

  final sqlitePath = p.join(temporaryDirPath, 'sqlite-autoconf-$_version');
  await _run('./configure', workingDirectory: sqlitePath);
  await _run('make -j', workingDirectory: sqlitePath);

  final targetDirectory = Directory(target);

  if (!targetDirectory.existsSync()) {
    // Not using recursive since .dart_tool should really exist already.
    targetDirectory.createSync();
  }

  await File(p.join(sqlitePath, 'sqlite3')).copy(p.join(target, 'sqlite3'));

  if (Platform.isLinux) {
    await File(p.join(sqlitePath, '.libs', 'libsqlite3.so'))
        .copy(p.join(target, 'libsqlite3.so'));
  } else if (Platform.isMacOS) {
    await File(p.join(sqlitePath, '.libs', 'libsqlite3.dylib'))
        .copy(p.join(target, 'libsqlite3.dylib'));
  }

  await File(p.join(target, 'version')).writeAsString(_version);
}

Future<void> _run(String command, {String? workingDirectory}) async {
  print('Running $command');

  final proc = await Process.start(
    'sh',
    ['-c', command],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: workingDirectory,
  );
  final exitCode = await proc.exitCode;

  if (exitCode != 0) {
    exit(exitCode);
  }
}
