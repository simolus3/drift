// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_docs/snippets/modular/many_to_many/shared.drift.dart'
    as i1;
import 'package:drift_docs/snippets/modular/many_to_many/shared.dart' as i2;

class $BuyableItemsTable extends i2.BuyableItems
    with i0.TableInfo<$BuyableItemsTable, i1.BuyableItem> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuyableItemsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const i0.VerificationMeta _descriptionMeta =
      const i0.VerificationMeta('description');
  @override
  late final i0.GeneratedColumn<String> description =
      i0.GeneratedColumn<String>('description', aliasedName, false,
          type: i0.DriftSqlType.string, requiredDuringInsert: true);
  static const i0.VerificationMeta _priceMeta =
      const i0.VerificationMeta('price');
  @override
  late final i0.GeneratedColumn<int> price = i0.GeneratedColumn<int>(
      'price', aliasedName, false,
      type: i0.DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<i0.GeneratedColumn> get $columns => [id, description, price];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'buyable_items';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.BuyableItem> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
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
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.BuyableItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.BuyableItem(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      description: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}description'])!,
      price: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}price'])!,
    );
  }

  @override
  $BuyableItemsTable createAlias(String alias) {
    return $BuyableItemsTable(attachedDatabase, alias);
  }
}

class BuyableItem extends i0.DataClass
    implements i0.Insertable<i1.BuyableItem> {
  final int id;
  final String description;
  final int price;
  const BuyableItem(
      {required this.id, required this.description, required this.price});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['description'] = i0.Variable<String>(description);
    map['price'] = i0.Variable<int>(price);
    return map;
  }

  i1.BuyableItemsCompanion toCompanion(bool nullToAbsent) {
    return i1.BuyableItemsCompanion(
      id: i0.Value(id),
      description: i0.Value(description),
      price: i0.Value(price),
    );
  }

  factory BuyableItem.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return BuyableItem(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
      price: serializer.fromJson<int>(json['price']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
      'price': serializer.toJson<int>(price),
    };
  }

  i1.BuyableItem copyWith({int? id, String? description, int? price}) =>
      i1.BuyableItem(
        id: id ?? this.id,
        description: description ?? this.description,
        price: price ?? this.price,
      );
  @override
  String toString() {
    return (StringBuffer('BuyableItem(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, description, price);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.BuyableItem &&
          other.id == this.id &&
          other.description == this.description &&
          other.price == this.price);
}

class BuyableItemsCompanion extends i0.UpdateCompanion<i1.BuyableItem> {
  final i0.Value<int> id;
  final i0.Value<String> description;
  final i0.Value<int> price;
  const BuyableItemsCompanion({
    this.id = const i0.Value.absent(),
    this.description = const i0.Value.absent(),
    this.price = const i0.Value.absent(),
  });
  BuyableItemsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String description,
    required int price,
  })  : description = i0.Value(description),
        price = i0.Value(price);
  static i0.Insertable<i1.BuyableItem> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? description,
    i0.Expression<int>? price,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
    });
  }

  i1.BuyableItemsCompanion copyWith(
      {i0.Value<int>? id,
      i0.Value<String>? description,
      i0.Value<int>? price}) {
    return i1.BuyableItemsCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      price: price ?? this.price,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (description.present) {
      map['description'] = i0.Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = i0.Variable<int>(price.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuyableItemsCompanion(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }
}
