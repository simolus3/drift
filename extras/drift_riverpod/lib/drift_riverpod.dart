/// Utilities for integrating drift into an application that uses riverpod for
/// state management.
library;

import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';

extension Magic<T extends GeneratedDatabase> on ProviderListenable<T> {}
