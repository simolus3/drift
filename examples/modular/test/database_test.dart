import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:modular/database.dart';
import 'package:modular/src/posts.drift.dart';
import 'package:modular/src/users.drift.dart';
import 'package:test/test.dart';

void main() {
  // These tests aren't really part of the example, we use them to make sure
  // the modular code is working as intended.
  late Database database;

  setUp(() {
    database = Database(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('can query posts', () async {
    await database.batch((b) {
      b.insertAll(database.users, [
        UsersCompanion.insert(name: 'a'),
        UsersCompanion.insert(name: 'b'),
      ]);
      b.insert(database.posts,
          PostsCompanion.insert(author: 1, content: Value('hello world')));
    });

    final (post, refs) = await database.managers.posts
        .withReferences((p) => p(author: true))
        .getSingle();

    expect(post.content, 'hello world');
    expect(refs.author.prefetchedData, hasLength(1));
  });
}
