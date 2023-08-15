import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';

import 'network_arguments_for_batched_statement.dart';

part 'network_batched_statement.g.dart';

@JsonSerializable(explicitToJson: true)
class NetworkBatchedStatement {
  final List<String> statements;

  /// Stores which sql statement should be run with what arguments.
  final List<NetworkArgumentsForBatchedStatement> arguments;

  // TODO: add class properties and constructor parameters
  NetworkBatchedStatement(this.statements, this.arguments);
  factory NetworkBatchedStatement.fromDrift(BatchedStatements batch) =>
      NetworkBatchedStatement(batch.statements, batch.arguments.map((e) => NetworkArgumentsForBatchedStatement.fromDrift(e)).toList());

  factory NetworkBatchedStatement.fromJson(Map<String, dynamic> json) =>
      _$NetworkBatchedStatementFromJson(json);

  Map<String, dynamic> toJson() => _$NetworkBatchedStatementToJson(this);

  String toJsonString() => jsonEncode(toJson());

  factory NetworkBatchedStatement.fromJsonString(String bytesToStringAsString) =>
      NetworkBatchedStatement.fromJson(jsonDecode(bytesToStringAsString));

  BatchedStatements toDrift() => BatchedStatements(statements, arguments.map((e) => e.toDrift()).toList());
}