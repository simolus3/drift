import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

final class Collapsible extends StatelessComponent {
  final String title;
  final List<Component> children;

  Collapsible(this.children, {required this.title});

  @override
  Component build(BuildContext context) {
    return details(classes: 'note', [
      summary([text(title)]),
      ...children,
    ]);
  }

  static CustomComponent component() {
    return CustomComponent(
      pattern: 'Collapsible',
      builder: (tag, attrs, children) {
        final title = attrs['title'] ?? '';
        return Collapsible([if (children != null) children], title: title);
      },
    );
  }
}
