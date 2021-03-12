---
data:
  title: "Using SQL"
  weight: 30
  description: Write typesafe sql with moor
template: layouts/docs/list
---

Moor let's you express a variety of queries in pure Dart. However, you don't have to miss out
on its features when you need more complex queries or simply prefer sql. Moor has a builtin
sql parser and analyzer, so it can generate a typesafe API for sql statements you write.
It can also warn about errors in your sql at build time.