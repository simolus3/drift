// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../analysis/results/table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VirtualTableData _$VirtualTableDataFromJson(Map json) => VirtualTableData(
      json['module'] as String,
      (json['module_arguments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$VirtualTableDataToJson(VirtualTableData instance) =>
    <String, dynamic>{
      'module': instance.module,
      'module_arguments': instance.moduleArguments,
    };
