// This file must not be moved, as the devtools extension will try to look up
// types in this exact library.
// ignore_for_file: public_member_api_docs
@internal
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:meta/meta.dart';

import '../api/runtime_api.dart';
import 'service_extension.dart';
import 'shared.dart';

const _releaseMode = bool.fromEnvironment('dart.vm.product');
const _profileMode = bool.fromEnvironment('dart.vm.profile');

// Avoid pulling in a bunch of unused code to describe databases and to make
// them available through service extensions on release builds.
const _enable = !_releaseMode && !_profileMode;

void postEvent(String type, Map<Object?, Object?> data) {
  developer.postEvent('drift:$type', data);
}

void _postChangedEvent() {
  postEvent('database-list-changed', {});
}

class TrackedDatabase {
  final GeneratedDatabase database;
  final int id;

  TrackedDatabase(this.database) : id = _nextId++ {
    byDatabase[database] = this;
    all.add(this);
  }

  static int _nextId = 0;

  static List<TrackedDatabase> all = [];
  static final Expando<TrackedDatabase> byDatabase = Expando();
}

void handleCreated(GeneratedDatabase database) {
  if (_enable) {
    TrackedDatabase(database);
    DriftServiceExtension.registerIfNeeded();
    _postChangedEvent();
  }
}

String describe(GeneratedDatabase database) {
  return json.encode(DatabaseDescription.fromDrift(database));
}
