// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_statement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkStatement _$NetworkStatementFromJson(Map<String, dynamic> json) =>
    NetworkStatement(
      json['statement'] as String,
      json['args'] as List<dynamic>,
    );

Map<String, dynamic> _$NetworkStatementToJson(NetworkStatement instance) =>
    <String, dynamic>{
      'statement': instance.statement,
      'args': instance.args,
    };
