import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart';
import 'package:server/database.dart';
import 'package:shared/tables.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// To run this server, first start a local postgres server with
//
//   docker run -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres postgres
//
void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  final database = ServerDatabase(PgDatabase(
    endpoint: Endpoint(
      host: 'localhost',
      database: 'postgres',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: ConnectionSettings(
      // Disable because this example is talking to a local postgres container.
      sslMode: SslMode.disable,
    ),
  ));

  final router = Router()
    ..post('/post', (Request request) async {
      final header = request.headers['Authorization'];
      if (header == null || !header.startsWith('Bearer ')) {
        return Response.unauthorized('Missing Authorization header');
      }

      final user =
          await database.authenticateUser(header.substring('Bearer '.length));
      if (user == null) {
        return Response.unauthorized('Invalid token');
      }

      database.posts.insertOne(PostsCompanion.insert(
          author: user.id, content: Value(await request.readAsString())));

      return Response(201);
    })
    ..get('/posts/latest', (req) async {
      final somePosts = await database.sharedDrift
          .allPosts(limit: (_, __) => Limit(10, null))
          .get();

      return Response.ok(
        json.encode([
          for (final post in somePosts)
            {
              'author': post.author,
              'post': post.posts,
            }
        ]),
        headers: {'Content-Type': 'application/json'},
      );
    });

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
