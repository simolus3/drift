// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../analysis/results/dart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DartTopLevelSymbol _$DartTopLevelSymbolFromJson(Map json) => $checkedCreate(
      'DartTopLevelSymbol',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['lexeme', 'element_id'],
        );
        final val = DartTopLevelSymbol(
          $checkedConvert('lexeme', (v) => v as String),
          $checkedConvert(
              'element_id', (v) => DriftElementId.fromJson(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {'elementId': 'element_id'},
    );

Map<String, dynamic> _$DartTopLevelSymbolToJson(DartTopLevelSymbol instance) =>
    <String, dynamic>{
      'lexeme': instance.lexeme,
      'element_id': instance.elementId.toJson(),
    };
