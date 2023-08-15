import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'network_statement.g.dart';

@JsonSerializable(explicitToJson: true)
class NetworkStatement {
  final String statement;
  final List<Object?> args;

  NetworkStatement(this.statement, this.args);

  factory NetworkStatement.fromJson(Map<String, dynamic> json) =>
      _$NetworkStatementFromJson(json);

  Map<String, dynamic> toJson() => _$NetworkStatementToJson(this);

  String toJsonString() => jsonEncode(toJson());

  factory NetworkStatement.fromJsonString(String json) =>
      NetworkStatement.fromJson(jsonDecode(json));
}