// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/jaspr.dart';
import 'package:drift_website/src/components/anchors.dart' as prefix0;
import 'package:drift_website/src/components/modal.dart' as prefix1;
import 'package:drift_website/src/components/search_input.dart' as prefix2;
import 'package:drift_website/src/components/web_compatibility.dart' as prefix3;
import 'package:drift_website/src/search/component.dart' as prefix4;
import 'package:jaspr_content_snippets/internal/client.dart' as prefix5;
import 'package:jaspr_docsy/components/internal/sidebar_toggle.dart' as prefix6;
import 'package:jaspr_docsy/components/internal/tabs.dart' as prefix7;

/// Default [JasprOptions] for use with your jaspr project.
///
/// Use this to initialize jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'jaspr_options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultJasprOptions,
///   );
///
///   runApp(...);
/// }
/// ```
JasprOptions get defaultJasprOptions => JasprOptions(
  clients: {
    prefix0.ActiveAnchors: ClientTarget<prefix0.ActiveAnchors>(
      'src/components/anchors',
    ),

    prefix1.Backdrop: ClientTarget<prefix1.Backdrop>('src/components/modal'),

    prefix2.DriftSearchInput: ClientTarget<prefix2.DriftSearchInput>(
      'src/components/search_input',
    ),

    prefix3.WebCompatibilityCheck: ClientTarget<prefix3.WebCompatibilityCheck>(
      'src/components/web_compatibility',
    ),

    prefix4.SearchModal: ClientTarget<prefix4.SearchModal>(
      'src/search/component',
    ),

    prefix5.CodeBlockCopyButton: ClientTarget<prefix5.CodeBlockCopyButton>(
      'jaspr_content_snippets:internal/client',
    ),

    prefix6.MobileSidebarToggle: ClientTarget<prefix6.MobileSidebarToggle>(
      'jaspr_docsy:components/internal/sidebar_toggle',
      params: _prefix6MobileSidebarToggle,
    ),

    prefix7.InternalTabHeaders: ClientTarget<prefix7.InternalTabHeaders>(
      'jaspr_docsy:components/internal/tabs',
      params: _prefix7InternalTabHeaders,
    ),
  },
  styles: () => [],
);

Map<String, dynamic> _prefix6MobileSidebarToggle(
  prefix6.MobileSidebarToggle c,
) => {'target': c.target};
Map<String, dynamic> _prefix7InternalTabHeaders(prefix7.InternalTabHeaders c) =>
    {'items': c.items};
