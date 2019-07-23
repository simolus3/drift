---
layout: guide
title: Custom databases
nav_order: 8
since: 2.0
permalink: /custom_backend
---

_Note_: This feature is available starting from Moor `2.0`.

# Custom databases
Moor has builtin support for Flutter using the `sqflite` package - it also supports the [web]({{"web" | absolute_url}})
and desktop apps. However, you can also use moor with a different database of your choice. In this guide, you'll learn how
to use Moor with a `mysql` database running on a server and with an encrypted database on a mobile device!

## MySQL
We'll connect to a MySQL server with the `sqljockey5` library, so let's first add that library to the `pubspec.yaml`:
```yaml
dependencies:
  // you'll also need moor, of course
  sqljocky5: ^2.2.0
```