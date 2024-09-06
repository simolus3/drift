---
data:
  title: "Backend synchronization"
  description: Approaches for syncing drift databases between clients and backends.
template: layouts/docs/single
---

At its core, drift is a package to access relational databases. On clients, that would
typically be a SQLite3 database, which is what drift is optimized for.
More recently, drift also gained stable support for [PostgreSQL databases]({{ '../Platforms/postgres.md' | pageUrl }}) as well.
This allows drift to be deployed in [fullstack Dart applications](https://github.com/simolus3/drift/tree/develop/examples/multi_package),
where a server uses drift to talk to a Postgres database and clients use it to manage a sqlite3 database.
Thanks to utilities like [DialectAwareSqlType](https://pub.dev/documentation/drift/latest/drift/DialectAwareSqlType-class.html),
it is also possible to share schema definitions between the two database systems.

But regardless of whether the backend is using drift or not, synchronizing data between frontend and
backend services can be complex.
It is not something drift is set up to do automatically, but drift can integrate with existing solutions
enabling synchronization.
This page lists a few options and how they can be integrated into drift.
If you have experience with alternatives that you can share, please feel free to open an issue or contribute
to this page!

## Manual

One approach that requires more work to configure, but also gives you the most flexibility, is to write
most of the synchronization logic yourself.

For instance, synchronizing changes made locally in the app could be tracked in additional tables - perhaps
with a `CREATE TRIGGER` statement keeping a log of changes made to database tables you want to sync.
Periodically, a background job could then post this log of changes to your backend server.

Dominik Roszkowski has given a [talk at Fluttercon 2023](https://www.droidcon.com/2023/08/06/from-network-failures-to-offline-success-a-journey-of-visible-app/)
in which he shares the approach used by Visible to sync local changes to the server.
Additional approaches are also discussed in [this issue](https://github.com/simolus3/drift/issues/136) and
[here](https://github.com/simolus3/drift/discussions/2880).

## ElectricSQL

[ElectricSQL](https://electric-sql.com/) is a solution you can self-host to synchronize PostgreSQL databases
with clients.
Instead of having to deal with changes manually, a service receives updates from the PostgreSQL server and
local sqlite3 databases. This service takes care of all the synchronization logic, with no backend changes
and only simple frontend changes being required to integrate this.

There is no official Dart support yet, but there are [community bindings](https://github.com/SkillDevs/electric_dart)
which have great support for drift databases.
This even works with stream queries - writes happening in the backend are quickly synchronized to the frontend,
and will update the UI right away.

[This example](https://github.com/SkillDevs/electric_dart/tree/master/todos_flutter) contains a Flutter app
and a simple backend, both using drift and synchronizing their database with ElectricSQL.
