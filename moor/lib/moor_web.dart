/// A version of moor that runs on the web by using [sql.js](https://github.com/kripken/sql.js)
/// You manually need to include that library into your website to use the
/// web version of moor.
@experimental
library moor_web;

import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:js';

import 'package:meta/meta.dart';
import 'package:meta/dart2js.dart';

import 'moor.dart';

export 'moor.dart';

part 'src/web/sql_js.dart';
