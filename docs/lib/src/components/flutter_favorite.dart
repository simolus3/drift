import 'package:jaspr/jaspr.dart';

final class FlutterFavoriteIcon extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return div(classes: 'row favorite', [
      a(
        classes: 'justify-content-end',
        href: 'https://docs.flutter.dev/packages-and-plugins/favorites',
        [
          img(classes: 'light', src: '/images/ff_light.png'),
          img(classes: 'dark', src: '/images/ff_dark.png'),
        ],
      ),
    ]);
  }
}
