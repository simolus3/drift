## Drift3 remote access

Drift 3 no longer has `package:drift/remote.dart` to access databases over a
custom communication channel.
However, it has become much easier to implement custom database drivers.

This example shows how to host a drift database through gRPC while preserving
reactive queries.

- `protos/drift.proto` defines the protocol.
- `lib/src/client.dart` implements a `DriftSession` over a gRPC stub.
- `lib/src/server.dart` exposes any `DriftSession` through gRPC.

This is a minimal demo, real deployments would also track which session is
owned by which client to close it when the connection is dropped.

To run it, first run `dart run example/server.dart` in this directory.
Then, run `dart run example/client.dart` (multiple times if you like), and see
queries updating in real time.

To re-generate code, run

```
dart pub global activate protoc_plugin
protoc --dart_out=grpc:lib/src/generated -Iprotos protos/drift.proto
dart run build_runner build
```
