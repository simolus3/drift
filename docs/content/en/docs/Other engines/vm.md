---
title: Dart VM
description: An upcoming version will have a version for the Dart VM
---

An upcoming version of moor will have first class support for the Dart VM, 
so you can use moor on Desktop Flutter applications or Dart apps.

We're going to use the `dart:ffi` feature for that, which itself is an
experimental state at the moment. We already have a version of moor that
runs on the Dart VM (see [#76](https://github.com/simolus3/moor/issues/76))
and we're going to release it when `dart:ffi` becomes stable.