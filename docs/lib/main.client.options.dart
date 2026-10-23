// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:drift_website/src/components/anchors.dart' deferred as _anchors;
import 'package:drift_website/src/components/modal.dart' deferred as _modal;
import 'package:drift_website/src/components/search_input.dart'
    deferred as _search_input;
import 'package:drift_website/src/components/web_compatibility.dart'
    deferred as _web_compatibility;
import 'package:drift_website/src/search/component.dart' deferred as _component;
import 'package:jaspr_content_snippets/internal/client.dart'
    deferred as _client;
import 'package:jaspr_docsy/components/internal/sidebar_toggle.dart'
    deferred as _sidebar_toggle;
import 'package:jaspr_docsy/components/internal/tabs.dart' deferred as _tabs;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'anchors': ClientLoader(
      (p) => _anchors.ActiveAnchors(),
      loader: _anchors.loadLibrary,
    ),
    'modal': ClientLoader((p) => _modal.Backdrop(), loader: _modal.loadLibrary),
    'search_input': ClientLoader(
      (p) => _search_input.DriftSearchInput(),
      loader: _search_input.loadLibrary,
    ),
    'web_compatibility': ClientLoader(
      (p) => _web_compatibility.WebCompatibilityCheck(),
      loader: _web_compatibility.loadLibrary,
    ),
    'component': ClientLoader(
      (p) => _component.SearchModal(),
      loader: _component.loadLibrary,
    ),
    'jaspr_content_snippets:client': ClientLoader(
      (p) => _client.CodeBlockCopyButton(),
      loader: _client.loadLibrary,
    ),
    'jaspr_docsy:sidebar_toggle': ClientLoader(
      (p) =>
          _sidebar_toggle.MobileSidebarToggle(target: p.get<String>('target')),
      loader: _sidebar_toggle.loadLibrary,
    ),
    'jaspr_docsy:tabs': ClientLoader(
      (p) => _tabs.InternalTabHeaders(
        items: p.get<Map<String, Object?>>('items').cast<String, String>(),
      ),
      loader: _tabs.loadLibrary,
    ),
  },
);
