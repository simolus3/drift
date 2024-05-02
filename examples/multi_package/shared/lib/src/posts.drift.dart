// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:shared/src/posts.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;
import 'package:shared/src/users.drift.dart' as i3;

class Posts extends i0.Table with i0.TableInfo<Posts, i1.Post> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Posts(this.attachedDatabase, [this._alias]);
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
  List<i0.GeneratedColumn> get $columns => [author, content];
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
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  i1.Post map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Post(
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
  final int author;
  final String? content;
  const Post({required this.author, this.content});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['author'] = i0.Variable<int>(author);
    if (!nullToAbsent || content != null) {
      map['content'] = i0.Variable<String>(content);
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
      map['author'] = i0.Variable<int>(author.value);
    }
    if (content.present) {
      map['content'] = i0.Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
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

class $PostsFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.Posts> {
  $PostsFilterComposer(super.$state);
  i3.$$UsersTableFilterComposer get author {
    final i3.$$UsersTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.author,
        referencedTable: i2.ReadDatabaseContainer($state.db)
            .resultSet<i3.$UsersTable>('users'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            i3.$$UsersTableFilterComposer(i0.ComposerState(
                $state.db,
                i2.ReadDatabaseContainer($state.db)
                    .resultSet<i3.$UsersTable>('users'),
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
  i3.$$UsersTableOrderingComposer get author {
    final i3.$$UsersTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.author,
        referencedTable: i2.ReadDatabaseContainer($state.db)
            .resultSet<i3.$UsersTable>('users'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            i3.$$UsersTableOrderingComposer(i0.ComposerState(
                $state.db,
                i2.ReadDatabaseContainer($state.db)
                    .resultSet<i3.$UsersTable>('users'),
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
  $PostsReferenceReader withReferences() {
    return $PostsReferenceReader(this);
  }
}

typedef $PostsInsertCompanionBuilder = i1.PostsCompanion Function({
  required int author,
  i0.Value<String?> content,
  i0.Value<int> rowid,
});
typedef $PostsUpdateCompanionBuilder = i1.PostsCompanion Function({
  i0.Value<int> author,
  i0.Value<String?> content,
  i0.Value<int> rowid,
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
              i0.Value<int> author = const i0.Value.absent(),
              i0.Value<String?> content = const i0.Value.absent(),
              i0.Value<int> rowid = const i0.Value.absent(),
            }) =>
                i1.PostsCompanion(
                  author: author,
                  content: content,
                  rowid: rowid,
                ),
            getInsertCompanionBuilder: ({
              required int author,
              i0.Value<String?> content = const i0.Value.absent(),
              i0.Value<int> rowid = const i0.Value.absent(),
            }) =>
                i1.PostsCompanion.insert(
                  author: author,
                  content: content,
                  rowid: rowid,
                )));
  $PostsReferenceReader withReferences() {
    return $PostsReferenceReader(this);
  }
}

class $PostsReferenceReader<T0>
    extends i0.ReferenceReader<i1.Post, ({i1.Post post, T0? author})> {
  $PostsReferenceReader(this.$manager);
  i0.GeneratedDatabase get _db => $manager.$state.db as i0.GeneratedDatabase;
  final i0.BaseTableManager $manager;
  @override
  Future<({i1.Post post, T0? author})> $withReferences(i1.Post value) async {
    return (post: value, author: await _getAuthor(value));
  }

  Future<T0?> _getAuthor(i1.Post value) async {
    return $getSingleReferenced<i3.User>(value.author, _db.users.id) as T0?;
  }

  $PostsReferenceReader<i3.User> withAuthor() {
    return $PostsReferenceReader(this.$manager);
  }
}
