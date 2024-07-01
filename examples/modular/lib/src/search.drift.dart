// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:modular/src/search.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;
import 'package:modular/src/posts.drift.dart' as i3;

class SearchInPosts extends i0.Table
    with
        i0.TableInfo<SearchInPosts, i1.SearchInPost>,
        i0.VirtualTableInfo<SearchInPosts, i1.SearchInPost> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  SearchInPosts(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _authorMeta =
      const i0.VerificationMeta('author');
  late final i0.GeneratedColumn<String> author = i0.GeneratedColumn<String>(
      'author', aliasedName, false,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: '');
  static const i0.VerificationMeta _contentMeta =
      const i0.VerificationMeta('content');
  late final i0.GeneratedColumn<String> content = i0.GeneratedColumn<String>(
      'content', aliasedName, false,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: '');
  @override
  List<i0.GeneratedColumn> get $columns => [author, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_in_posts';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.SearchInPost> instance,
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
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  i1.SearchInPost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.SearchInPost(
      author: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}author'])!,
      content: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}content'])!,
    );
  }

  @override
  SearchInPosts createAlias(String alias) {
    return SearchInPosts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(author, content, content=posts, content_rowid=id)';
}

class SearchInPost extends i0.DataClass
    implements i0.Insertable<i1.SearchInPost> {
  final String author;
  final String content;
  const SearchInPost({required this.author, required this.content});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['author'] = i0.Variable<String>(author);
    map['content'] = i0.Variable<String>(content);
    return map;
  }

  i1.SearchInPostsCompanion toCompanion(bool nullToAbsent) {
    return i1.SearchInPostsCompanion(
      author: i0.Value(author),
      content: i0.Value(content),
    );
  }

  factory SearchInPost.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return SearchInPost(
      author: serializer.fromJson<String>(json['author']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'author': serializer.toJson<String>(author),
      'content': serializer.toJson<String>(content),
    };
  }

  i1.SearchInPost copyWith({String? author, String? content}) =>
      i1.SearchInPost(
        author: author ?? this.author,
        content: content ?? this.content,
      );
  SearchInPost copyWithCompanion(i1.SearchInPostsCompanion data) {
    return SearchInPost(
      author: data.author.present ? data.author.value : this.author,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchInPost(')
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
      (other is i1.SearchInPost &&
          other.author == this.author &&
          other.content == this.content);
}

class SearchInPostsCompanion extends i0.UpdateCompanion<i1.SearchInPost> {
  final i0.Value<String> author;
  final i0.Value<String> content;
  final i0.Value<int> rowid;
  const SearchInPostsCompanion({
    this.author = const i0.Value.absent(),
    this.content = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  SearchInPostsCompanion.insert({
    required String author,
    required String content,
    this.rowid = const i0.Value.absent(),
  })  : author = i0.Value(author),
        content = i0.Value(content);
  static i0.Insertable<i1.SearchInPost> custom({
    i0.Expression<String>? author,
    i0.Expression<String>? content,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (author != null) 'author': author,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.SearchInPostsCompanion copyWith(
      {i0.Value<String>? author,
      i0.Value<String>? content,
      i0.Value<int>? rowid}) {
    return i1.SearchInPostsCompanion(
      author: author ?? this.author,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (author.present) {
      map['author'] = i0.Variable<String>(author.value);
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
    return (StringBuffer('SearchInPostsCompanion(')
          ..write('author: $author, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

typedef $SearchInPostsCreateCompanionBuilder = i1.SearchInPostsCompanion
    Function({
  required String author,
  required String content,
  i0.Value<int> rowid,
});
typedef $SearchInPostsUpdateCompanionBuilder = i1.SearchInPostsCompanion
    Function({
  i0.Value<String> author,
  i0.Value<String> content,
  i0.Value<int> rowid,
});

class $SearchInPostsFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.SearchInPosts> {
  $SearchInPostsFilterComposer(super.$state);
  i0.ColumnFilters<String> get author => $state.composableBuilder(
      column: $state.table.author,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));
}

class $SearchInPostsOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.SearchInPosts> {
  $SearchInPostsOrderingComposer(super.$state);
  i0.ColumnOrderings<String> get author => $state.composableBuilder(
      column: $state.table.author,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $SearchInPostsTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.SearchInPosts,
    i1.SearchInPost,
    i1.$SearchInPostsFilterComposer,
    i1.$SearchInPostsOrderingComposer,
    $SearchInPostsCreateCompanionBuilder,
    $SearchInPostsUpdateCompanionBuilder,
    (
      i1.SearchInPost,
      i0.BaseWithReferences<i0.GeneratedDatabase, i1.SearchInPost,
          $SearchInPostsPrefetchedData>
    ),
    i1.SearchInPost,
    $SearchInPostsCreatePrefetchedDataCallback,
    $SearchInPostsPrefetchedData> {
  $SearchInPostsTableManager(i0.GeneratedDatabase db, i1.SearchInPosts table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              i1.$SearchInPostsFilterComposer(i0.ComposerState(db, table)),
          orderingComposer:
              i1.$SearchInPostsOrderingComposer(i0.ComposerState(db, table)),
          withReferenceMapper: (p0, p1) =>
              p0.map((e) => (e, i0.BaseWithReferences(db, e, p1))).toList(),
          createPrefetchedDataGetterCallback: () {
            return (db, data) async {
              final managers = data.map((e) => i0.BaseWithReferences(db, e));

              return $SearchInPostsPrefetchedData();
            };
          },
          updateCompanionCallback: ({
            i0.Value<String> author = const i0.Value.absent(),
            i0.Value<String> content = const i0.Value.absent(),
            i0.Value<int> rowid = const i0.Value.absent(),
          }) =>
              i1.SearchInPostsCompanion(
            author: author,
            content: content,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String author,
            required String content,
            i0.Value<int> rowid = const i0.Value.absent(),
          }) =>
              i1.SearchInPostsCompanion.insert(
            author: author,
            content: content,
            rowid: rowid,
          ),
        ));
}

typedef $SearchInPostsProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.SearchInPosts,
    i1.SearchInPost,
    i1.$SearchInPostsFilterComposer,
    i1.$SearchInPostsOrderingComposer,
    $SearchInPostsCreateCompanionBuilder,
    $SearchInPostsUpdateCompanionBuilder,
    (
      i1.SearchInPost,
      i0.BaseWithReferences<i0.GeneratedDatabase, i1.SearchInPost,
          $SearchInPostsPrefetchedData>
    ),
    i1.SearchInPost,
    $SearchInPostsCreatePrefetchedDataCallback,
    $SearchInPostsPrefetchedData>;
typedef $SearchInPostsCreatePrefetchedDataCallback
    = Future<$SearchInPostsPrefetchedData> Function(
            i0.GeneratedDatabase, List<i1.SearchInPost>)
        Function();

class $SearchInPostsPrefetchedData {
  $SearchInPostsPrefetchedData();
}

i0.Trigger get postsInsert => i0.Trigger(
    'CREATE TRIGGER posts_insert AFTER INSERT ON posts BEGIN INSERT INTO search_in_posts ("rowid", author, content) VALUES (new.id, new.author, new.content);END',
    'posts_insert');
i0.Trigger get postsUpdate => i0.Trigger(
    'CREATE TRIGGER posts_update AFTER UPDATE ON posts BEGIN INSERT INTO search_in_posts (search_in_posts, "rowid", author, content) VALUES (\'delete\', old.id, old.author, old.content);INSERT INTO search_in_posts ("rowid", author, content) VALUES (new.id, new.author, new.content);END',
    'posts_update');
i0.Trigger get postsDelete => i0.Trigger(
    'CREATE TRIGGER posts_delete AFTER DELETE ON posts BEGIN INSERT INTO search_in_posts (search_in_posts, "rowid", author, content) VALUES (\'delete\', old.id, old.author, old.content);END',
    'posts_delete');

class SearchDrift extends i2.ModularAccessor {
  SearchDrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<i3.Post> search(String var1) {
    return customSelect(
        'WITH relevant_ports AS (SELECT "rowid" FROM search_in_posts WHERE search_in_posts MATCH ?1) SELECT posts.* FROM relevant_ports AS results INNER JOIN posts ON id = results."rowid"',
        variables: [
          i0.Variable<String>(var1)
        ],
        readsFrom: {
          searchInPosts,
          posts,
        }).asyncMap(posts.mapFromRow);
  }

  i1.SearchInPosts get searchInPosts =>
      i2.ReadDatabaseContainer(attachedDatabase)
          .resultSet<i1.SearchInPosts>('search_in_posts');
  i3.Posts get posts =>
      i2.ReadDatabaseContainer(attachedDatabase).resultSet<i3.Posts>('posts');
}
