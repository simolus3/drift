import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../platform_specific.dart';

/// In the table of contents section, sets an `.active` class on the current
/// section that auto-updates as the window is scrolled.
@client
final class ActiveAnchors extends StatefulComponent {
  @override
  State<StatefulComponent> createState() {
    if (kIsWeb) {
      return _AnchorsState();
    } else {
      return _ServerAnchorsState();
    }
  }
}

final class _AnchorsState extends State<ActiveAnchors> {
  @override
  void initState() {
    super.initState();

    final node = context.node as web.Element;
    final links = node.querySelectorAll('li > a');
    final allLinks = <web.HTMLAnchorElement>[];
    final targetToLink = <web.HTMLElement, web.HTMLAnchorElement>{};
    web.HTMLAnchorElement? active;

    for (var i = 0; i < links.length; i++) {
      final link = links.item(i)! as web.HTMLAnchorElement;
      final name = Uri.parse(link.href).fragment;
      if (web.document.getElementById(name) case web.HTMLElement element) {
        allLinks.add(link);
        targetToLink[element] = link;
      }
    }

    web.EventStreamProviders.scrollEvent.forTarget(web.window).listen((_) {
      // Find the last heading with a negative y offset (meaning the user has
      // scrolled past it).
      web.HTMLAnchorElement? scrolledPast;

      for (final MapEntry(:key, :value) in targetToLink.entries) {
        final rect = key.getBoundingClientRect();

        if (rect.top < 50) {
          scrolledPast = value;
        } else {
          break;
        }
      }

      if (scrolledPast != active) {
        for (final link in allLinks) {
          if (link == active) {
            link.classList.remove('active');
          } else if (link == scrolledPast) {
            link.classList.add('active');
          }
        }

        active = scrolledPast;
      }
    });
  }

  @override
  Component build(BuildContext context) {
    return const Component.empty();
  }
}

final class _ServerAnchorsState extends State<ActiveAnchors> {
  @override
  Component build(BuildContext context) {
    return const Component.empty();
  }
}
