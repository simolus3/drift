// #docregion existing
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:json_annotation/json_annotation.dart';

// #enddocregion existing
import 'package:drift/native.dart';

part 'json.g.dart';

// #docregion existing
@JsonSerializable()
class ContactData {
  final String name;
  final List<String> phoneNumbers;

  ContactData(this.name, this.phoneNumbers);

  factory ContactData.fromJson(Map<String, Object?> json) =>
      _$ContactDataFromJson(json);

  Map<String, Object?> toJson() => _$ContactDataToJson(this);
}
// #enddocregion existing

// #docregion contacts
class _ContactsConverter extends TypeConverter<ContactData, String> {
  @override
  ContactData fromSql(String fromDb) {
    return ContactData.fromJson(json.decode(fromDb) as Map<String, Object?>);
  }

  @override
  String toSql(ContactData value) {
    return json.encode(value.toJson());
  }
}

class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get data => text().map(_ContactsConverter())();

  TextColumn get name => text().generatedAs(data.jsonExtract(r'$.name'))();
}
// #enddocregion contacts

// #docregion calls
class Calls extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get incoming => boolean()();
  TextColumn get phoneNumber => text()();
  DateTimeColumn get callTime => dateTime()();
}
// #enddocregion calls

@DriftDatabase(tables: [Contacts, Calls])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  // #docregion calls-with-contacts
  Future<List<(Call, Contact)>> callsWithContact() async {
    final phoneNumbersForContact =
        contacts.data.jsonEach(this, r'$.phoneNumbers');
    final phoneNumberQuery = selectOnly(phoneNumbersForContact)
      ..addColumns([phoneNumbersForContact.value]);

    final query = select(calls).join(
        [innerJoin(contacts, calls.phoneNumber.isInQuery(phoneNumberQuery))]);

    return query
        .map((row) => (row.readTable(calls), row.readTable(contacts)))
        .get();
  }
  // #enddocregion calls-with-contacts
}
