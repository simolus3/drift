# Moor ORM
Based on simolus3/moor

With ORM extension you can define model and table declarations in one class!

### Additional features:
- Wrapper class for fields
- Custom enum class
- Global converters

```
@UseMoor(
   tables: [
      Address,
   ],
   converters: {
       Decimal2: Decimal2Converter(),
       Decimal3: Decimal3Converter(),
   },
   foreignKeyConverter: RefConverter(),
   nullableForeignKeyConverter: NullRefConverter(),
   genericConverters: { 
      Val: ValConverter(),
   },
   enumConverters: {
      EnumVal: EnumValConverter<BaseEnum>([]),
   },
)

class AppDatabase extends _$AppDatabase {
    ///....
}

@OrmTable(name: 'countries')
class Country {
  @PrimaryKeyColumn()
  @ColumnDef(ColumnType.integer)
  int? id;

  @ColumnDef(ColumnType.text)
  String name;
  
  @ColumnDef(ColumnType.text)
  final Val<String> nameWrapped;
  
  @EnumColumn()
  final EnumVal<Language> languageWrapped;
  
  @EnumColumn()
  final Language language;

  Country({
    this.id,
    required this.name,
  });
}

@OrmTable(name: 'addresses')
class Address {
  @PrimaryKeyColumn()
  @ColumnDef(ColumnType.integer)
  int? id;
  
  /// ForeignKeyColumn automatically generate constraints
  @ForeignKeyColumn(Country, onUpdate: KeyAction.cascade, onDelete: KeyAction.restrict)
  final Ref<Country> country;
}
```

### Converters
```
/// Generic converter for wrapped types. 
/// Default types (String, int) does not need to catch (-> else)
/// Generic converters require two and only two type argument.

class ValConverter<T extends Object?, D extends Object> extends TypeConverter<Val<T>, D> {
  static final _decimal2Converter = Decimal2Converter();
  static final _decimal3Converter = Decimal3Converter();

  const ValConverter();

  @override
  Val<T>? mapToDart(D? fromDb) {
    final value = (null is T) ? fromDb : fromDb!;
    if (T is Decimal2) {
      return Val<T>(_decimal2Converter.mapToDart(value as int) as T);
    } else if (T is Decimal3) {
      return Val<T>(_decimal3Converter.mapToDart(fromDb as int) as T);
    } else {
      return Val<T>(value as T);
    }
  }

  @override
  D? mapToSql(Val<T>? value) {
    if (T is Decimal2) {
      return _decimal2Converter.mapToSql(value!.value as Decimal2) as D;
    } else if (T is Decimal3) {
      return _decimal3Converter.mapToSql(value!.value as Decimal3) as D;
    } else {
      return value!.value as D;
    }
  }
}

/// For custom enum classes
class EnumValConverter<T extends BaseEnum> extends ForeignKeyConverter<EnumVal<T>> {
  final List<T> _values;

  const EnumValConverter(this._values);

  @override
  EnumVal<T>? mapToDart(int? fromDb) {
    if (null is T) {
      return EnumVal<T>((fromDb == null ? null : _values[fromDb]) as T);
    } else {
      return EnumVal<T>(_values[fromDb!]);
    }
  }

  @override
  int? mapToSql(EnumVal<T>? value) {
    return value!.id;
  }
}

/// You have to define nullable and non-nullable reference wrapper. 
/// NullRef and Ref can't be merged for a strict null checking
class NullRefConverter<T extends BaseModel?> extends ForeignKeyConverter<NullRef<T>> {
  const NullRefConverter();

  @override
  NullRef<T>? mapToDart(int? fromDb) {
    return NullRef(fromDb);
  }

  @override
  int? mapToSql(NullRef<T>? value) {
    return (null is T) ? value!.id! : value!.id;
  }
}

class RefConverter<T extends BaseModel> extends ForeignKeyConverter<Ref<T>> {
  const RefConverter();

  @override
  Ref<T>? mapToDart(int? fromDb) {
    return Ref(fromDb!);
  }

  @override
  int? mapToSql(Ref<T>? value) {
    return value!.id;
  }
}
```

### Custom wrapper types
```
/// These are sample implementations, not part of the package

class Ref<T extends BaseModel> with ValChangeNotifier implements Val<T> {
  T? _value;
  int _id;

  Ref(this._id, {T? value}) : _value = value;

  Ref.withValue(T value) : this(value.id!, value: value);

  int get id => _id;

  @override
  T get value => _value ?? (throw Exception('Foreign key value not loaded'));

  @override
  set value(T value) {
    if (value != _value) {
      _id = value.id!;
      _value = value;
      notifyListeners();
    }
  }

  @override
  String toString() {
    return value.toString();
  }
}

class NullRef<T extends BaseModel?> with ValChangeNotifier implements Val<T?> {
  T? _value;
  int? _id;

  NullRef(this._id, {T? value}) : _value = value;

  NullRef.withValue(T? value) : this(value?.id, value: value);

  int? get id => _id;

  @override
  T? get value => _value;

  @override
  set value(T? value) {
    if (value != _value) {
      _id = value?.id;
      _value = value;
      notifyListeners();
    }
  }

  @override
  String toString() {
    return value.toString();
  }
}

/// Generic value wrapper
class Val<T extends Object?> with ValChangeNotifier {
  T _value;

  Val(this._value);

  T get value => _value;

  set value(T value) {
    if (value != _value) {
      _value = value;
      notifyListeners();
    }
  }

  @override
  String toString() {
    return value.toString();
  }
}

/// Custom enum classes. Enum class requires a "values" static array field

abstract class BaseEnum {
  final int id;
  final String value;

  const BaseEnum(this.id, this.value);

  @override
  String toString() {
    return value;
  }
}

class Language extends BaseEnum {
  static const hungarian = Language(0, 'hungarian');
  static const english = Language(1, 'english');

  static const values = [hungarian, english];

  const Language(int id, String value) : super(id, value);
}
```

## Sample query
```
/// Foreign keys can be loaded easily

final query = select(db.address).join([
  leftOuterJoin(db.country, db.country.id.equalsExp(db.address.country)),
]);

query.map((row) {
  final address = row.readTable(db.address);
  final country = row.readTable(db.country);
  address.country.value = country;
  return address;
});
```

# Moor
[![Build Status](https://api.cirrus-ci.com/github/simolus3/moor.svg)](https://cirrus-ci.com/github/simolus3/moor)
[![codecov](https://codecov.io/gh/simolus3/moor/branch/master/graph/badge.svg)](https://codecov.io/gh/simolus3/moor)
[![Chat on Gitter](https://img.shields.io/gitter/room/moor-dart/community)](https://gitter.im/moor-dart/community)

| Core          | Flutter           | Generator  |
|:-------------:|:-------------:|:-----:|
| [![Generator version](https://img.shields.io/pub/v/moor.svg)](https://pub.dev/packages/moor) | [![Flutter version](https://img.shields.io/pub/v/moor_flutter.svg)](https://pub.dev/packages/moor_flutter) | [![Generator version](https://img.shields.io/pub/v/moor_generator.svg)](https://pub.dev/packages/moor_generator) |

Moor is a reactive persistence library for Flutter and Dart, built ontop of
sqlite. 
Moor is

- __Flexible__: Moor let's you write queries in both SQL and Dart, 
providing fluent apis for both languages. You can filter and order results 
or use joins to run queries on multiple tables. You can even use complex 
sql features like `WITH` and `WINDOW` clauses.
- __🔥 Feature rich__: Moor has builtin support for transactions, schema 
migrations, complex filters and expressions, batched updates and joins. We 
even have a builtin IDE for SQL!
- __📦 Modular__: Thanks to builtin support for daos and `import`s in sql files, moor helps you keep your database code simple.
- __🛡️ Safe__: Moor generates typesafe code based on your tables and queries. If you make a mistake in your queries, moor will find it at compile time and
provide helpful and descriptive lints.
- __⚡ Fast__: Even though moor lets you write powerful queries, it can keep
up with the performance of key-value stores like shared preferences and Hive. Moor is the only major persistence library with builtin threading support, allowing you to run database code across isolates with zero additional effort.
- __Reactive__: Turn any sql query into an auto-updating stream! This includes complex queries across many tables
- __⚙️ Cross-Platform support__: Moor works on Android, iOS, macOS, Windows, Linux and the web. [This template](https://github.com/rodydavis/moor_shared) is a Flutter todo app that works on all platforms
- __🗡️ Battle tested and production ready__: Moor is stable and well tested with a wide range of unit and integration tests. It powers production Flutter apps.

With moor, persistence on Flutter is fun!

__To start using moor, read our detailed [docs](https://moor.simonbinder.eu/docs/getting-started/).__

If you have any questions, feedback or ideas, feel free to [create an
issue](https://github.com/simolus3/moor/issues/new). If you enjoy this
project, I'd appreciate your [🌟 on GitHub](https://github.com/simolus3/moor/).

-----

Packages in this repo:
- `moor`: The main runtime for moor, which provides most apis
- `moor_ffi`: New and faster executor for moor, built with `dart:ffi`.
- `moor_flutter`: The standard executor wrapping the `sqflite` package
- `moor_generator`: The compiler for moor tables, databases and daos. It 
   also contains a fully-featured sql ide
- `sqlparser`: A sql parser and static analyzer, written in pure Dart. This package can be used without moor to perform analysis on sql statements.
It's on pub at 
[![sqlparser](https://img.shields.io/pub/v/sqlparser.svg)](https://pub.dev/packages/sqlparser)
