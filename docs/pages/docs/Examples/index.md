---
data:
  title: "Examples"
  weight: 30
  description: Example apps using drift
template: layouts/docs/list
---

For a full example of a cross-platform Flutter app using drift following best
practices, see [app example](https://github.com/simolus3/drift/tree/develop/examples/app) in drift's repository.
For interested users wanting to take a look at how to use drift in a Flutter app
with a modern architecture, this is perhaps the best example to use as a starting
point.

Drift's repository also contains a number of smaller examples showcasing select
drift features:

- The [encryption] example contains a simple Flutter app using an encrypted drift
  database, powered by the `sqlcipher_flutter_libs` package.
{% comment %}
- [web_worker] and [flutter_web_worker] are small web-only apps using drift in
  a shared web worker, which allows for a real-time synchronization of the
  database across tabs. Of course, this pattern can only be embedded into
  multi-platform apps.
{%- endcomment %}
- The [migration] example makes use of advanced schema migrations and shows how
  to test migrations between different database schemas by using drift's
  [dedicated tooling][migration tooling] for this purpose.
- [Another example][with_built_value] shows how to use drift-generated code in
  other builders (here, `built_value`).

Additional examples from our awesome community are available as well:

- The [clean architecture](https://github.com/rodydavis/clean_architecture_todo_app) example app written by [Rody Davis](https://github.com/rodydavis) shows how to use drift
  in a more complex architecture.
- [Abdelrahman Mostafa Elmarakby](https://github.com/abdelrahmanelmarakby) wrote an animated version of the todo app available [here](https://github.com/abdelrahmanelmarakby/todo_with_moor_and_animation).
- [Abdelrahman Mostafa Elmarakby](https://github.com/abdelrahmanelmarakby) wrote an hotel booking app with GetX version with diffrent relationships available [here](https://github.com/abdelrahmanelmarakby/hotels_booking).
- The [HackerNews reader app](https://github.com/filiph/hn_app) from the [Boring Flutter Show](https://www.youtube.com/playlist?list=PLjxrf2q8roU3ahJVrSgAnPjzkpGmL9Czl)
  also uses drift to keep a list of favorite articles.

If you too have an open-source application using drift, feel free to reach out
and have it added to this list!

If you are interested in seeing more drift examples, or want to contribute more
examples yourself, don't hesitate to open an issue either.
Providing more up-to-date examples would be a much appreciated contribution!

Additional patterns are also shown and explained on this website:

[encryption]: https://github.com/simolus3/drift/tree/develop/examples/encryption
[web_worker]: https://github.com/simolus3/drift/tree/develop/examples/web_worker_example
[flutter_web_worker]: https://github.com/simolus3/drift/tree/develop/examples/flutter_web_worker_example
[migration]: https://github.com/simolus3/drift/tree/develop/examples/migrations_example
[migration tooling]: {{ '../Migrations/tests.md#verifying-migrations' | pageUrl }}
[with_built_value]: https://github.com/simolus3/drift/tree/develop/examples/with_built_value
