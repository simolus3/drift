This example shows how to use drift declarations across packages.
It is structured as follows:

- `shared/` contains table definitions. This package does not define a database
  on its own (although that could be useful for testing), instead it declares
  tables used by the server and the client.
- `server/` is a simple shelf server using Postgres with drift.
- `client/` is a simple CLI client using a local sqlite3 database
  while also communicating with the server.

As the main point of this example is to demonstrate how the build
setup could look like, the client and server are kept minimal.

To fully build the code, `build_runner run` needs to be run in all three
packages.
However, after making changes to the database code in one of the packages, only
that package needs to be rebuilt.

## Starting

To run the server, first start a postgres database server:

```
docker run -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres postgres
```

Then, run the example by starting a server and a client:

```
dart run server/bin/server.dart
dart run client/bin/client.dart
```
