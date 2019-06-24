/// A version of moor that runs on the web by using [AlaSQL.js](https://alasql.org/)
/// You manually need to include that library into your website by using
/// ```html
/// <script src="https://cdn.jsdelivr.net/npm/alasql@0.4"></script>
/// ```
@experimental
library moor_web;

import 'dart:async';
import 'dart:convert' show json;
import 'dart:html';
import 'dart:indexed_db';
import 'dart:js';

import 'package:meta/meta.dart';

import 'moor.dart';

export 'moor.dart';

part 'src/web/alasql.dart';
part 'src/web/functions.dart';
