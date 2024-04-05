// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _releaseDateMeta =
      const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<DateTime> releaseDate = GeneratedColumn<DateTime>(
      'release_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumnWithTypeConverter<Color, int> color =
      GeneratedColumn<int>('color', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<Color>($ProductsTable.$convertercolor);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, description, releaseDate, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('release_date')) {
      context.handle(
          _releaseDateMeta,
          releaseDate.isAcceptableOrUnknown(
              data['release_date']!, _releaseDateMeta));
    } else if (isInserting) {
      context.missing(_releaseDateMeta);
    }
    context.handle(_colorMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      releaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}release_date'])!,
      color: $ProductsTable.$convertercolor.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }

  static TypeConverter<Color, int> $convertercolor = const ColorConverter();
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String name;
  final String description;
  final DateTime releaseDate;
  final Color color;
  const Product(
      {required this.id,
      required this.name,
      required this.description,
      required this.releaseDate,
      required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['release_date'] = Variable<DateTime>(releaseDate);
    {
      map['color'] = Variable<int>($ProductsTable.$convertercolor.toSql(color));
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      releaseDate: Value(releaseDate),
      color: Value(color),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      releaseDate: serializer.fromJson<DateTime>(json['releaseDate']),
      color: serializer.fromJson<Color>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'releaseDate': serializer.toJson<DateTime>(releaseDate),
      'color': serializer.toJson<Color>(color),
    };
  }

  Product copyWith(
          {int? id,
          String? name,
          String? description,
          DateTime? releaseDate,
          Color? color}) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        releaseDate: releaseDate ?? this.releaseDate,
        color: color ?? this.color,
      );
  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, releaseDate, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.releaseDate == this.releaseDate &&
          other.color == this.color);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<DateTime> releaseDate;
  final Value<Color> color;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.color = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String description,
    required DateTime releaseDate,
    required Color color,
  })  : name = Value(name),
        description = Value(description),
        releaseDate = Value(releaseDate),
        color = Value(color);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? releaseDate,
    Expression<int>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (releaseDate != null) 'release_date': releaseDate,
      if (color != null) 'color': color,
    });
  }

  ProductsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? description,
      Value<DateTime>? releaseDate,
      Value<Color>? color}) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      releaseDate: releaseDate ?? this.releaseDate,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<DateTime>(releaseDate.value);
    }
    if (color.present) {
      map['color'] =
          Variable<int>($ProductsTable.$convertercolor.toSql(color.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $OwnerTable extends Owner with TableInfo<$OwnerTable, OwnerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'owner';
  @override
  VerificationContext validateIntegrity(Insertable<OwnerData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OwnerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnerData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $OwnerTable createAlias(String alias) {
    return $OwnerTable(attachedDatabase, alias);
  }
}

class OwnerData extends DataClass implements Insertable<OwnerData> {
  final int id;
  final String name;
  const OwnerData({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  OwnerCompanion toCompanion(bool nullToAbsent) {
    return OwnerCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory OwnerData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnerData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  OwnerData copyWith({int? id, String? name}) => OwnerData(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  @override
  String toString() {
    return (StringBuffer('OwnerData(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerData && other.id == this.id && other.name == this.name);
}

class OwnerCompanion extends UpdateCompanion<OwnerData> {
  final Value<int> id;
  final Value<String> name;
  const OwnerCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  OwnerCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<OwnerData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  OwnerCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return OwnerCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnerCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $StoreTable extends Store with TableInfo<$StoreTable, StoreData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<int> owner = GeneratedColumn<int>(
      'owner', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES owner (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, name, owner];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store';
  @override
  VerificationContext validateIntegrity(Insertable<StoreData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner')) {
      context.handle(
          _ownerMeta, owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta));
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoreData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      owner: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}owner'])!,
    );
  }

  @override
  $StoreTable createAlias(String alias) {
    return $StoreTable(attachedDatabase, alias);
  }
}

class StoreData extends DataClass implements Insertable<StoreData> {
  final int id;
  final String name;
  final int owner;
  const StoreData({required this.id, required this.name, required this.owner});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['owner'] = Variable<int>(owner);
    return map;
  }

  StoreCompanion toCompanion(bool nullToAbsent) {
    return StoreCompanion(
      id: Value(id),
      name: Value(name),
      owner: Value(owner),
    );
  }

  factory StoreData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      owner: serializer.fromJson<int>(json['owner']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'owner': serializer.toJson<int>(owner),
    };
  }

  StoreData copyWith({int? id, String? name, int? owner}) => StoreData(
        id: id ?? this.id,
        name: name ?? this.name,
        owner: owner ?? this.owner,
      );
  @override
  String toString() {
    return (StringBuffer('StoreData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('owner: $owner')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, owner);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreData &&
          other.id == this.id &&
          other.name == this.name &&
          other.owner == this.owner);
}

class StoreCompanion extends UpdateCompanion<StoreData> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> owner;
  const StoreCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.owner = const Value.absent(),
  });
  StoreCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int owner,
  })  : name = Value(name),
        owner = Value(owner);
  static Insertable<StoreData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? owner,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (owner != null) 'owner': owner,
    });
  }

  StoreCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<int>? owner}) {
    return StoreCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      owner: owner ?? this.owner,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (owner.present) {
      map['owner'] = Variable<int>(owner.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('owner: $owner')
          ..write(')'))
        .toString();
  }
}

class $ListingsTable extends Listings with TableInfo<$ListingsTable, Listing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _productMeta =
      const VerificationMeta('product');
  @override
  late final GeneratedColumn<int> product = GeneratedColumn<int>(
      'product', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _storeMeta = const VerificationMeta('store');
  @override
  late final GeneratedColumn<int> store = GeneratedColumn<int>(
      'store', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES store (id)'));
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, product, store, price];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listings';
  @override
  VerificationContext validateIntegrity(Insertable<Listing> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product')) {
      context.handle(_productMeta,
          product.isAcceptableOrUnknown(data['product']!, _productMeta));
    } else if (isInserting) {
      context.missing(_productMeta);
    }
    if (data.containsKey('store')) {
      context.handle(
          _storeMeta, store.isAcceptableOrUnknown(data['store']!, _storeMeta));
    } else if (isInserting) {
      context.missing(_storeMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Listing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Listing(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      product: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product'])!,
      store: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}store'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
    );
  }

  @override
  $ListingsTable createAlias(String alias) {
    return $ListingsTable(attachedDatabase, alias);
  }
}

class Listing extends DataClass implements Insertable<Listing> {
  final int id;
  final int product;
  final int store;
  final double price;
  const Listing(
      {required this.id,
      required this.product,
      required this.store,
      required this.price});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product'] = Variable<int>(product);
    map['store'] = Variable<int>(store);
    map['price'] = Variable<double>(price);
    return map;
  }

  ListingsCompanion toCompanion(bool nullToAbsent) {
    return ListingsCompanion(
      id: Value(id),
      product: Value(product),
      store: Value(store),
      price: Value(price),
    );
  }

  factory Listing.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Listing(
      id: serializer.fromJson<int>(json['id']),
      product: serializer.fromJson<int>(json['product']),
      store: serializer.fromJson<int>(json['store']),
      price: serializer.fromJson<double>(json['price']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'product': serializer.toJson<int>(product),
      'store': serializer.toJson<int>(store),
      'price': serializer.toJson<double>(price),
    };
  }

  Listing copyWith({int? id, int? product, int? store, double? price}) =>
      Listing(
        id: id ?? this.id,
        product: product ?? this.product,
        store: store ?? this.store,
        price: price ?? this.price,
      );
  @override
  String toString() {
    return (StringBuffer('Listing(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('store: $store, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, product, store, price);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Listing &&
          other.id == this.id &&
          other.product == this.product &&
          other.store == this.store &&
          other.price == this.price);
}

class ListingsCompanion extends UpdateCompanion<Listing> {
  final Value<int> id;
  final Value<int> product;
  final Value<int> store;
  final Value<double> price;
  const ListingsCompanion({
    this.id = const Value.absent(),
    this.product = const Value.absent(),
    this.store = const Value.absent(),
    this.price = const Value.absent(),
  });
  ListingsCompanion.insert({
    this.id = const Value.absent(),
    required int product,
    required int store,
    required double price,
  })  : product = Value(product),
        store = Value(store),
        price = Value(price);
  static Insertable<Listing> custom({
    Expression<int>? id,
    Expression<int>? product,
    Expression<int>? store,
    Expression<double>? price,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (product != null) 'product': product,
      if (store != null) 'store': store,
      if (price != null) 'price': price,
    });
  }

  ListingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? product,
      Value<int>? store,
      Value<double>? price}) {
    return ListingsCompanion(
      id: id ?? this.id,
      product: product ?? this.product,
      store: store ?? this.store,
      price: price ?? this.price,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (product.present) {
      map['product'] = Variable<int>(product.value);
    }
    if (store.present) {
      map['store'] = Variable<int>(store.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListingsCompanion(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('store: $store, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  _$AppDatabaseManager get managers => _$AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $OwnerTable owner = $OwnerTable(this);
  late final $StoreTable store = $StoreTable(this);
  late final $ListingsTable listings = $ListingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [products, owner, store, listings];
}

class $$ProductsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer(super.db, super.table);
  ColumnFilters<int> get id => ColumnFilters($table.id);
  ColumnFilters<String> get name => ColumnFilters($table.name);
  ColumnFilters<String> get description => ColumnFilters($table.description);
  ColumnFilters<DateTime> get releaseDate => ColumnFilters($table.releaseDate);
  ColumnFilters<int> get colorValue => ColumnFilters($table.color);
  ColumnWithTypeConverterFilters<Color, int> get color =>
      ColumnWithTypeConverterFilters($table.color);
  ComposableFilter listings(
      ComposableFilter Function($$ListingsTableFilterComposer f) f) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: $db.listings,
        getCurrentColumn: (f) => f.id,
        getReferencedColumn: (f) => f.product,
        getReferencedComposer: (db, table) =>
            $$ListingsTableFilterComposer(db, table),
        builder: f);
  }
}

class $$ProductsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer(super.db, super.table);
  ColumnOrderings get id => ColumnOrderings($table.id);
  ColumnOrderings get name => ColumnOrderings($table.name);
  ColumnOrderings get description => ColumnOrderings($table.description);
  ColumnOrderings get releaseDate => ColumnOrderings($table.releaseDate);
  ColumnOrderings get color => ColumnOrderings($table.color);
}

class $$ProductsTableProcessedTableManager extends ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableProcessedTableManager,
    $$ProductsTableInsertCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder> {
  const $$ProductsTableProcessedTableManager(super.$state);
}

typedef $$ProductsTableInsertCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  required String name,
  required String description,
  required DateTime releaseDate,
  required Color color,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> description,
  Value<DateTime> releaseDate,
  Value<Color> color,
});

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableProcessedTableManager,
    $$ProductsTableInsertCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$ProductsTableFilterComposer(db, table),
            orderingComposer: $$ProductsTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$ProductsTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<String> name = const Value.absent(),
              Value<String> description = const Value.absent(),
              Value<DateTime> releaseDate = const Value.absent(),
              Value<Color> color = const Value.absent(),
            }) =>
                ProductsCompanion(
                  id: id,
                  name: name,
                  description: description,
                  releaseDate: releaseDate,
                  color: color,
                ),
            getInsertCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              required String name,
              required String description,
              required DateTime releaseDate,
              required Color color,
            }) =>
                ProductsCompanion.insert(
                  id: id,
                  name: name,
                  description: description,
                  releaseDate: releaseDate,
                  color: color,
                )));
}

class $$OwnerTableFilterComposer
    extends FilterComposer<_$AppDatabase, $OwnerTable> {
  $$OwnerTableFilterComposer(super.db, super.table);
  ColumnFilters<int> get id => ColumnFilters($table.id);
  ColumnFilters<String> get name => ColumnFilters($table.name);
  ComposableFilter stores(
      ComposableFilter Function($$StoreTableFilterComposer f) f) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: $db.store,
        getCurrentColumn: (f) => f.id,
        getReferencedColumn: (f) => f.owner,
        getReferencedComposer: (db, table) =>
            $$StoreTableFilterComposer(db, table),
        builder: f);
  }
}

class $$OwnerTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $OwnerTable> {
  $$OwnerTableOrderingComposer(super.db, super.table);
  ColumnOrderings get id => ColumnOrderings($table.id);
  ColumnOrderings get name => ColumnOrderings($table.name);
}

class $$OwnerTableProcessedTableManager extends ProcessedTableManager<
    _$AppDatabase,
    $OwnerTable,
    OwnerData,
    $$OwnerTableFilterComposer,
    $$OwnerTableOrderingComposer,
    $$OwnerTableProcessedTableManager,
    $$OwnerTableInsertCompanionBuilder,
    $$OwnerTableUpdateCompanionBuilder> {
  const $$OwnerTableProcessedTableManager(super.$state);
}

typedef $$OwnerTableInsertCompanionBuilder = OwnerCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$OwnerTableUpdateCompanionBuilder = OwnerCompanion Function({
  Value<int> id,
  Value<String> name,
});

class $$OwnerTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OwnerTable,
    OwnerData,
    $$OwnerTableFilterComposer,
    $$OwnerTableOrderingComposer,
    $$OwnerTableProcessedTableManager,
    $$OwnerTableInsertCompanionBuilder,
    $$OwnerTableUpdateCompanionBuilder> {
  $$OwnerTableTableManager(_$AppDatabase db, $OwnerTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$OwnerTableFilterComposer(db, table),
            orderingComposer: $$OwnerTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$OwnerTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<String> name = const Value.absent(),
            }) =>
                OwnerCompanion(
                  id: id,
                  name: name,
                ),
            getInsertCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              required String name,
            }) =>
                OwnerCompanion.insert(
                  id: id,
                  name: name,
                )));
}

class $$StoreTableFilterComposer
    extends FilterComposer<_$AppDatabase, $StoreTable> {
  $$StoreTableFilterComposer(super.db, super.table);
  ColumnFilters<int> get id => ColumnFilters($table.id);
  ColumnFilters<String> get name => ColumnFilters($table.name);
  ColumnFilters<int> get ownerId => ColumnFilters($table.owner);
  ComposableFilter owner(
      ComposableFilter Function($$OwnerTableFilterComposer f) f) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: $db.owner,
        getCurrentColumn: (f) => f.owner,
        getReferencedColumn: (f) => f.id,
        getReferencedComposer: (db, table) =>
            $$OwnerTableFilterComposer(db, table),
        builder: f);
  }

  ComposableFilter listings(
      ComposableFilter Function($$ListingsTableFilterComposer f) f) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: $db.listings,
        getCurrentColumn: (f) => f.id,
        getReferencedColumn: (f) => f.store,
        getReferencedComposer: (db, table) =>
            $$ListingsTableFilterComposer(db, table),
        builder: f);
  }
}

class $$StoreTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $StoreTable> {
  $$StoreTableOrderingComposer(super.db, super.table);
  ColumnOrderings get id => ColumnOrderings($table.id);
  ColumnOrderings get name => ColumnOrderings($table.name);
  ColumnOrderings get ownerId => ColumnOrderings($table.owner);
  ComposableOrdering owner(
      ComposableOrdering Function($$OwnerTableOrderingComposer o) o) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: $db.owner,
        getCurrentColumn: (f) => f.owner,
        getReferencedColumn: (f) => f.id,
        getReferencedComposer: (db, table) =>
            $$OwnerTableOrderingComposer(db, table),
        builder: o);
  }
}

class $$StoreTableProcessedTableManager extends ProcessedTableManager<
    _$AppDatabase,
    $StoreTable,
    StoreData,
    $$StoreTableFilterComposer,
    $$StoreTableOrderingComposer,
    $$StoreTableProcessedTableManager,
    $$StoreTableInsertCompanionBuilder,
    $$StoreTableUpdateCompanionBuilder> {
  const $$StoreTableProcessedTableManager(super.$state);
}

typedef $$StoreTableInsertCompanionBuilder = StoreCompanion Function({
  Value<int> id,
  required String name,
  required int owner,
});
typedef $$StoreTableUpdateCompanionBuilder = StoreCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> owner,
});

class $$StoreTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoreTable,
    StoreData,
    $$StoreTableFilterComposer,
    $$StoreTableOrderingComposer,
    $$StoreTableProcessedTableManager,
    $$StoreTableInsertCompanionBuilder,
    $$StoreTableUpdateCompanionBuilder> {
  $$StoreTableTableManager(_$AppDatabase db, $StoreTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$StoreTableFilterComposer(db, table),
            orderingComposer: $$StoreTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$StoreTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<String> name = const Value.absent(),
              Value<int> owner = const Value.absent(),
            }) =>
                StoreCompanion(
                  id: id,
                  name: name,
                  owner: owner,
                ),
            getInsertCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              required String name,
              required int owner,
            }) =>
                StoreCompanion.insert(
                  id: id,
                  name: name,
                  owner: owner,
                )));
}

class $$ListingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ListingsTable> {
  $$ListingsTableFilterComposer(super.db, super.table);
  ColumnFilters<int> get id => ColumnFilters($table.id);
  ColumnFilters<int> get productId => ColumnFilters($table.product);
  ComposableFilter product(
      ComposableFilter Function($$ProductsTableFilterComposer f) f) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: $db.products,
        getCurrentColumn: (f) => f.product,
        getReferencedColumn: (f) => f.id,
        getReferencedComposer: (db, table) =>
            $$ProductsTableFilterComposer(db, table),
        builder: f);
  }

  ColumnFilters<int> get storeId => ColumnFilters($table.store);
  ComposableFilter store(
      ComposableFilter Function($$StoreTableFilterComposer f) f) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: $db.store,
        getCurrentColumn: (f) => f.store,
        getReferencedColumn: (f) => f.id,
        getReferencedComposer: (db, table) =>
            $$StoreTableFilterComposer(db, table),
        builder: f);
  }

  ColumnFilters<double> get price => ColumnFilters($table.price);
}

class $$ListingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ListingsTable> {
  $$ListingsTableOrderingComposer(super.db, super.table);
  ColumnOrderings get id => ColumnOrderings($table.id);
  ColumnOrderings get productId => ColumnOrderings($table.product);
  ComposableOrdering product(
      ComposableOrdering Function($$ProductsTableOrderingComposer o) o) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: $db.products,
        getCurrentColumn: (f) => f.product,
        getReferencedColumn: (f) => f.id,
        getReferencedComposer: (db, table) =>
            $$ProductsTableOrderingComposer(db, table),
        builder: o);
  }

  ColumnOrderings get storeId => ColumnOrderings($table.store);
  ComposableOrdering store(
      ComposableOrdering Function($$StoreTableOrderingComposer o) o) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: $db.store,
        getCurrentColumn: (f) => f.store,
        getReferencedColumn: (f) => f.id,
        getReferencedComposer: (db, table) =>
            $$StoreTableOrderingComposer(db, table),
        builder: o);
  }

  ColumnOrderings get price => ColumnOrderings($table.price);
}

class $$ListingsTableProcessedTableManager extends ProcessedTableManager<
    _$AppDatabase,
    $ListingsTable,
    Listing,
    $$ListingsTableFilterComposer,
    $$ListingsTableOrderingComposer,
    $$ListingsTableProcessedTableManager,
    $$ListingsTableInsertCompanionBuilder,
    $$ListingsTableUpdateCompanionBuilder> {
  const $$ListingsTableProcessedTableManager(super.$state);
}

typedef $$ListingsTableInsertCompanionBuilder = ListingsCompanion Function({
  Value<int> id,
  required int product,
  required int store,
  required double price,
});
typedef $$ListingsTableUpdateCompanionBuilder = ListingsCompanion Function({
  Value<int> id,
  Value<int> product,
  Value<int> store,
  Value<double> price,
});

class $$ListingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ListingsTable,
    Listing,
    $$ListingsTableFilterComposer,
    $$ListingsTableOrderingComposer,
    $$ListingsTableProcessedTableManager,
    $$ListingsTableInsertCompanionBuilder,
    $$ListingsTableUpdateCompanionBuilder> {
  $$ListingsTableTableManager(_$AppDatabase db, $ListingsTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$ListingsTableFilterComposer(db, table),
            orderingComposer: $$ListingsTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$ListingsTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<int> product = const Value.absent(),
              Value<int> store = const Value.absent(),
              Value<double> price = const Value.absent(),
            }) =>
                ListingsCompanion(
                  id: id,
                  product: product,
                  store: store,
                  price: price,
                ),
            getInsertCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              required int product,
              required int store,
              required double price,
            }) =>
                ListingsCompanion.insert(
                  id: id,
                  product: product,
                  store: store,
                  price: price,
                )));
}

class _$AppDatabaseManager {
  final _$AppDatabase _db;
  _$AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$OwnerTableTableManager get owner =>
      $$OwnerTableTableManager(_db, _db.owner);
  $$StoreTableTableManager get store =>
      $$StoreTableTableManager(_db, _db.store);
  $$ListingsTableTableManager get listings =>
      $$ListingsTableTableManager(_db, _db.listings);
}
