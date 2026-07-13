import 'dart:io';
import 'dart:isolate';

import 'package:package_config/package_config.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:http/http.dart' as http;

void main() async {
  final config = await loadPackageConfigUri((await Isolate.packageConfig)!);
  final sqliteImport =
      config.resolve(Uri.parse('package:sqlite3/sqlite3.dart'))!;
  final pubspec = Pubspec.parse(
      await File.fromUri(sqliteImport.resolve('../pubspec.yaml'))
          .readAsString());
  final tag = 'sqlite3-${pubspec.version}';

  final client = http.Client();

  Future<void> downloadFile(String name) async {
    final uri = Uri.parse(
        'https://github.com/simolus3/sqlite3.dart/releases/download/$tag/$name');
    final response = await client.send(
      http.Request(
        'GET',
        uri,
      ),
    );

    if (response.statusCode != 200) {
      throw http.ClientException(
          'Unexpected response for $name: ${response.statusCode}', uri);
    }

    final output = File('extras/assets/$name').openWrite();
    await response.stream.pipe(output);
    print('Downloaded $name');
  }

  await (downloadFile('sqlite3.wasm'), downloadFile('sqlite3mc.wasm')).wait;
  client.close();
}
