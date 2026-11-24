import 'package:drift3_preview/drift.dart';
import 'package:drift3_remote/src/client.dart';
import 'package:drift3_remote/src/generated/drift.pbgrpc.dart' as gen;
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:grpc/grpc.dart';

part 'client.g.dart';

class Messages extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get content => text();
}

@DriftDatabase(tables: [Messages])
final class ChatDatabase(super.implementation) extends _$ChatDatabase {
  @override
  int get schemaVersion => 1;
}

void main() async {
  final db = ChatDatabase(
    serverConnection(SqliteDialect.new, () async {
      final channel = ClientChannel(
        'localhost',
        port: 50051,
        options: ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          codecRegistry: CodecRegistry(
            codecs: const [GzipCodec(), IdentityCodec()],
          ),
        ),
      );
      return gen.DatabaseServiceClient(channel);
    }),
  );

  db.messagesQueries.all().watch().listen((messages) {
    print('All messages: $messages');
  });

  await db.messagesQueries.insertOne(
    MessagesCompanion.insert(content: 'New client at ${DateTime.now()}'),
  );
}
