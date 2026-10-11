import 'dart:convert';

import 'package:client/database.dart';
import 'package:drift3_preview/drift.dart';
import 'package:http/http.dart' as http;
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:shared/tables.dart';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> arguments) async {
  final database = ClientDatabase(SqliteConnection.inMemory(sqlite3));
  final client = http.Client();

  // Fetch posts from server and save them in the local database.
  final fromServer =
      await client.get(Uri.parse('http://localhost:8080/posts/latest'));

  await database.batch((batch) {
    final entries = json.decode(fromServer.body) as List;

    for (final entry in entries) {
      final post = Post.fromJson(entry['post']);
      final user = User.fromJson(entry['author']);

      batch.insert(database.posts, post);
      batch.insert<User, $UsersTable>(database.users, user,
          onConflict: DoUpdate((old) => user));
    }
  });

  final localPosts = await database.locallySavedPosts;
  print('Saved local posts: $localPosts');

  await database.close();
}
