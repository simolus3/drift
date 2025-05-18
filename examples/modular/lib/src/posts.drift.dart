// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:modular/src/posts.drift.dart' as i1;

class Posts extends i0.Table
    with i0.ResultSet<i1.Post, Posts>
    implements i0.GeneratedTable<i1.Post, Posts> {
  @override
  final String? alias;
  Posts([this.alias]);
  late final i0.TableColumn<int> id = i0.TableColumn<int>(
      name: 'id',
      type: i0.BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () => [i0.ColumnConstraint.customSql('PRIMARY KEY')])
    ..owningResultSet = this;
  late final i0.TableColumn<int> author = i0.TableColumn<int>(
      name: 'author',
      type: i0.BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () =>
          [i0.ColumnConstraint.customSql('NOT NULL REFERENCES users(id)')])
    ..owningResultSet = this;
  late final i0.TableColumn<String> content = i0.TableColumn<String>(
      name: 'content',
      type: i0.BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: () => [i0.ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns => [id, author, content];
  @override
  String get entityName => $name;
  static const String $name = 'posts';
  @override
  Posts asSelfType() => this;

  @override
  Set<i0.TableColumn> get primaryKey => {id};
  @override
  i1.Post? Function(i0.DriftRow) createMapperFromPositions(
      List<i0.ColumnPosition> positions) {
    return (i0.DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return i1.Post(
        id: row.readWithType(positions[0], i0.BuiltinDriftType.int)!,
        author: row.readWithType(positions[1], i0.BuiltinDriftType.int)!,
        content: row.readWithType(positions[2], i0.BuiltinDriftType.text),
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
  final int id;
  final int author;
  final String? content;
  const Post({required this.id, required this.author, this.content});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['author'] = i0.Variable<int>(author);
    if (!nullToAbsent || content != null) {
      map['content'] = i0.Variable<String>(content);
    }
    return map;
  }

  i1.PostsCompanion toCompanion(bool nullToAbsent) {
    return i1.PostsCompanion(
      id: i0.Value(id),
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
      id: serializer.fromJson<int>(json['id']),
      author: serializer.fromJson<int>(json['author']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'author': serializer.toJson<int>(author),
      'content': serializer.toJson<String?>(content),
    };
  }

  i1.Post copyWith(
          {int? id,
          int? author,
          i0.Value<String?> content = const i0.Value.absent()}) =>
      i1.Post(
        id: id ?? this.id,
        author: author ?? this.author,
        content: content.present ? content.value : this.content,
      );
  Post copyWithCompanion(i1.PostsCompanion data) {
    return Post(
      id: data.id.present ? data.id.value : this.id,
      author: data.author.present ? data.author.value : this.author,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Post(')
          ..write('id: $id, ')
          ..write('author: $author, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, author, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Post &&
          other.id == this.id &&
          other.author == this.author &&
          other.content == this.content);
}

class PostsCompanion extends i0.UpdateCompanion<i1.Post> {
  final i0.Value<int> id;
  final i0.Value<int> author;
  final i0.Value<String?> content;
  const PostsCompanion({
    this.id = const i0.Value.absent(),
    this.author = const i0.Value.absent(),
    this.content = const i0.Value.absent(),
  });
  PostsCompanion.insert({
    this.id = const i0.Value.absent(),
    required int author,
    this.content = const i0.Value.absent(),
  }) : author = i0.Value(author);
  static i0.Insertable<i1.Post> custom({
    i0.Expression<int>? id,
    i0.Expression<int>? author,
    i0.Expression<String>? content,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (author != null) 'author': author,
      if (content != null) 'content': content,
    });
  }

  i1.PostsCompanion copyWith(
      {i0.Value<int>? id, i0.Value<int>? author, i0.Value<String?>? content}) {
    return i1.PostsCompanion(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (author.present) {
      map['author'] = i0.Variable<int>(author.value);
    }
    if (content.present) {
      map['content'] = i0.Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostsCompanion(')
          ..write('id: $id, ')
          ..write('author: $author, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class Likes extends i0.Table
    with i0.ResultSet<i1.Like, Likes>
    implements i0.GeneratedTable<i1.Like, Likes> {
  @override
  final String? alias;
  Likes([this.alias]);
  late final i0.TableColumn<int> post = i0.TableColumn<int>(
      name: 'post',
      type: i0.BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () =>
          [i0.ColumnConstraint.customSql('NOT NULL REFERENCES posts(id)')])
    ..owningResultSet = this;
  late final i0.TableColumn<int> likedBy = i0.TableColumn<int>(
      name: 'liked_by',
      type: i0.BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () =>
          [i0.ColumnConstraint.customSql('NOT NULL REFERENCES users(id)')])
    ..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns => [post, likedBy];
  @override
  String get entityName => $name;
  static const String $name = 'likes';
  @override
  Likes asSelfType() => this;

  @override
  Set<i0.TableColumn> get primaryKey => const {};
  @override
  i1.Like? Function(i0.DriftRow) createMapperFromPositions(
      List<i0.ColumnPosition> positions) {
    return (i0.DriftRow row) {
      // Not part of row if non-nullable column "post" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return i1.Like(
        post: row.readWithType(positions[0], i0.BuiltinDriftType.int)!,
        likedBy: row.readWithType(positions[1], i0.BuiltinDriftType.int)!,
      );
    };
  }

  @override
  Likes withAlias(String alias) {
    return Likes(alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Like extends i0.LegacyDataClass implements i0.Insertable<i1.Like> {
  final int post;
  final int likedBy;
  const Like({required this.post, required this.likedBy});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['post'] = i0.Variable<int>(post);
    map['liked_by'] = i0.Variable<int>(likedBy);
    return map;
  }

  i1.LikesCompanion toCompanion(bool nullToAbsent) {
    return i1.LikesCompanion(
      post: i0.Value(post),
      likedBy: i0.Value(likedBy),
    );
  }

  factory Like.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Like(
      post: serializer.fromJson<int>(json['post']),
      likedBy: serializer.fromJson<int>(json['liked_by']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'post': serializer.toJson<int>(post),
      'liked_by': serializer.toJson<int>(likedBy),
    };
  }

  i1.Like copyWith({int? post, int? likedBy}) => i1.Like(
        post: post ?? this.post,
        likedBy: likedBy ?? this.likedBy,
      );
  Like copyWithCompanion(i1.LikesCompanion data) {
    return Like(
      post: data.post.present ? data.post.value : this.post,
      likedBy: data.likedBy.present ? data.likedBy.value : this.likedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Like(')
          ..write('post: $post, ')
          ..write('likedBy: $likedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(post, likedBy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Like &&
          other.post == this.post &&
          other.likedBy == this.likedBy);
}

class LikesCompanion extends i0.UpdateCompanion<i1.Like> {
  final i0.Value<int> post;
  final i0.Value<int> likedBy;
  final i0.Value<int> rowid;
  const LikesCompanion({
    this.post = const i0.Value.absent(),
    this.likedBy = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  LikesCompanion.insert({
    required int post,
    required int likedBy,
    this.rowid = const i0.Value.absent(),
  })  : post = i0.Value(post),
        likedBy = i0.Value(likedBy);
  static i0.Insertable<i1.Like> custom({
    i0.Expression<int>? post,
    i0.Expression<int>? likedBy,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (post != null) 'post': post,
      if (likedBy != null) 'liked_by': likedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.LikesCompanion copyWith(
      {i0.Value<int>? post, i0.Value<int>? likedBy, i0.Value<int>? rowid}) {
    return i1.LikesCompanion(
      post: post ?? this.post,
      likedBy: likedBy ?? this.likedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (post.present) {
      map['post'] = i0.Variable<int>(post.value);
    }
    if (likedBy.present) {
      map['liked_by'] = i0.Variable<int>(likedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LikesCompanion(')
          ..write('post: $post, ')
          ..write('likedBy: $likedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
