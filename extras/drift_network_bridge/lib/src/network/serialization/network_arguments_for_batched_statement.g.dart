// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_arguments_for_batched_statement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkArgumentsForBatchedStatement
    _$NetworkArgumentsForBatchedStatementFromJson(Map<String, dynamic> json) =>
        NetworkArgumentsForBatchedStatement(
          json['statementIndex'] as int,
          json['arguments'] as List<dynamic>,
        );

Map<String, dynamic> _$NetworkArgumentsForBatchedStatementToJson(
        NetworkArgumentsForBatchedStatement instance) =>
    <String, dynamic>{
      'statementIndex': instance.statementIndex,
      'arguments': instance.arguments,
    };
