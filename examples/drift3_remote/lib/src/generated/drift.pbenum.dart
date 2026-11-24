// This is a generated file - do not edit.
//
// Generated from drift.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class UpdateKind extends $pb.ProtobufEnum {
  /// The kind of update is not known (a `null` `TableUpdate.kind`).
  static const UpdateKind UPDATE_KIND_UNKNOWN =
      UpdateKind._(0, _omitEnumNames ? '' : 'UPDATE_KIND_UNKNOWN');
  static const UpdateKind UPDATE_KIND_INSERT =
      UpdateKind._(1, _omitEnumNames ? '' : 'UPDATE_KIND_INSERT');
  static const UpdateKind UPDATE_KIND_UPDATE =
      UpdateKind._(2, _omitEnumNames ? '' : 'UPDATE_KIND_UPDATE');
  static const UpdateKind UPDATE_KIND_DELETE =
      UpdateKind._(3, _omitEnumNames ? '' : 'UPDATE_KIND_DELETE');

  static const $core.List<UpdateKind> values = <UpdateKind>[
    UPDATE_KIND_UNKNOWN,
    UPDATE_KIND_INSERT,
    UPDATE_KIND_UPDATE,
    UPDATE_KIND_DELETE,
  ];

  static final $core.List<UpdateKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static UpdateKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const UpdateKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
