// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// SallyGenerator
// **************************************************************************

class ProductsData {
  final int id;
  final String name;
  ProductsData({this.id, this.name});
}

class _$ProductsTable extends Products
    implements TableInfo<Products, ProductsData> {
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
  ProductsData map(Map<String, dynamic> data) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return ProductsData(
      id: intType.mapFromDatabaseResponse(data['products_id']),
      name: stringType.mapFromDatabaseResponse(data['name']),
    );
  }
}

class UsersData {
  final int id;
  final String name;
  UsersData({this.id, this.name});
}

class _$UsersTable extends Users implements TableInfo<Users, UsersData> {
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
  UsersData map(Map<String, dynamic> data) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return UsersData(
      id: intType.mapFromDatabaseResponse(data['id']),
      name: stringType.mapFromDatabaseResponse(data['name']),
    );
  }
}
