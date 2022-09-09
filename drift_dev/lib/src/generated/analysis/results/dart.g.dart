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
          allowedKeys: const ['lexeme', 'import_uri'],
        );
        final val = DartTopLevelSymbol(
          $checkedConvert('lexeme', (v) => v as String),
          $checkedConvert(
              'import_uri', (v) => v == null ? null : Uri.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'importUri': 'import_uri'},
    );

Map<String, dynamic> _$DartTopLevelSymbolToJson(DartTopLevelSymbol instance) =>
    <String, dynamic>{
      'lexeme': instance.lexeme,
      'import_uri': instance.importUri?.toString(),
    };
