/// A version of moor that runs on the web by using [sql.js](https://github.com/sql-js/sql.js)
/// You manually need to include that library into your website to use the
/// web version of moor. See [the documentation](https://moor.simonbinder.eu/web)
/// for a more detailed instruction.
@experimental
library moor_web;

import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:js';

import 'package:meta/meta.dart';

import 'backends.dart';
import 'moor.dart';
import 'src/web/binary_string_conversion.dart';
import 'src/web/sql_js.dart';

part 'src/web/storage.dart';
part 'src/web/web_db.dart';
