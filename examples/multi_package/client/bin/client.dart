import 'dart:convert';

import 'package:client/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:shared/tables.dart';

void main(List<String> arguments) async {
  final database = ClientDatabase(NativeDatabase.memory());
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
      batch.insert(database.users, user, onConflict: DoUpdate((old) => user));
    }
  });

  final localPosts = await database.locallySavedPosts;
  print('Saved local posts: $localPosts');

  await database.close();
}
