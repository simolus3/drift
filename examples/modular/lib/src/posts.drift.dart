// ignore_for_file: type=lint, invalid_use_of_internal_member
import 'package:drift/drift.dart' as i0;
import 'package:modular/src/posts.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;
import 'package:modular/src/users.drift.dart' as i3;

class Posts extends i0.Table with i0.TableInfo<Posts, i1.Post> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Posts(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'PRIMARY KEY');
  static const i0.VerificationMeta _authorMeta =
      const i0.VerificationMeta('author');
  late final i0.GeneratedColumn<int> author = i0.GeneratedColumn<int>(
      'author', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES users(id)');
  static const i0.VerificationMeta _contentMeta =
      const i0.VerificationMeta('content');
  late final i0.GeneratedColumn<String> content = i0.GeneratedColumn<String>(
      'content', aliasedName, true,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<i0.GeneratedColumn> get $columns => [id, author, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'posts';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i1.Post> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.Post map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Post(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      author: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}author'])!,
      content: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}content']),
    );
  }

  @override
  Posts createAlias(String alias) {
    return Posts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Post extends i0.DataClass implements i0.Insertable<i1.Post> {
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

class $PostsFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.Posts> {
  $PostsFilterComposer(super.$state);
  i0.ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));
  i3.$UsersFilterComposer get author {
    final i3.$UsersFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.author,
        referencedTable:
            i2.ReadDatabaseContainer($state.db).resultSet<i3.Users>('users'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => i3.$UsersFilterComposer(
            i0.ComposerState(
                $state.db,
                i2.ReadDatabaseContainer($state.db)
                    .resultSet<i3.Users>('users'),
                joinBuilder,
                parentComposers)));
    return composer;
  }

  i0.ColumnFilters<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));
}

class $PostsOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.Posts> {
  $PostsOrderingComposer(super.$state);
  i0.ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));
  i3.$UsersOrderingComposer get author {
    final i3.$UsersOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.author,
        referencedTable:
            i2.ReadDatabaseContainer($state.db).resultSet<i3.Users>('users'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => i3.$UsersOrderingComposer(
            i0.ComposerState(
                $state.db,
                i2.ReadDatabaseContainer($state.db)
                    .resultSet<i3.Users>('users'),
                joinBuilder,
                parentComposers)));
    return composer;
  }

  i0.ColumnOrderings<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $PostsProcessedTableManager extends i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.Posts,
    i1.Post,
    $PostsFilterComposer,
    $PostsOrderingComposer,
    $PostsProcessedTableManager,
    $PostsInsertCompanionBuilder,
    $PostsUpdateCompanionBuilder> {
  const $PostsProcessedTableManager(super.$state);
}

typedef $PostsInsertCompanionBuilder = i1.PostsCompanion Function({
  i0.Value<int> id,
  required int author,
  i0.Value<String?> content,
});
typedef $PostsUpdateCompanionBuilder = i1.PostsCompanion Function({
  i0.Value<int> id,
  i0.Value<int> author,
  i0.Value<String?> content,
});

class $PostsTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.Posts,
    i1.Post,
    $PostsFilterComposer,
    $PostsOrderingComposer,
    $PostsProcessedTableManager,
    $PostsInsertCompanionBuilder,
    $PostsUpdateCompanionBuilder> {
  $PostsTableManager(i0.GeneratedDatabase db, i1.Posts table)
      : super(i0.TableManagerState(
            db: db,
            table: table,
            filteringComposer:
                $PostsFilterComposer(i0.ComposerState(db, table)),
            orderingComposer:
                $PostsOrderingComposer(i0.ComposerState(db, table)),
            getChildManagerBuilder: (p0) => $PostsProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              i0.Value<int> id = const i0.Value.absent(),
              i0.Value<int> author = const i0.Value.absent(),
              i0.Value<String?> content = const i0.Value.absent(),
            }) =>
                i1.PostsCompanion(
                  id: id,
                  author: author,
                  content: content,
                ),
            getInsertCompanionBuilder: ({
              i0.Value<int> id = const i0.Value.absent(),
              required int author,
              i0.Value<String?> content = const i0.Value.absent(),
            }) =>
                i1.PostsCompanion.insert(
                  id: id,
                  author: author,
                  content: content,
                )));
}

class Likes extends i0.Table with i0.TableInfo<Likes, i1.Like> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Likes(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _postMeta =
      const i0.VerificationMeta('post');
  late final i0.GeneratedColumn<int> post = i0.GeneratedColumn<int>(
      'post', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES posts(id)');
  static const i0.VerificationMeta _likedByMeta =
      const i0.VerificationMeta('likedBy');
  late final i0.GeneratedColumn<int> likedBy = i0.GeneratedColumn<int>(
      'liked_by', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES users(id)');
  @override
  List<i0.GeneratedColumn> get $columns => [post, likedBy];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'likes';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i1.Like> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('post')) {
      context.handle(
          _postMeta, post.isAcceptableOrUnknown(data['post']!, _postMeta));
    } else if (isInserting) {
      context.missing(_postMeta);
    }
    if (data.containsKey('liked_by')) {
      context.handle(_likedByMeta,
          likedBy.isAcceptableOrUnknown(data['liked_by']!, _likedByMeta));
    } else if (isInserting) {
      context.missing(_likedByMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  i1.Like map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Like(
      post: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}post'])!,
      likedBy: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}liked_by'])!,
    );
  }

  @override
  Likes createAlias(String alias) {
    return Likes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Like extends i0.DataClass implements i0.Insertable<i1.Like> {
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

class $LikesFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.Likes> {
  $LikesFilterComposer(super.$state);
  i1.$PostsFilterComposer get post {
    final i1.$PostsFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.post,
        referencedTable:
            i2.ReadDatabaseContainer($state.db).resultSet<i1.Posts>('posts'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => i1.$PostsFilterComposer(
            i0.ComposerState(
                $state.db,
                i2.ReadDatabaseContainer($state.db)
                    .resultSet<i1.Posts>('posts'),
                joinBuilder,
                parentComposers)));
    return composer;
  }

  i3.$UsersFilterComposer get likedBy {
    final i3.$UsersFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.likedBy,
        referencedTable:
            i2.ReadDatabaseContainer($state.db).resultSet<i3.Users>('users'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => i3.$UsersFilterComposer(
            i0.ComposerState(
                $state.db,
                i2.ReadDatabaseContainer($state.db)
                    .resultSet<i3.Users>('users'),
                joinBuilder,
                parentComposers)));
    return composer;
  }
}

class $LikesOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.Likes> {
  $LikesOrderingComposer(super.$state);
  i1.$PostsOrderingComposer get post {
    final i1.$PostsOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.post,
        referencedTable:
            i2.ReadDatabaseContainer($state.db).resultSet<i1.Posts>('posts'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => i1.$PostsOrderingComposer(
            i0.ComposerState(
                $state.db,
                i2.ReadDatabaseContainer($state.db)
                    .resultSet<i1.Posts>('posts'),
                joinBuilder,
                parentComposers)));
    return composer;
  }

  i3.$UsersOrderingComposer get likedBy {
    final i3.$UsersOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.likedBy,
        referencedTable:
            i2.ReadDatabaseContainer($state.db).resultSet<i3.Users>('users'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => i3.$UsersOrderingComposer(
            i0.ComposerState(
                $state.db,
                i2.ReadDatabaseContainer($state.db)
                    .resultSet<i3.Users>('users'),
                joinBuilder,
                parentComposers)));
    return composer;
  }
}

class $LikesProcessedTableManager extends i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.Likes,
    i1.Like,
    $LikesFilterComposer,
    $LikesOrderingComposer,
    $LikesProcessedTableManager,
    $LikesInsertCompanionBuilder,
    $LikesUpdateCompanionBuilder> {
  const $LikesProcessedTableManager(super.$state);
}

typedef $LikesInsertCompanionBuilder = i1.LikesCompanion Function({
  required int post,
  required int likedBy,
  i0.Value<int> rowid,
});
typedef $LikesUpdateCompanionBuilder = i1.LikesCompanion Function({
  i0.Value<int> post,
  i0.Value<int> likedBy,
  i0.Value<int> rowid,
});

class $LikesTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.Likes,
    i1.Like,
    $LikesFilterComposer,
    $LikesOrderingComposer,
    $LikesProcessedTableManager,
    $LikesInsertCompanionBuilder,
    $LikesUpdateCompanionBuilder> {
  $LikesTableManager(i0.GeneratedDatabase db, i1.Likes table)
      : super(i0.TableManagerState(
            db: db,
            table: table,
            filteringComposer:
                $LikesFilterComposer(i0.ComposerState(db, table)),
            orderingComposer:
                $LikesOrderingComposer(i0.ComposerState(db, table)),
            getChildManagerBuilder: (p0) => $LikesProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              i0.Value<int> post = const i0.Value.absent(),
              i0.Value<int> likedBy = const i0.Value.absent(),
              i0.Value<int> rowid = const i0.Value.absent(),
            }) =>
                i1.LikesCompanion(
                  post: post,
                  likedBy: likedBy,
                  rowid: rowid,
                ),
            getInsertCompanionBuilder: ({
              required int post,
              required int likedBy,
              i0.Value<int> rowid = const i0.Value.absent(),
            }) =>
                i1.LikesCompanion.insert(
                  post: post,
                  likedBy: likedBy,
                  rowid: rowid,
                )));
}
