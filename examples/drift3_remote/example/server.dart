import 'dart:io';

import 'package:drift3_remote/src/server.dart';
import 'package:drift_sqlite/native.dart';
import 'package:grpc/grpc.dart';

Future<void> main(List<String> args) async {
  final pool = await sqliteConnectionPool(file: File('server.db')).open();

  final server = Server.create(
    services: [DriftDatabaseServer(pool.session)],
    codecRegistry: CodecRegistry(codecs: const [GzipCodec(), IdentityCodec()]),
  );
  await server.serve(port: 50051);
  print('Server listening on port ${server.port}...');
}
