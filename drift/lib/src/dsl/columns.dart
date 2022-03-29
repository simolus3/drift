part of 'dsl.dart';

/// A [KeyAction] can be used on a [BuildColumn.references] clause to describe
/// how updates and deletes to a referenced table should propagate in your
/// database.
///
/// By default, [KeyAction.noAction] will be used.
/// For details, see [the sqlite3 documentation](https://www.sqlite.org/foreignkeys.html#fk_actions).
enum KeyAction {
  /// Set the column to null when the referenced column changes.
  setNull,

  /// Set the column back to its default value when the referenced column
  /// changes.
  setDefault,

  /// Propagate updates and deletes into referencing rows.
  cascade,

  /// Forbid deleting or updating the referenced column in a database if there
  /// are children pointing towards it.
  restrict,

  /// No special action is taken when the parent key is modified or deleted from
  /// the database.
  noAction,
}

/// Base class for columns in sql. Type [T] refers to the type a value of this
/// column will have in Dart.
abstract class Column<T> extends Expression<T> {
  @override
  final Precedence precedence = Precedence.primary;

  /// The (unescaped) name of this column.
  ///
  /// Use [escapedName] to access a name that's escaped in double quotes if
  /// needed.
  String get name;

  /// [name], but escaped if it's an sql keyword.
  String get escapedName => escapeIfNeeded(name);
}

/// A column that stores int values.
typedef IntColumn = Column<int?>;

/// A column that stores boolean values. Booleans will be stored as an integer
/// that can either be 0 (false) or 1 (true).
typedef BoolColumn = Column<bool?>;

/// A column that stores text.
typedef TextColumn = Column<String?>;

/// A column that stores a [DateTime]. Times will be stored as unix timestamp
/// and will thus have a second accuracy.
typedef DateTimeColumn = Column<DateTime?>;

/// A column that stores arbitrary blobs of data as a [Uint8List].
typedef BlobColumn = Column<Uint8List?>;

/// A column that stores floating point numeric values.
typedef RealColumn = Column<double?>;

class _BaseColumnBuilder<T> {}

/// A column builder is used to specify which columns should appear in a table.
/// All of the methods defined in this class and its subclasses are not meant to
/// be called at runtime. Instead, the generator will take a look at your
/// source code (specifically, it will analyze which of the methods you use) to
/// figure out the column structure of a table.
class ColumnBuilder<T> extends _BaseColumnBuilder<T> {}

/// A column builder for virtual, generated columns.
///
/// This is a different class so that some methods are not available
class VirtualColumnBuilder<T> extends _BaseColumnBuilder<T> {}

/// DSL extension to define a column inside a drift table.
extension BuildColumn<T> on ColumnBuilder<T> {
  /// Tells drift to write a custom constraint after this column definition when
  /// writing this column, for instance in a CREATE TABLE statement.
  ///
  /// When no custom constraint is set, columns will be written like this:
  /// `name TYPE NULLABILITY NATIVE_CONSTRAINTS`. Native constraints are used to
  /// enforce that booleans are either 0 or 1 (e.g.
  /// `field BOOLEAN NOT NULL CHECK (field in (0, 1)`). Auto-Increment
  /// columns also make use of the native constraints, as do default values.
  /// If [customConstraint] has been called, the nullability information and
  /// native constraints will never be written. Instead, they will be replaced
  /// with the [constraint]. For example, if you call
  /// `customConstraint('UNIQUE')` on an [IntColumn] named "votes", the
  /// generated column definition will be `votes INTEGER UNIQUE`. Notice how the
  /// nullability information is lost - you'll have to include it in
  /// [constraint] if that is desired.
  ///
  /// This can be used to implement constraints that drift does not (yet)
  /// support (e.g. unique keys, etc.). If you've found a common use-case for
  /// this, it should be considered a limitation of drift itself. Please feel
  /// free to open an issue at https://github.com/simolus3/drift/issues/new to
  /// report that.
  ///
  /// See also:
  /// - https://www.sqlite.org/syntax/column-constraint.html
  /// - [GeneratedColumn.$customConstraints]
  ColumnBuilder<T> customConstraint(String constraint) => _isGenerated();

  /// The column will use this expression when a row is inserted and no value
  /// has been specified.
  ///
  /// Note: Unlike most other methods used to declare tables, the parameter
  /// [e] which denotes the default expression doesn't have to be a Dart
  /// constant.
  /// Particularly, you can use operators like those defined in
  /// [BooleanExpressionOperators] to form expressions here.
  ///
  /// If you need a column that just stores a static default value, you could
  /// use this method with a [Constant]:
  /// ```dart
  /// IntColumn get level => int().withDefault(const Constant(1))();
  /// ```
  ///
  /// See also:
  /// - [Constant], which can be used to model literals that appear in CREATE
  /// TABLE statements.
  /// - [currentDate] and [currentDateAndTime], which are useful expressions to
  /// store the current date/time as a default value.
  ColumnBuilder<T> withDefault(Expression<T> e) => _isGenerated();

  /// Sets a dynamic default value for this column.
  ///
  /// When a row is inserted into the table and no value has been specified for
  /// this column, [onInsert] will be evaluated. Its return value will be used
  /// for the missing column. [onInsert] may return different values when called
  /// multiple times.
  ///
  /// Here's an example using the [uuid](https://pub.dev/packages/uuid) package:
  ///
  /// ```dart
  /// final uuid = Uuid();
  ///
  /// class Pictures extends Table {
  ///   TextColumn get id => text().clientDefault(() => uuid.v4())();
  ///   BlobColumn get rawData => blob();
  ///
  ///   @override
  ///   Set<Column> get primaryKey => {id};
  /// }
  /// ```
  ///
  /// For a default value that's constant, it is more efficient to use
  /// [withDefault] instead. [withDefault] will write the default value into the
  /// generated `CREATE TABLE` statement. The underlying sql engine will then
  /// apply the default value.
  ColumnBuilder<T> clientDefault(T Function() onInsert) => _isGenerated();

  /// Adds a foreign-key reference from this column.
  ///
  /// The [table] type must be a Dart class name defining a drift table.
  /// The [column] must be a Dart symbol with the same name as a column in the
  /// referenced table.
  /// In Dart, symbols can be created by prefixing an identifier with `#`.
  ///
  /// In the following example, a `Books` table keeps a reference to the author
  /// of each book:
  ///
  /// ```dart
  /// class Authors extends Table {
  ///   IntColumn get id => integer().autoIncrement()();
  ///   // ...
  /// }
  ///
  /// class Books extends Table {
  ///   IntColumn get author => integer().references(Authors, #id)();
  /// }
  /// ```
  ///
  /// __Important notice__: In sqlite3, foreign keys are not enabled by default.
  /// When using foreign keys, remember to enable the option in the
  /// [MigrationStrategy.beforeOpen] callback:
  ///
  /// ```dart
  /// beforeOpen: (details) async {
  ///   await customStatement('PRAGMA foreign_keys = ON');
  /// }
  /// ```
  ColumnBuilder<T> references(
    Type table,
    Symbol column, {
    KeyAction? onUpdate,
    KeyAction? onDelete,
  }) {
    _isGenerated();
  }

  /// Declare a generated column.
  ///
  /// Generated columns are backed by an expression, declared with
  /// [generatedAs]:
  ///
  /// ```dart
  /// class Products extends Table {
  ///   TextColumn get name => text()();
  ///
  ///   RealColumn get price => real()();
  ///   RealColumn get discount => real()();
  ///   RealColumn get tax => real()();
  ///   RealColumn get netPrice => real().generatedAs(
  ///     price * (Constant(1) - discount) * (Constant(1) + tax))();
  /// }
  /// ```
  ///
  /// Generated columns can either be `VIRTUAL` (the default) or `STORED`
  /// (enabled with the [stored] parameter). Stored generated columns are
  /// computed on each update and are stored in the database. Virtual columns
  /// consume less space, but are re-computed on each read.
  ///
  /// Generated columns can't be updated or inserted (neither with the Dart API
  /// or though SQL queries), so they are not represented in companions.
  ///
  /// __Important__: When a generated column can be nullable, don't forget to
  /// call [BuildGeneralColumn.nullable] on it to reflect this in the generated
  /// code.
  /// Also, note that generated columns are part of your databases schema and
  /// cannot be updated easily. When changing the [generatedAs] expression for a
  /// column, you need to re-generate the table with a [TableMigration].
  ///
  /// Note that generated columns are only available in sqlite3 version
  /// `3.31.0`. When using `sqlite3_flutter_libs` or a web database, this is not
  /// a problem.
  VirtualColumnBuilder<T> generatedAs(Expression<T?> generatedAs,
          {bool stored = false}) =>
      _isGenerated();
}

/// Column builders available for both virtual and non-virtual columns.
extension BuildGeneralColumn<T> on _BaseColumnBuilder<T> {
  /// By default, the field name will be used as the column name, e.g.
  /// `IntColumn get id = integer()` will have "id" as its associated name.
  /// Columns made up of multiple words are expected to be in camelCase and will
  /// be converted to snake_case (e.g. a getter called accountCreationDate will
  /// result in an SQL column called account_creation_date).
  /// To change this default behavior, use something like
  /// `IntColumn get id = integer((c) => c.named('user_id'))`.
  ///
  /// Note that using [named] __does not__ have an effect on the json key of an
  /// object. To change the json key, annotate this column getter with
  /// [JsonKey].
  ColumnBuilder<T> named(String name) => _isGenerated();

  /// Marks this column as nullable. Nullable columns should not appear in a
  /// primary key. Columns are non-null by default.
  ColumnBuilder<T?> nullable() => _isGenerated();

  /// Uses a custom [converter] to store custom Dart objects in a single column
  /// and automatically mapping them from and to sql.
  ///
  /// An example might look like this:
  /// ```dart
  ///  // this is the custom object with we want to store in a column. It
  ///  // can be as complex as you want it to be
  ///  class MyCustomObject {
  ///   final String data;
  ///   MyCustomObject(this.data);
  /// }
  ///
  /// class CustomConverter extends TypeConverter<MyCustomObject, String> {
  ///   // this class is responsible for turning a custom object into a string.
  ///   // this is easy here, but more complex objects could be serialized using
  ///   // json or any other method of your choice.
  ///   const CustomConverter();
  ///   @override
  ///   MyCustomObject mapToDart(String fromDb) {
  ///     return fromDb == null ? null : MyCustomObject(fromDb);
  ///   }
  ///
  ///   @override
  ///   String mapToSql(MyCustomObject value) {
  ///     return value?.data;
  ///   }
  /// }
  ///
  /// ```
  ///
  /// In that case, you could have a table with this column
  /// ```dart
  /// TextColumn get custom => text().map(const CustomConverter())();
  /// ```
  /// The generated row class will then use a `MyFancyClass` instead of a
  /// `String`, which would usually be used for [Table.text] columns.
  ColumnBuilder<T> map<Dart>(TypeConverter<Dart, T> converter) =>
      _isGenerated();

  /// Turns this column builder into a column. This method won't actually be
  /// called in your code. Instead, the generator will take a look at your
  /// source code to figure out your table structure.
  Column<T> call() => _isGenerated();
}

/// Tells the generator to build an [IntColumn]. See the docs at [ColumnBuilder]
/// for details.
extension BuildIntColumn<T extends int?> on ColumnBuilder<T> {
  /// Enables auto-increment for this column, which will also make this column
  /// the primary key of the table.
  ///
  /// For this reason, you can't use an [autoIncrement] column and also set a
  /// custom [Table.primaryKey] on the same table.
  ColumnBuilder<T> autoIncrement() => _isGenerated();
}

/// Tells the generator to build an [TextColumn]. See the docs at
/// [ColumnBuilder] for details.
extension BuildTextColumn<T extends String?> on ColumnBuilder<T> {
  /// Puts a constraint on the minimum and maximum length of text that can be
  /// stored in this column.
  ///
  /// Both [min] and [max] are inclusive. This constraint will be validated in
  /// Dart, it doesn't have an impact on the database schema. If [min] is not
  /// null and one tries to write a string which [String.length] is
  /// _strictly less_ than [min], an exception will be thrown. Similarly, you
  /// can't insert strings with a length _strictly greater_ than [max].
  ColumnBuilder<T> withLength({int? min, int? max}) => _isGenerated();
}

/// Annotation to use on column getters inside of a [Table] to define the name
/// of the column in the json used by [DataClass.toJson].
///
/// Example:
/// ```dart
/// class Users extends Table {
///   IntColumn get id => integer().autoIncrement()();
///   @JsonKey('user_name')
///   TextColumn get name => text().nullable()();
/// }
/// ```
/// When calling [DataClass.toJson] on a `User` object, the output will be a map
/// with the keys "id" and "user_name". The output would be "id" and "name" if
/// the [JsonKey] annotation was omitted.
class JsonKey {
  /// The key in the json map to use for this [Column]. See the documentation
  /// for [JsonKey] for details.
  final String key;

  /// An annotation to tell drift how the name of a column should appear in
  /// generated json. See the documentation for [JsonKey] for details.
  const JsonKey(this.key);
}
