// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// SallyGenerator
// **************************************************************************

class Product {
  final int id;
  final String name;
  Product({this.id, this.name});
}

class _$ProductsTable extends Products implements TableInfo<Products, Product> {
  final GeneratedDatabase db;
  _$ProductsTable(this.db);
  @override
  IntColumn get id => GeneratedIntColumn('products_id', false);
  @override
  TextColumn get name => GeneratedTextColumn('name', false);
  @override
  List<Column> get $columns => [id, name];
  @override
  Products get asDslTable => this;
  @override
  String get $tableName => 'products';
  @override
  Set<Column> get $primaryKey => Set();
  @override
  Product map(Map<String, dynamic> data) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Product(
      id: intType.mapFromDatabaseResponse(data['products_id']),
      name: stringType.mapFromDatabaseResponse(data['name']),
    );
  }
}

class User {
  final int id;
  final String name;
  User({this.id, this.name});
}

class _$UsersTable extends Users implements TableInfo<Users, User> {
  final GeneratedDatabase db;
  _$UsersTable(this.db);
  @override
  IntColumn get id => GeneratedIntColumn('id', false);
  @override
  TextColumn get name => GeneratedTextColumn('name', false);
  @override
  List<Column> get $columns => [id, name];
  @override
  Users get asDslTable => this;
  @override
  String get $tableName => 'users';
  @override
  Set<Column> get $primaryKey => Set();
  @override
  User map(Map<String, dynamic> data) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return User(
      id: intType.mapFromDatabaseResponse(data['id']),
      name: stringType.mapFromDatabaseResponse(data['name']),
    );
  }
}

abstract class _$ShopDb extends GeneratedDatabase {
  _$ShopDb() : super(const SqlTypeSystem.withDefaults(), null);
  _$ProductsTable get products => _$ProductsTable(this);
  _$UsersTable get users => _$UsersTable(this);
}
