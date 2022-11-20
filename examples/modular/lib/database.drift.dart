// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:modular/src/users.drift.dart' as i1;
import 'package:modular/src/posts.drift.dart' as i2;
import 'package:modular/src/search.drift.dart' as i3;
import 'package:drift/internal/modular.dart' as i4;

abstract class $Database extends i0.GeneratedDatabase {
  $Database(i0.QueryExecutor e) : super(e);
  late final i1.Users users = i1.Users(this);
  late final i2.Posts posts = i2.Posts(this);
  late final i3.SearchInPosts searchInPosts = i3.SearchInPosts(this);
  late final i2.Likes likes = i2.Likes(this);
  late final i1.Follows follows = i1.Follows(this);
  i1.UsersDrift get usersDrift =>
      i4.ReadDatabaseContainer(this).accessor<i1.UsersDrift>(i1.UsersDrift.new);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        posts,
        searchInPosts,
        i3.postsInsert,
        i3.postsUpdate,
        i3.postsDelete,
        likes,
        follows
      ];
  @override
  i0.StreamQueryUpdateRules get streamUpdateRules =>
      const i0.StreamQueryUpdateRules(
        [
          i0.WritePropagation(
            on: i0.TableUpdateQuery.onTableName('posts',
                limitUpdateKind: i0.UpdateKind.insert),
            result: [
              i0.TableUpdate('search_in_posts', kind: i0.UpdateKind.insert),
            ],
          ),
          i0.WritePropagation(
            on: i0.TableUpdateQuery.onTableName('posts',
                limitUpdateKind: i0.UpdateKind.update),
            result: [
              i0.TableUpdate('search_in_posts', kind: i0.UpdateKind.insert),
            ],
          ),
          i0.WritePropagation(
            on: i0.TableUpdateQuery.onTableName('posts',
                limitUpdateKind: i0.UpdateKind.delete),
            result: [
              i0.TableUpdate('search_in_posts', kind: i0.UpdateKind.insert),
            ],
          ),
        ],
      );
  @override
  i0.DriftDatabaseOptions get options =>
      const i0.DriftDatabaseOptions(storeDateTimeAsText: true);
}
