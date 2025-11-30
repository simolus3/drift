import 'package:jaspr/jaspr.dart';

import '../platform_specific.dart';

@client
final class SearchModal extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return searchModalImpl();
  }
}
