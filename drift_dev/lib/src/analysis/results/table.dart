import 'dart.dart';
import 'element.dart';

import 'column.dart';
import 'result_sets.dart';

class DriftTable extends DriftElementWithResultSet {
  @override
  final List<DriftColumn> columns;

  final Set<DriftColumn>? primaryKeyFromTableConstraint;
  final List<Set<DriftColumn>> uniqueKeysFromTableConstraint;

  @override
  final List<DriftElement> references;

  @override
  final ExistingRowClass? existingRowClass;

  @override
  final AnnotatedDartCode? customParentClass;

  /// The fixed [entityInfoName] to use, overriding the default.
  final String? fixedEntityInfoName;

  /// The default name to use for the [entityInfoName].
  final String baseDartName;

  /// The name for the data class associated with this table
  final String dartTypeName;

  final bool withoutRowId;

  final bool strict;

  DriftTable(
    super.id,
    super.declaration, {
    required this.columns,
    required this.baseDartName,
    required this.dartTypeName,
    this.references = const [],
    this.existingRowClass,
    this.customParentClass,
    this.fixedEntityInfoName,
    this.withoutRowId = false,
    this.strict = false,
    this.primaryKeyFromTableConstraint,
    this.uniqueKeysFromTableConstraint = const [],
  }) {
    for (final column in columns) {
      column.owner = this;
    }
  }

  @override
  String get entityInfoName {
    // if this table was parsed from sql, a user might want to refer to it
    // directly because there is no user defined parent class.
    // So, turn CREATE TABLE users into something called "Users" instead of
    // "$UsersTable".
    final name =
        fixedEntityInfoName ?? _tableInfoNameForTableClass(baseDartName);
    if (name == dartTypeName) {
      // resolve clashes if the table info class has the same name as the data
      // class. This can happen because the data class name can be specified by
      // the user.
      return '${name}Table';
    }
    return name;
  }
}

String _tableInfoNameForTableClass(String className) => '\$${className}Table';
