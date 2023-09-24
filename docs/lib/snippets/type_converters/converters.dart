// #docregion start
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart' as j;

part 'converters.g.dart';

@j.JsonSerializable()
class Preferences {
  bool receiveEmails;
  String selectedTheme;

  Preferences(this.receiveEmails, this.selectedTheme);

  factory Preferences.fromJson(Map<String, dynamic> json) =>
      _$PreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$PreferencesToJson(this);
  // #enddocregion start

  // #docregion simplified
  static TypeConverter<Preferences, String> converter = TypeConverter.json(
    fromJson: (json) => Preferences.fromJson(json as Map<String, Object?>),
    toJson: (pref) => pref.toJson(),
  );
  // #enddocregion simplified
  // #docregion start
}
// #enddocregion start

// #docregion converter
// stores preferences as strings
class PreferenceConverter extends TypeConverter<Preferences, String> {
  const PreferenceConverter();

  @override
  Preferences fromSql(String fromDb) {
    return Preferences.fromJson(json.decode(fromDb) as Map<String, dynamic>);
  }

  @override
  String toSql(Preferences value) {
    return json.encode(value.toJson());
  }
}
// #enddocregion converter

// #docregion table
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  TextColumn get preferences =>
      text().map(const PreferenceConverter()).nullable()();
}
// #enddocregion table
