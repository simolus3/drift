import 'package:web/web.dart';

NodeList findComponents(String name, [Element? parent]) {
  if (parent != null) {
    return parent.querySelectorAll('[data-md-component=$name]');
  } else {
    return document.querySelectorAll('[data-md-component=$name]');
  }
}

extension NodeListToList on NodeList {
  List<Node?> toList() {
    return List.generate(length, (i) => item(i));
  }
}
