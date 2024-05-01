// ignore_for_file: type=lint, invalid_use_of_internal_member
import 'package:drift/drift.dart' as i0;
import 'package:drift/internal/modular.dart' as i1;
import 'package:shared/src/posts.drift.dart' as i2;
import 'package:shared/src/users.drift.dart' as i3;

class SharedDrift extends i1.ModularAccessor {
  SharedDrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<AllPostsResult> allPosts({required AllPosts$limit limit}) {
    var $arrayStartIndex = 1;
    final generatedlimit = $write(
        limit(this.posts, alias(this.users, 'author')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT"posts"."author" AS "nested_0.author", "posts"."content" AS "nested_0.content","author"."id" AS "nested_1.id", "author"."name" AS "nested_1.name" FROM posts INNER JOIN users AS author ON author.id = posts.author ${generatedlimit.sql}',
        variables: [
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          posts,
          users,
          ...generatedlimit.watchedTables,
        }).asyncMap((i0.QueryRow row) async => AllPostsResult(
          posts: await posts.mapFromRow(row, tablePrefix: 'nested_0'),
          author: await users.mapFromRow(row, tablePrefix: 'nested_1'),
        ));
  }

  i2.Posts get posts => this.resultSet<i2.Posts>('posts');
  i3.$UsersTable get users => this.resultSet<i3.$UsersTable>('users');
}

class AllPostsResult {
  final i2.Post posts;
  final i3.User author;
  AllPostsResult({
    required this.posts,
    required this.author,
  });
}

typedef AllPosts$limit = i0.Limit Function(
    i2.Posts posts, i3.$UsersTable author);
