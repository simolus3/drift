// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_batched_statement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkBatchedStatement _$NetworkBatchedStatementFromJson(
        Map<String, dynamic> json) =>
    NetworkBatchedStatement(
      (json['statements'] as List<dynamic>).map((e) => e as String).toList(),
      (json['arguments'] as List<dynamic>)
          .map((e) => NetworkArgumentsForBatchedStatement.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NetworkBatchedStatementToJson(
        NetworkBatchedStatement instance) =>
    <String, dynamic>{
      'statements': instance.statements,
      'arguments': instance.arguments.map((e) => e.toJson()).toList(),
    };
