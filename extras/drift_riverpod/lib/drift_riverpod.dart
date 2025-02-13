/// Utilities for integrating drift into an application that uses riverpod for
/// state management.
library;

import 'package:riverpod/riverpod.dart' as riverpod show ProviderListenable;

export 'src/annotation.dart';
export 'src/selectable_provider.dart';

/// Used as a target for generated extensions.
typedef DatabaseProvider<T> = riverpod.ProviderListenable<T>;
