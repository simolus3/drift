// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../analysis/results/element.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriftElementId _$DriftElementIdFromJson(Map json) => $checkedCreate(
      'DriftElementId',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['library_uri', 'name'],
        );
        final val = DriftElementId(
          $checkedConvert('library_uri', (v) => Uri.parse(v as String)),
          $checkedConvert('name', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'libraryUri': 'library_uri'},
    );

Map<String, dynamic> _$DriftElementIdToJson(DriftElementId instance) =>
    <String, dynamic>{
      'library_uri': instance.libraryUri.toString(),
      'name': instance.name,
    };

DriftDeclaration _$DriftDeclarationFromJson(Map json) => $checkedCreate(
      'DriftDeclaration',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['source_uri', 'offset'],
        );
        final val = DriftDeclaration(
          $checkedConvert('source_uri', (v) => Uri.parse(v as String)),
          $checkedConvert('offset', (v) => v as int),
        );
        return val;
      },
      fieldKeyMap: const {'sourceUri': 'source_uri'},
    );

Map<String, dynamic> _$DriftDeclarationToJson(DriftDeclaration instance) =>
    <String, dynamic>{
      'source_uri': instance.sourceUri.toString(),
      'offset': instance.offset,
    };
