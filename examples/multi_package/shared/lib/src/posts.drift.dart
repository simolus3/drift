// dart format width=80
// ignore_for_file: type=lint
import 'package:drift3_preview/drift.dart' as i0;
import 'package:shared/src/posts.drift.dart' as i1;
import 'package:shared/src/users.drift.dart' as i2;

class Posts extends i0.Table
    with i0.ResultSet<i1.Post, Posts>
    implements i0.GeneratedTable<i1.Post, Posts> {
  @override
  final String? alias;
  Posts([this.alias]);
  late final i0.TableColumn<int> author = i0.TableColumn<int>(
      name: 'author',
      sqlType: i0.SqlType.int,
      requiredDuringInsert: true,
      constraints: () =>
          [i0.ColumnConstraint.customSql('NOT NULL REFERENCES users(id)')])
    ..owningResultSet = this;
  late final i0.TableColumn<String> content = i0.TableColumn<String>(
      name: 'content', sqlType: i0.SqlType.text, requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns => [author, content];
  @override
  String get entityName => $name;
  static const String $name = 'posts';
  @override
  Posts asSelfType() => this;

  @override
  i1.Post? Function(i0.RawRow) createMapperFromPositions(
      i0.DriftDialect dialect, List<i0.ColumnPosition> positions) {
    final pos$author = positions[0].index;
    final type$0 = i0.SqlType.int.resolveIn(dialect);
    final pos$content = positions[1].index;
    final type$1 = i0.SqlType.text.resolveIn(dialect);
    return (i0.RawRow row) {
      // Not part of row if non-nullable column "author" is missing
      if (row[pos$author] == null) {
        return null;
      }
      return i1.Post(
        author: type$0.dartValue(row[pos$author]!),
        content: type$1.nullableDartValue(row[pos$content]),
      );
    };
  }

  @override
  Posts withAlias(String alias) {
    return Posts(alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Post extends i0.LegacyDataClass implements i0.Insertable<i1.Post> {
  final int author;
  final String? content;
  const Post({required this.author, this.content});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['author'] = i0.Variable<int>(author, i0.SqlType.int);
    if (!nullToAbsent || content != null) {
      map['content'] = i0.Variable<String>(content, i0.SqlType.text);
    }
    return map;
  }

  i1.PostsCompanion toCompanion(bool nullToAbsent) {
    return i1.PostsCompanion(
      author: i0.Value(author),
      content: content == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(content),
    );
  }

  factory Post.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Post(
      author: serializer.fromJson<int>(json['author']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'author': serializer.toJson<int>(author),
      'content': serializer.toJson<String?>(content),
    };
  }

  i1.Post copyWith(
          {int? author, i0.Value<String?> content = const i0.Value.absent()}) =>
      i1.Post(
        author: author ?? this.author,
        content: content.present ? content.value : this.content,
      );
  Post copyWithCompanion(i1.PostsCompanion data) {
    return Post(
      author: data.author.present ? data.author.value : this.author,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Post(')
          ..write('author: $author, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(author, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Post &&
          other.author == this.author &&
          other.content == this.content);
}

class PostsCompanion extends i0.UpdateCompanion<i1.Post> {
  final i0.Value<int> author;
  final i0.Value<String?> content;
  final i0.Value<int> rowid;
  const PostsCompanion({
    this.author = const i0.Value.absent(),
    this.content = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  PostsCompanion.insert({
    required int author,
    this.content = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : author = i0.Value(author);
  static i0.Insertable<i1.Post> custom({
    i0.Expression<int>? author,
    i0.Expression<String>? content,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (author != null) 'author': author,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.PostsCompanion copyWith(
      {i0.Value<int>? author,
      i0.Value<String?>? content,
      i0.Value<int>? rowid}) {
    return i1.PostsCompanion(
      author: author ?? this.author,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (author.present) {
      map['author'] = i0.Variable<int>(author.value, i0.SqlType.int);
    }
    if (content.present) {
      map['content'] = i0.Variable<String>(content.value, i0.SqlType.text);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value, i0.SqlType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostsCompanion(')
          ..write('author: $author, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

final class PostsDrift extends i0.DatabaseAccessor {
  PostsDrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<AllPostsResult> allPosts({required AllPosts$limit limit}) {
    var $arrayStartIndex = 0;
    final generatedlimit = $write(
        limit(i1.Posts(), alias(i2.$UsersTable(), 'author')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.variables.length;
    return customSelectMapped<AllPostsResult>(
        query:
            'SELECT"posts"."author", "posts"."content","author"."id", "author"."name" FROM posts INNER JOIN users AS author ON author.id = posts.author ${generatedlimit.buffer}',
        variables: [...generatedlimit.variables],
        readsFrom: {
          i1.Posts(),
          i2.$UsersTable(),
          ...generatedlimit.watchedTables,
        },
        createMapper: (i0.RawResultSet _) {
          final map_0 = i1.Posts().createMapperFromPositions(dialect, const [
            i0.ColumnPosition(0),
            i0.ColumnPosition(1),
          ]);
          final map_1 =
              i2.$UsersTable().createMapperFromPositions(dialect, const [
            i0.ColumnPosition(2),
            i0.ColumnPosition(3),
          ]);

          return (i0.RawRow row) => AllPostsResult(
                posts: map_0(row)!,
                author: map_1(row)!,
              );
        });
  }

  i1.Posts get posts => i1.Posts();
  i2.$UsersTable get users => i2.$UsersTable();
}

final class AllPostsResult {
  final i1.Post posts;
  final i2.User author;
  AllPostsResult({
    required this.posts,
    required this.author,
  });
}

typedef AllPosts$limit = i0.Limit Function(
    i1.Posts posts, i2.$UsersTable author);
