// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../analysis/results/dart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaggedDartLexeme _$TaggedDartLexemeFromJson(Map json) => TaggedDartLexeme(
      json['lexeme'] as String,
      json['tag'] as String,
    );

Map<String, dynamic> _$TaggedDartLexemeToJson(TaggedDartLexeme instance) =>
    <String, dynamic>{
      'lexeme': instance.lexeme,
      'tag': instance.tag,
    };

DartTopLevelSymbol _$DartTopLevelSymbolFromJson(Map json) => DartTopLevelSymbol(
      json['lexeme'] as String,
      json['import_uri'] == null
          ? null
          : Uri.parse(json['import_uri'] as String),
    );

Map<String, dynamic> _$DartTopLevelSymbolToJson(DartTopLevelSymbol instance) =>
    <String, dynamic>{
      'lexeme': instance.lexeme,
      'import_uri': instance.importUri?.toString(),
    };
