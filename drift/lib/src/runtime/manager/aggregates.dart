// ignore_for_file: unused_field

part of 'manager.dart';

/// A wrapper around reverse filters for different kinds of aggregates.
@internal
class ColumnAggregate {
  final ComposableFilter _filter;

  /// Creates a new column aggregate for the given column.
  const ColumnAggregate(this._filter);

  /// If any of these columns exist, this column aggregate will be true.
  ComposableFilter any() => _filter;
}
