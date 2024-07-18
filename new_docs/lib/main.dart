import 'package:web/web.dart';

import 'src/web/announce.dart';

void setupWebsite() {
  document.documentElement!.classList
    ..remove('no-js')
    ..add('js');

  watchAnnouncementBar();
}
