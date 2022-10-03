// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../analysis/results/element.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriftElementId _$DriftElementIdFromJson(Map json) => DriftElementId(
      Uri.parse(json['library_uri'] as String),
      json['name'] as String,
    );

Map<String, dynamic> _$DriftElementIdToJson(DriftElementId instance) =>
    <String, dynamic>{
      'library_uri': instance.libraryUri.toString(),
      'name': instance.name,
    };

DriftDeclaration _$DriftDeclarationFromJson(Map json) => DriftDeclaration(
      Uri.parse(json['source_uri'] as String),
      json['offset'] as int,
      json['name'] as String?,
    );

Map<String, dynamic> _$DriftDeclarationToJson(DriftDeclaration instance) =>
    <String, dynamic>{
      'source_uri': instance.sourceUri.toString(),
      'offset': instance.offset,
      'name': instance.name,
    };
