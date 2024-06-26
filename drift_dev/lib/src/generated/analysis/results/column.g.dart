// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../analysis/results/column.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrimaryKeyColumn _$PrimaryKeyColumnFromJson(Map json) => PrimaryKeyColumn(
      json['is_auto_increment'] as bool,
    );

Map<String, dynamic> _$PrimaryKeyColumnToJson(PrimaryKeyColumn instance) =>
    <String, dynamic>{
      'is_auto_increment': instance.isAutoIncrement,
    };

ColumnGeneratedAs _$ColumnGeneratedAsFromJson(Map json) => ColumnGeneratedAs(
      AnnotatedDartCode.fromJson(json['dart_expression'] as Map),
      json['stored'] as bool,
    );

Map<String, dynamic> _$ColumnGeneratedAsToJson(ColumnGeneratedAs instance) =>
    <String, dynamic>{
      'dart_expression': instance.dartExpression.toJson(),
      'stored': instance.stored,
    };

DartCheckExpression _$DartCheckExpressionFromJson(Map json) =>
    DartCheckExpression(
      AnnotatedDartCode.fromJson(json['dart_expression'] as Map),
    );

Map<String, dynamic> _$DartCheckExpressionToJson(
        DartCheckExpression instance) =>
    <String, dynamic>{
      'dart_expression': instance.dartExpression.toJson(),
    };

LimitingTextLength _$LimitingTextLengthFromJson(Map json) => LimitingTextLength(
      minLength: (json['min_length'] as num?)?.toInt(),
      maxLength: (json['max_length'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LimitingTextLengthToJson(LimitingTextLength instance) =>
    <String, dynamic>{
      'min_length': instance.minLength,
      'max_length': instance.maxLength,
    };
