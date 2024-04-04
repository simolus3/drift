import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show Color;

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().withLength(min: 1, max: 50)();
  DateTimeColumn get releaseDate => dateTime()();
  IntColumn get color => integer().map(const ColorConverter())();
}

class Listings extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName("listings")
  IntColumn get product => integer().references(Products, #id)();
  @ReferenceName("listings")
  IntColumn get store => integer().references(Store, #id)();
  RealColumn get price => real()();
}

class Store extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  @ReferenceName("stores")
  IntColumn get owner => integer().references(Owner, #id)();
}

class Owner extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
}

class ColorConverter extends TypeConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromSql(int fromDb) => Color(fromDb);

  @override
  int toSql(Color value) => value.value;
}
