// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:modular/src/search.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;
import 'package:modular/src/posts.drift.dart' as i3;

class SearchInPosts extends i0.Table
    with i0.ResultSet<i1.SearchInPost, SearchInPosts>
    implements
        i0.GeneratedTable<i1.SearchInPost, SearchInPosts>,
        i0.VirtualTableInfo<i1.SearchInPost, SearchInPosts> {
  @override
  final String? alias;
  SearchInPosts([this.alias]);
  late final i0.TableColumn<String> author = i0.TableColumn<String>(
      name: 'author',
      type: i0.BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () => [i0.ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  late final i0.TableColumn<String> content = i0.TableColumn<String>(
      name: 'content',
      type: i0.BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () => [i0.ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns => [author, content];
  @override
  String get entityName => $name;
  static const String $name = 'search_in_posts';
  @override
  SearchInPosts asSelfType() => this;

  @override
  Set<i0.TableColumn> get primaryKey => const {};
  @override
  i1.SearchInPost? Function(i0.DriftRow) createMapperFromPositions(
      List<i0.ColumnPosition> positions) {
    return (i0.DriftRow row) {
      // Not part of row if non-nullable column "author" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return i1.SearchInPost(
        author: row.readWithType(positions[0], i0.BuiltinDriftType.text)!,
        content: row.readWithType(positions[1], i0.BuiltinDriftType.text)!,
      );
    };
  }

  @override
  SearchInPosts withAlias(String alias) {
    return SearchInPosts(alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(author, content, content=posts, content_rowid=id)';
}

class SearchInPost extends i0.LegacyDataClass
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

i0.Trigger get postsInsert => i0.Trigger(
    'posts_insert',
    i0.CustomComponent(
        'CREATE TRIGGER posts_insert AFTER INSERT ON posts BEGIN INSERT INTO search_in_posts ("rowid", author, content) VALUES (new.id, new.author, new.content);END'));
i0.Trigger get postsUpdate => i0.Trigger(
    'posts_update',
    i0.CustomComponent(
        'CREATE TRIGGER posts_update AFTER UPDATE ON posts BEGIN INSERT INTO search_in_posts (search_in_posts, "rowid", author, content) VALUES (\'delete\', old.id, old.author, old.content);INSERT INTO search_in_posts ("rowid", author, content) VALUES (new.id, new.author, new.content);END'));
i0.Trigger get postsDelete => i0.Trigger(
    'posts_delete',
    i0.CustomComponent(
        'CREATE TRIGGER posts_delete AFTER DELETE ON posts BEGIN INSERT INTO search_in_posts (search_in_posts, "rowid", author, content) VALUES (\'delete\', old.id, old.author, old.content);END'));

class SearchDrift extends i2.ModularAccessor {
  SearchDrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<i3.Post> search(String var1) {
    return customSelectMapped<i3.Post>(
        query:
            'WITH relevant_ports AS (SELECT "rowid" FROM search_in_posts WHERE search_in_posts MATCH ?1) SELECT posts.id AS _c0, posts.author AS _c1, posts.content AS _c2 FROM relevant_ports AS results INNER JOIN posts ON id = results."rowid"',
        variables: [(dialect.textType, var1)],
        readsFrom: {
          searchInPosts,
          posts,
        },
        createMapper: (i0.DriftResultSet resultSet) {
          final map_0 = posts.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
          ]);

          return (i0.DriftRow row) => map_0(row)!;
        });
  }

  i1.SearchInPosts get searchInPosts =>
      i2.ReadDatabaseContainer(attachedDatabase)
          .resultSet<i1.SearchInPosts>('search_in_posts');
  i3.Posts get posts =>
      i2.ReadDatabaseContainer(attachedDatabase).resultSet<i3.Posts>('posts');
}
