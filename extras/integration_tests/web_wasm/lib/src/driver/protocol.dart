import 'dart:convert';

import 'package:http/http.dart';

/// An instruction the opened page receives from the test server.
final class Instruction {
  final int id;
  final String method;
  final Object? arguments;

  Instruction({
    required this.id,
    required this.method,
    required this.arguments,
  });

  factory Instruction.fromJson(Map<String, Object?> json) {
    return Instruction(
      id: json['id'] as int,
      method: json['method'] as String,
      arguments: json['arguments'],
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'method': method,
    'arguments': arguments,
  };
}

final class InstructionComplete {
  final int id;
  final Object? result;

  InstructionComplete({required this.id, this.result});

  factory InstructionComplete.fromJson(Map<String, Object?> json) {
    return InstructionComplete(id: json['id'] as int, result: json['result']);
  }

  Map<String, Object?> toJson() => {'id': id, 'result': result};
}

final class ClientError {
  final int? id;
  final String message;
  final String trace;

  ClientError({required this.id, required this.message, required this.trace});

  factory ClientError.fromJson(Map<String, Object?> json) {
    return ClientError(
      id: json['id'] as int?,
      message: json['message'] as String,
      trace: json['trace'] as String,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'message': message,
    'trace': trace,
  };
}

final class ClientPrint {
  final int clientId;
  final String message;

  ClientPrint({required this.clientId, required this.message});

  factory ClientPrint.fromJson(Map<String, Object?> json) {
    return ClientPrint(
      clientId: json['client'] as int,
      message: json['message'] as String,
    );
  }

  Map<String, Object?> toJson() => {'client': clientId, 'message': message};
}

final class TestClient {
  final Client client;

  TestClient(this.client);

  Stream<Instruction> instructions(int clientId) async* {
    final response = await client.send(
      Request('GET', Uri.parse('/instructions?client=$clientId')),
    );

    yield* response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => Instruction.fromJson(json.decode(line)));
  }

  Future<void> postCompletion(InstructionComplete ok) async {
    await client.post(Uri.parse('/complete'), body: json.encode(ok.toJson()));
  }

  Future<void> postError(ClientError error) async {
    await client.post(Uri.parse('/error'), body: json.encode(error.toJson()));
  }

  Future<void> print(ClientPrint print) async {
    await client.post(Uri.parse('/print'), body: json.encode(print.toJson()));
  }
}
