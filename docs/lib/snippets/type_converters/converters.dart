// #docregion start
import 'dart:convert';

import 'package:drift/drift.dart';

class Preferences {
  bool receiveEmails;
  String selectedTheme;

  Preferences(this.receiveEmails, this.selectedTheme);

  String toJson() => json.encode({
        'receiveEmails': receiveEmails,
        'selectedTheme': selectedTheme,
      });

  factory Preferences.fromJson(String source) {
    final map = json.decode(source) as Map<String, dynamic>;
    return Preferences(
      map['receiveEmails'] as bool,
      map['selectedTheme'] as String,
    );
  }

  @override
  bool operator ==(covariant Preferences other) {
    if (identical(this, other)) return true;

    return other.receiveEmails == receiveEmails &&
        other.selectedTheme == selectedTheme;
  }

  @override
  int get hashCode => receiveEmails.hashCode ^ selectedTheme.hashCode;

  // #enddocregion start

  // #docregion simplified
  static TypeConverter<Preferences, String> converter = TypeConverter.json(
    fromJson: (json) => Preferences.fromJson(json as String),
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
    return Preferences.fromJson(fromDb);
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
