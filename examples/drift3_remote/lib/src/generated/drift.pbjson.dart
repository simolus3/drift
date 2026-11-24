// This is a generated file - do not edit.
//
// Generated from drift.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use updateKindDescriptor instead')
const UpdateKind$json = {
  '1': 'UpdateKind',
  '2': [
    {'1': 'UPDATE_KIND_UNKNOWN', '2': 0},
    {'1': 'UPDATE_KIND_INSERT', '2': 1},
    {'1': 'UPDATE_KIND_UPDATE', '2': 2},
    {'1': 'UPDATE_KIND_DELETE', '2': 3},
  ],
};

/// Descriptor for `UpdateKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List updateKindDescriptor = $convert.base64Decode(
    'CgpVcGRhdGVLaW5kEhcKE1VQREFURV9LSU5EX1VOS05PV04QABIWChJVUERBVEVfS0lORF9JTl'
    'NFUlQQARIWChJVUERBVEVfS0lORF9VUERBVEUQAhIWChJVUERBVEVfS0lORF9ERUxFVEUQAw==');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use connectRequestDescriptor instead')
const ConnectRequest$json = {
  '1': 'ConnectRequest',
};

/// Descriptor for `ConnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectRequestDescriptor =
    $convert.base64Decode('Cg5Db25uZWN0UmVxdWVzdA==');

@$core.Deprecated('Use createdSessionDescriptor instead')
const CreatedSession$json = {
  '1': 'CreatedSession',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {
      '1': 'persistent_schema_version',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'persistentSchemaVersion'
    },
    {'1': 'transaction', '3': 3, '4': 1, '5': 8, '10': 'transaction'},
    {
      '1': 'transaction_parent',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'transactionParent'
    },
    {'1': 'locks', '3': 5, '4': 1, '5': 8, '10': 'locks'},
  ],
};

/// Descriptor for `CreatedSession`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createdSessionDescriptor = $convert.base64Decode(
    'Cg5DcmVhdGVkU2Vzc2lvbhIOCgJpZBgBIAEoBVICaWQSOgoZcGVyc2lzdGVudF9zY2hlbWFfdm'
    'Vyc2lvbhgCIAEoCFIXcGVyc2lzdGVudFNjaGVtYVZlcnNpb24SIAoLdHJhbnNhY3Rpb24YAyAB'
    'KAhSC3RyYW5zYWN0aW9uEi0KEnRyYW5zYWN0aW9uX3BhcmVudBgEIAEoCFIRdHJhbnNhY3Rpb2'
    '5QYXJlbnQSFAoFbG9ja3MYBSABKAhSBWxvY2tz');

@$core.Deprecated('Use sessionRequestDescriptor instead')
const SessionRequest$json = {
  '1': 'SessionRequest',
  '2': [
    {'1': 'session', '3': 1, '4': 1, '5': 5, '10': 'session'},
  ],
};

/// Descriptor for `SessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionRequestDescriptor = $convert
    .base64Decode('Cg5TZXNzaW9uUmVxdWVzdBIYCgdzZXNzaW9uGAEgASgFUgdzZXNzaW9u');

@$core.Deprecated('Use getSchemaVersionDescriptor instead')
const GetSchemaVersion$json = {
  '1': 'GetSchemaVersion',
  '2': [
    {'1': 'session', '3': 1, '4': 1, '5': 5, '10': 'session'},
  ],
};

/// Descriptor for `GetSchemaVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSchemaVersionDescriptor = $convert.base64Decode(
    'ChBHZXRTY2hlbWFWZXJzaW9uEhgKB3Nlc3Npb24YASABKAVSB3Nlc3Npb24=');

@$core.Deprecated('Use getSchemaVersionResultDescriptor instead')
const GetSchemaVersionResult$json = {
  '1': 'GetSchemaVersionResult',
  '2': [
    {'1': 'schema_version', '3': 1, '4': 1, '5': 3, '10': 'schemaVersion'},
  ],
};

/// Descriptor for `GetSchemaVersionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSchemaVersionResultDescriptor =
    $convert.base64Decode(
        'ChZHZXRTY2hlbWFWZXJzaW9uUmVzdWx0EiUKDnNjaGVtYV92ZXJzaW9uGAEgASgDUg1zY2hlbW'
        'FWZXJzaW9u');

@$core.Deprecated('Use setSchemaVersionDescriptor instead')
const SetSchemaVersion$json = {
  '1': 'SetSchemaVersion',
  '2': [
    {'1': 'session', '3': 1, '4': 1, '5': 5, '10': 'session'},
    {'1': 'schema_version', '3': 2, '4': 1, '5': 3, '10': 'schemaVersion'},
  ],
};

/// Descriptor for `SetSchemaVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSchemaVersionDescriptor = $convert.base64Decode(
    'ChBTZXRTY2hlbWFWZXJzaW9uEhgKB3Nlc3Npb24YASABKAVSB3Nlc3Npb24SJQoOc2NoZW1hX3'
    'ZlcnNpb24YAiABKANSDXNjaGVtYVZlcnNpb24=');

@$core.Deprecated('Use beginRequestDescriptor instead')
const BeginRequest$json = {
  '1': 'BeginRequest',
  '2': [
    {'1': 'session', '3': 1, '4': 1, '5': 5, '10': 'session'},
    {
      '1': 'options',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.driftremote.TransactionOptions',
      '10': 'options'
    },
  ],
};

/// Descriptor for `BeginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List beginRequestDescriptor = $convert.base64Decode(
    'CgxCZWdpblJlcXVlc3QSGAoHc2Vzc2lvbhgBIAEoBVIHc2Vzc2lvbhI5CgdvcHRpb25zGAIgAS'
    'gLMh8uZHJpZnRyZW1vdGUuVHJhbnNhY3Rpb25PcHRpb25zUgdvcHRpb25z');

@$core.Deprecated('Use transactionOptionsDescriptor instead')
const TransactionOptions$json = {
  '1': 'TransactionOptions',
  '2': [
    {
      '1': 'defer_foreign_keys',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'deferForeignKeys',
      '17': true
    },
    {'1': 'read_only', '3': 2, '4': 1, '5': 8, '10': 'readOnly'},
  ],
  '8': [
    {'1': '_defer_foreign_keys'},
  ],
};

/// Descriptor for `TransactionOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOptionsDescriptor = $convert.base64Decode(
    'ChJUcmFuc2FjdGlvbk9wdGlvbnMSMQoSZGVmZXJfZm9yZWlnbl9rZXlzGAEgASgISABSEGRlZm'
    'VyRm9yZWlnbktleXOIAQESGwoJcmVhZF9vbmx5GAIgASgIUghyZWFkT25seUIVChNfZGVmZXJf'
    'Zm9yZWlnbl9rZXlz');

@$core.Deprecated('Use executeRequestDescriptor instead')
const ExecuteRequest$json = {
  '1': 'ExecuteRequest',
  '2': [
    {'1': 'session', '3': 1, '4': 1, '5': 5, '10': 'session'},
    {
      '1': 'statement',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.driftremote.StatementInfo',
      '10': 'statement'
    },
  ],
};

/// Descriptor for `ExecuteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executeRequestDescriptor = $convert.base64Decode(
    'Cg5FeGVjdXRlUmVxdWVzdBIYCgdzZXNzaW9uGAEgASgFUgdzZXNzaW9uEjgKCXN0YXRlbWVudB'
    'gCIAEoCzIaLmRyaWZ0cmVtb3RlLlN0YXRlbWVudEluZm9SCXN0YXRlbWVudA==');

@$core.Deprecated('Use executeBatchRequestDescriptor instead')
const ExecuteBatchRequest$json = {
  '1': 'ExecuteBatchRequest',
  '2': [
    {'1': 'session', '3': 1, '4': 1, '5': 5, '10': 'session'},
    {
      '1': 'batch',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.driftremote.StatementBatch',
      '10': 'batch'
    },
  ],
};

/// Descriptor for `ExecuteBatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executeBatchRequestDescriptor = $convert.base64Decode(
    'ChNFeGVjdXRlQmF0Y2hSZXF1ZXN0EhgKB3Nlc3Npb24YASABKAVSB3Nlc3Npb24SMQoFYmF0Y2'
    'gYAiABKAsyGy5kcmlmdHJlbW90ZS5TdGF0ZW1lbnRCYXRjaFIFYmF0Y2g=');

@$core.Deprecated('Use statementBatchDescriptor instead')
const StatementBatch$json = {
  '1': 'StatementBatch',
  '2': [
    {'1': 'sql', '3': 1, '4': 3, '5': 9, '10': 'sql'},
    {
      '1': 'statements',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.driftremote.StatementInBatch',
      '10': 'statements'
    },
  ],
};

/// Descriptor for `StatementBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statementBatchDescriptor = $convert.base64Decode(
    'Cg5TdGF0ZW1lbnRCYXRjaBIQCgNzcWwYASADKAlSA3NxbBI9CgpzdGF0ZW1lbnRzGAIgAygLMh'
    '0uZHJpZnRyZW1vdGUuU3RhdGVtZW50SW5CYXRjaFIKc3RhdGVtZW50cw==');

@$core.Deprecated('Use statementInBatchDescriptor instead')
const StatementInBatch$json = {
  '1': 'StatementInBatch',
  '2': [
    {'1': 'sql_index', '3': 1, '4': 1, '5': 5, '10': 'sqlIndex'},
    {
      '1': 'info',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.driftremote.StatementInfo',
      '10': 'info'
    },
  ],
};

/// Descriptor for `StatementInBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statementInBatchDescriptor = $convert.base64Decode(
    'ChBTdGF0ZW1lbnRJbkJhdGNoEhsKCXNxbF9pbmRleBgBIAEoBVIIc3FsSW5kZXgSLgoEaW5mbx'
    'gCIAEoCzIaLmRyaWZ0cmVtb3RlLlN0YXRlbWVudEluZm9SBGluZm8=');

@$core.Deprecated('Use statementInfoDescriptor instead')
const StatementInfo$json = {
  '1': 'StatementInfo',
  '2': [
    {'1': 'sql', '3': 1, '4': 1, '5': 9, '10': 'sql'},
    {'1': 'needs_result_set', '3': 2, '4': 1, '5': 8, '10': 'needsResultSet'},
    {
      '1': 'variables',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.driftremote.SqlValue',
      '10': 'variables'
    },
    {'1': 'watched_tables', '3': 4, '4': 3, '5': 9, '10': 'watchedTables'},
    {
      '1': 'expected_writes',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.driftremote.TableUpdate',
      '10': 'expectedWrites'
    },
    {'1': 'is_read_only', '3': 6, '4': 1, '5': 8, '10': 'isReadOnly'},
  ],
};

/// Descriptor for `StatementInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statementInfoDescriptor = $convert.base64Decode(
    'Cg1TdGF0ZW1lbnRJbmZvEhAKA3NxbBgBIAEoCVIDc3FsEigKEG5lZWRzX3Jlc3VsdF9zZXQYAi'
    'ABKAhSDm5lZWRzUmVzdWx0U2V0EjMKCXZhcmlhYmxlcxgDIAMoCzIVLmRyaWZ0cmVtb3RlLlNx'
    'bFZhbHVlUgl2YXJpYWJsZXMSJQoOd2F0Y2hlZF90YWJsZXMYBCADKAlSDXdhdGNoZWRUYWJsZX'
    'MSQQoPZXhwZWN0ZWRfd3JpdGVzGAUgAygLMhguZHJpZnRyZW1vdGUuVGFibGVVcGRhdGVSDmV4'
    'cGVjdGVkV3JpdGVzEiAKDGlzX3JlYWRfb25seRgGIAEoCFIKaXNSZWFkT25seQ==');

@$core.Deprecated('Use sqlValueDescriptor instead')
const SqlValue$json = {
  '1': 'SqlValue',
  '2': [
    {'1': 'int_value', '3': 1, '4': 1, '5': 3, '9': 0, '10': 'intValue'},
    {'1': 'double_value', '3': 2, '4': 1, '5': 1, '9': 0, '10': 'doubleValue'},
    {'1': 'text_value', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'textValue'},
    {'1': 'blob_value', '3': 4, '4': 1, '5': 12, '9': 0, '10': 'blobValue'},
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `SqlValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlValueDescriptor = $convert.base64Decode(
    'CghTcWxWYWx1ZRIdCglpbnRfdmFsdWUYASABKANIAFIIaW50VmFsdWUSIwoMZG91YmxlX3ZhbH'
    'VlGAIgASgBSABSC2RvdWJsZVZhbHVlEh8KCnRleHRfdmFsdWUYAyABKAlIAFIJdGV4dFZhbHVl'
    'Eh8KCmJsb2JfdmFsdWUYBCABKAxIAFIJYmxvYlZhbHVlQgcKBXZhbHVl');

@$core.Deprecated('Use tableUpdateDescriptor instead')
const TableUpdate$json = {
  '1': 'TableUpdate',
  '2': [
    {'1': 'table', '3': 1, '4': 1, '5': 9, '10': 'table'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.driftremote.UpdateKind',
      '10': 'kind'
    },
  ],
};

/// Descriptor for `TableUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableUpdateDescriptor = $convert.base64Decode(
    'CgtUYWJsZVVwZGF0ZRIUCgV0YWJsZRgBIAEoCVIFdGFibGUSKwoEa2luZBgCIAEoDjIXLmRyaW'
    'Z0cmVtb3RlLlVwZGF0ZUtpbmRSBGtpbmQ=');

@$core.Deprecated('Use tableUpdatesDescriptor instead')
const TableUpdates$json = {
  '1': 'TableUpdates',
  '2': [
    {
      '1': 'updates',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.driftremote.TableUpdate',
      '10': 'updates'
    },
  ],
};

/// Descriptor for `TableUpdates`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableUpdatesDescriptor = $convert.base64Decode(
    'CgxUYWJsZVVwZGF0ZXMSMgoHdXBkYXRlcxgBIAMoCzIYLmRyaWZ0cmVtb3RlLlRhYmxlVXBkYX'
    'RlUgd1cGRhdGVz');

@$core.Deprecated('Use queryResultDescriptor instead')
const QueryResult$json = {
  '1': 'QueryResult',
  '2': [
    {
      '1': 'affected_rows',
      '3': 1,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'affectedRows',
      '17': true
    },
    {
      '1': 'last_insert_row_id',
      '3': 2,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'lastInsertRowId',
      '17': true
    },
    {
      '1': 'result_set',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.driftremote.ResultSet',
      '10': 'resultSet'
    },
  ],
  '8': [
    {'1': '_affected_rows'},
    {'1': '_last_insert_row_id'},
  ],
};

/// Descriptor for `QueryResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryResultDescriptor = $convert.base64Decode(
    'CgtRdWVyeVJlc3VsdBIoCg1hZmZlY3RlZF9yb3dzGAEgASgDSABSDGFmZmVjdGVkUm93c4gBAR'
    'IwChJsYXN0X2luc2VydF9yb3dfaWQYAiABKANIAVIPbGFzdEluc2VydFJvd0lkiAEBEjUKCnJl'
    'c3VsdF9zZXQYAyABKAsyFi5kcmlmdHJlbW90ZS5SZXN1bHRTZXRSCXJlc3VsdFNldEIQCg5fYW'
    'ZmZWN0ZWRfcm93c0IVChNfbGFzdF9pbnNlcnRfcm93X2lk');

@$core.Deprecated('Use batchResultDescriptor instead')
const BatchResult$json = {
  '1': 'BatchResult',
  '2': [
    {
      '1': 'results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.driftremote.QueryResult',
      '10': 'results'
    },
  ],
};

/// Descriptor for `BatchResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchResultDescriptor = $convert.base64Decode(
    'CgtCYXRjaFJlc3VsdBIyCgdyZXN1bHRzGAEgAygLMhguZHJpZnRyZW1vdGUuUXVlcnlSZXN1bH'
    'RSB3Jlc3VsdHM=');

@$core.Deprecated('Use resultSetDescriptor instead')
const ResultSet$json = {
  '1': 'ResultSet',
  '2': [
    {'1': 'column_names', '3': 1, '4': 3, '5': 9, '10': 'columnNames'},
    {
      '1': 'rows',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.driftremote.Row',
      '10': 'rows'
    },
  ],
};

/// Descriptor for `ResultSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resultSetDescriptor = $convert.base64Decode(
    'CglSZXN1bHRTZXQSIQoMY29sdW1uX25hbWVzGAEgAygJUgtjb2x1bW5OYW1lcxIkCgRyb3dzGA'
    'IgAygLMhAuZHJpZnRyZW1vdGUuUm93UgRyb3dz');

@$core.Deprecated('Use rowDescriptor instead')
const Row$json = {
  '1': 'Row',
  '2': [
    {
      '1': 'values',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.driftremote.SqlValue',
      '10': 'values'
    },
  ],
};

/// Descriptor for `Row`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowDescriptor = $convert.base64Decode(
    'CgNSb3cSLQoGdmFsdWVzGAEgAygLMhUuZHJpZnRyZW1vdGUuU3FsVmFsdWVSBnZhbHVlcw==');
