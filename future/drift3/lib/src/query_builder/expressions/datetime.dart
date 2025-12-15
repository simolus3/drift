import '../compiler.dart';
import 'expression.dart';

/// An expression that evaluates to the current date or the current date and
/// time.
final class CurrentDateOrTimeExpression extends Expression<DateTime> {
  /// Whether this should evaluate to the current date and time, or just to the
  /// current date.
  final bool includeTime;

  const CurrentDateOrTimeExpression._(this.includeTime);

  @override
  Precedence get precedence => Precedence.primary;

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addCurrentDateOrTimeExpression(this);
  }
}

/// A sql expression that evaluates to the current date.
///
/// This means that the [DateTime.hour], [DateTime.minute], [DateTime.second]
/// and smaller fields will be set to `0`.
///
/// On SQLite, this returns the [DateTime] as a UTC representation when date
/// times are stored as text on the dialect (for the unix timestamp
/// representation, the time zone makes no difference).
///
/// On PostgreSQL and other servers, the returned timezone may be dependent on
/// the connection or the server.
const Expression<DateTime> currentDate = CurrentDateOrTimeExpression._(false);

/// A sql expression that evaluates to the current date and time, similar to
/// [DateTime.now].
const Expression<DateTime> currentDateAndTime = CurrentDateOrTimeExpression._(
  true,
);

/// An expression converting the inner [timestamp] (as unix seconds) to a
/// [DateTime] value.
final class UnixTimestampToDateTime extends Expression<DateTime> {
  /// The timestamp (in seconds) to convert.
  final Expression<int> timestamp;

  UnixTimestampToDateTime._(this.timestamp);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addUnixTimestampToDateTime(this);
  }
}

/// Fields that can be extracted from [DateTime] values in SQL.
enum DateExtractionField<T extends Object> {
  /// Extracts the [DateTime.year].
  year<int>(),

  /// Extracts the [DateTime.month].
  month<int>(),

  /// Extracts the [DateTime.day].
  day<int>(),

  /// Extracts the [DateTime.hour].
  hour<int>(),

  /// Extracts the [DateTime.minute].
  minute<int>(),

  /// Extracts the [DateTime.second].
  second<int>(),

  /// Extracts the [DateTime.year], [DateTime.month] and [DateTime.day] fields
  /// in the format `year-month-day`.
  date<String>(),

  /// Formats this datetime in the format `hour:minute:second`.
  time<String>(),

  /// Formats this datetime in the format `year-month-day hour:minute:second`.
  datetime<String>(),

  /// Extracts the unix timestamp (in seconds) from this value.
  unixepoch<int>(),

  /// Formats this datetime in the Julian day format - a fractional number of
  /// days since noon in Greenwich on November 24, 4714 B.C.
  julianday<double>();

  const DateExtractionField();
}

/// An expression that extracts some field(s) from a [DateTime] expression.
///
/// These are constructed with getters available with [DateTimeExpressions].
final class DateExtractionOperator<T extends Object> extends Expression<T> {
  /// The value from which a [DateExtractionField] should be extracted.
  final Expression<DateTime> value;

  /// The field to extract from the [value].
  final DateExtractionField<T> field;

  DateExtractionOperator._(this.value, this.field);

  @override
  int get hashCode => Object.hash(value, field);

  @override
  bool operator ==(Object other) {
    return other is DateExtractionOperator &&
        other.field == field &&
        other.value == value;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addDateExtractionOperator(this);
  }
}

/// Provides expressions to extract information from date time values, or to
/// calculate the difference between datetimes.
extension DateTimeExpressions on Expression<DateTime> {
  /// Converts a numeric expression [unixEpoch] into a date time by interpreting
  /// it as the amount of seconds since 1970-01-01 00:00:00 UTC.
  ///
  /// Note that the returned value is in UTC if date times are stored as text.
  /// If they're stored as unix timestamps, this function is a no-op and the
  /// returned value is interpreted as a local date time (like all datetime
  /// values in that mode).
  static Expression<DateTime> fromUnixEpoch(Expression<int> unixEpoch) {
    return UnixTimestampToDateTime._(unixEpoch);
  }

  /// Extracts the year from `this` datetime expression.
  ///
  /// {@template drift_datetime_timezone}
  /// Even if the date time stored was in a local timezone, this format may
  /// return information in a different time zone depending on the database used
  /// (UTC for SQLite, for instance).
  ///
  /// For example, if your local timezone has the UTC offset `+02:00` and you're
  /// inserting a (local) [DateTime] value at `12:34`, running the [hour] getter
  /// on this value could return `10`, since the datetime is at `10:34` in UTC.
  ///
  /// For SQLite databases, you can use `modify` with
  /// `DateTimeModifier.localTime` before invoking the getters, e.g. like:
  ///
  /// ```dart
  ///  Variable(DateTime.now()).modify(DateTimeModifier.localTime()).hour
  /// ```
  /// {@endtemplate}
  Expression<int> get year =>
      DateExtractionOperator._(this, DateExtractionField.year);

  /// Extracts the month from `this` datetime expression.
  ///
  /// {@macro drift_datetime_timezone}
  Expression<int> get month =>
      DateExtractionOperator._(this, DateExtractionField.month);

  /// Extracts the day from `this` datetime expression.
  ///
  /// {@macro drift_datetime_timezone}
  Expression<int> get day =>
      DateExtractionOperator._(this, DateExtractionField.day);

  /// Extracts the hour from `this` datetime expression.
  ///
  /// {@macro drift_datetime_timezone}
  Expression<int> get hour =>
      DateExtractionOperator._(this, DateExtractionField.hour);

  /// Extracts the minute from `this` datetime expression.
  ///
  /// {@macro drift_datetime_timezone}
  Expression<int> get minute =>
      DateExtractionOperator._(this, DateExtractionField.minute);

  /// Extracts the second from `this` datetime expression.
  ///
  /// {@macro drift_datetime_timezone}
  Expression<int> get second =>
      DateExtractionOperator._(this, DateExtractionField.second);

  /// Formats this datetime in the format `year-month-day`.
  ///
  /// {@macro drift_datetime_timezone}
  Expression<String> get date =>
      DateExtractionOperator._(this, DateExtractionField.date);

  /// Formats this datetime in the format `hour:minute:second`.
  ///
  /// {@macro drift_datetime_timezone}
  Expression<String> get time =>
      DateExtractionOperator._(this, DateExtractionField.time);

  /// Formats this datetime in the format `year-month-day hour:minute:second`.
  ///
  /// {@macro drift_datetime_timezone}
  Expression<String> get datetime =>
      DateExtractionOperator._(this, DateExtractionField.datetime);

  /// Formats this datetime as a unix timestamp - the number of seconds since
  /// 1970-01-01 00:00:00 UTC.
  ///
  /// This function always returns an integer for seconds, even if the input
  /// value has millisecond precision.
  Expression<int> get unixepoch =>
      DateExtractionOperator._(this, DateExtractionField.unixepoch);

  /// Formats this datetime in the Julian day format - a fractional number of
  /// days since noon in Greenwich on November 24, 4714 B.C.
  Expression<double> get julianday =>
      DateExtractionOperator._(this, DateExtractionField.julianday);
}
