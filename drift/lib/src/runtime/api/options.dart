import '../types/mapping.dart';

class DriftDatabaseOptions {
  final SqlTypes types;

  DriftDatabaseOptions({
    bool storeDateTimeAsText = false,
  }) : types = SqlTypes(storeDateTimeAsText);
}
