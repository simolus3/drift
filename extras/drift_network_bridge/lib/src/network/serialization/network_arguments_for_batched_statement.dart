import 'dart:convert';

import 'package:drift/src/runtime/executor/executor.dart';
import 'package:json_annotation/json_annotation.dart';

part 'network_arguments_for_batched_statement.g.dart';

@JsonSerializable(explicitToJson: true)
class NetworkArgumentsForBatchedStatement {

  /// Index of the sql statement in the [BatchedStatements.statements] of the
  /// [BatchedStatements] containing this argument set.
  final int statementIndex;

  /// Bound arguments for the referenced statement.
  final List<Object?> arguments;

  NetworkArgumentsForBatchedStatement(this.statementIndex, this.arguments);

  factory NetworkArgumentsForBatchedStatement.fromDrift(ArgumentsForBatchedStatement arguments) => NetworkArgumentsForBatchedStatement(arguments.statementIndex, arguments.arguments);

  factory NetworkArgumentsForBatchedStatement.fromJson(
      Map<String, dynamic> json) =>
      _$NetworkArgumentsForBatchedStatementFromJson(json);

  Map<String, dynamic> toJson() =>
      _$NetworkArgumentsForBatchedStatementToJson(this);

  String toJsonString() => jsonEncode(toJson());

  ArgumentsForBatchedStatement toDrift()  => ArgumentsForBatchedStatement(statementIndex, arguments);
}