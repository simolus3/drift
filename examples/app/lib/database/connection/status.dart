import 'package:riverpod/riverpod.dart';

/// On the web platform, drift may or may not be supported depending on the
/// browser used and whether the user is in an incognito/private window.
///
/// In those cases, we show a warning and fall back to an in-memory database.
final databaseStatusProvider = StateProvider<String?>((ref) => null);
