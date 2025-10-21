// The entrypoint for the **server** environment.
//
// The [main] method will only be executed on the server during pre-rendering.
// To run code on the client, use the @client annotation.

// Server-specific jaspr import.
import 'package:jaspr/server.dart';

import 'package:jaspr_content/jaspr_content.dart';

// This file is generated automatically by Jaspr, do not remove or edit.
import 'jaspr_options.dart';
import 'src/common.dart';
import 'src/components/inherited_page.dart';

void main() {
  // Initializes the server environment with the generated default options.
  Jaspr.initializeApp(
    options: JasprOptions(
      clients: defaultJasprOptions.clients,
      styles: () => [],
    ),
  );

  final fsLoader = driftWebsiteLoader();
  runApp(
    InheritedPageResolver(
      loader: fsLoader,
      child: ContentApp.custom(
        loaders: [fsLoader],
        configResolver: driftPageConfig(),
      ),
    ),
  );
}
