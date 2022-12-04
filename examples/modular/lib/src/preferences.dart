import 'dart:convert';

import 'package:drift/drift.dart';

class Preferences {
  final bool notifyForNewPosts;

  Preferences(this.notifyForNewPosts);
}

class PreferencesConverter extends TypeConverter<Preferences, String>
    with JsonTypeConverter2<Preferences, String, Map<String, Object?>> {
  const PreferencesConverter();

  @override
  Preferences fromSql(String fromDb) {
    return fromJson(json.decode(fromDb));
  }

  @override
  String toSql(Preferences value) {
    return json.encode(toJson(value));
  }

  @override
  Preferences fromJson(Map<String, Object?> json) {
    return Preferences(json['notify_for_new_posts'] as bool);
  }

  @override
  Map<String, Object?> toJson(Preferences value) {
    return {
      'notify_for_new_posts': value.notifyForNewPosts,
    };
  }
}
