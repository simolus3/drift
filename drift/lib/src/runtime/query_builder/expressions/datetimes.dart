part of '../query_builder.dart';

/// A sql expression that evaluates to the current date represented as a unix
/// timestamp. The hour, minute and second fields will be set to 0.
const Expression<DateTime> currentDate =
    _CustomDateTimeExpression("strftime('%s', CURRENT_DATE)");

/// A sql expression that evaluates to the current date and time, similar to
/// [DateTime.now]. Timestamps are stored with a second accuracy.
const Expression<DateTime> currentDateAndTime =
    _CustomDateTimeExpression("strftime('%s', CURRENT_TIMESTAMP)");

class _CustomDateTimeExpression extends CustomExpression<DateTime> {
  @override
  Precedence get precedence => Precedence.primary;

  const _CustomDateTimeExpression(String content) : super(content);
}

/// Provides expressions to extract information from date time values, or to
/// calculate the difference between datetimes.
extension DateTimeExpressions on Expression<DateTime?> {
  /// Extracts the (UTC) year from `this` datetime expression.
  Expression<int?> get year => _StrftimeSingleFieldExpression('%Y', this);

  /// Extracts the (UTC) month from `this` datetime expression.
  Expression<int?> get month => _StrftimeSingleFieldExpression('%m', this);

  /// Extracts the (UTC) day from `this` datetime expression.
  Expression<int?> get day => _StrftimeSingleFieldExpression('%d', this);

  /// Extracts the (UTC) hour from `this` datetime expression.
  Expression<int?> get hour => _StrftimeSingleFieldExpression('%H', this);

  /// Extracts the (UTC) minute from `this` datetime expression.
  Expression<int?> get minute => _StrftimeSingleFieldExpression('%M', this);

  /// Extracts the (UTC) second from `this` datetime expression.
  Expression<int?> get second => _StrftimeSingleFieldExpression('%S', this);

  /// Formats this datetime in the format `year-month-day`.
  Expression<String?> get date => FunctionCallExpression(
      'DATE', [this, const DateTimeModifier._unixEpoch()]);

  /// Formats this datetime in the format `hour:minute:second`.
  Expression<String?> get time => FunctionCallExpression(
      'TIME', [this, const DateTimeModifier._unixEpoch()]);

  /// Formats this datetime in the format `year-month-day hour:minute:second`.
  Expression<String?> get datetime => FunctionCallExpression(
      'DATETIME', [this, const DateTimeModifier._unixEpoch()]);

  /// Formats this datetime as a unix timestamp - the number of seconds since
  /// 1970-01-01 00:00:00 UTC. The unixepoch() always returns an integer, even
  /// if the input time-value has millisecond precision.
  Expression<int?> get unixepoch => FunctionCallExpression(
      'UNIXEPOCH', [this, const DateTimeModifier._unixEpoch()]);

  /// Formats this datetime in the Julian day format - a fractional number of
  /// days since noon in Greenwich on November 24, 4714 B.C.
  Expression<double?> get julianday => FunctionCallExpression(
      'JULIANDAY', [this, const DateTimeModifier._unixEpoch()]);

  /// Formats this datetime according to the format string specified as the
  /// first argument. The format string supports the most common substitutions
  /// found in the strftime() function from the standard C library plus two new
  /// substitutions, %f and %J. The following is a complete list of valid
  /// strftime() substitutions:
  /// * %d		day of month: 00
  /// * %f		fractional seconds: SS.SSS
  /// * %H		hour: 00-24
  /// * %j		day of year: 001-366
  /// * %J		Julian day number (fractional)
  /// * %m		month: 01-12
  /// * %M		minute: 00-59
  /// * %s		seconds since 1970-01-01
  /// * %S		seconds: 00-59
  /// * %w		day of week 0-6 with Sunday==0
  /// * %W		week of year: 00-53
  /// * %Y		year: 0000-9999
  /// * %%		%
  Expression<String?> strftime(String format) => FunctionCallExpression(
      'STRFTIME',
      [Constant<String>(format), this, const DateTimeModifier._unixEpoch()]);

  /// Apply a modifier that alters the date and/or time.
  ///
  /// See the factories on [DateTimeModifier] for a list of modifiers that can
  /// be used with this method.
  Expression<DateTime?> modify(DateTimeModifier modifier) =>
      FunctionCallExpression(
          'unixepoch', [this, const DateTimeModifier._unixEpoch(), modifier]);

  /// Applies modifiers that alters the date and/or time.
  ///
  /// The [modifiers] are applied in sequence from left to right.
  /// For a list of modifiers and how they behave, see the docs on
  /// [DateTimeModifier] factories.
  Expression<DateTime?> modifyAll(Iterable<DateTimeModifier> modifiers) =>
      FunctionCallExpression('unixepoch',
          [this, const DateTimeModifier._unixEpoch(), ...modifiers]);

  /// Returns an expression containing the amount of seconds from the unix
  /// epoch (January 1st, 1970) to `this` datetime expression. The datetime is
  /// assumed to be in utc.
  // for drift, date times are just unix timestamps, so we don't need to rewrite
  // anything when converting
  Expression<int> get secondsSinceEpoch => dartCast();

  /// Adds a [duration] to this date.
  ///
  /// Note that the curation is added as a value in seconds. Thus, adding a
  /// `Duration(days: 1)` will not necessary yield the same time tomorrow in all
  /// cases (due to daylight saving time switches).
  /// To change the value in terms of calendar units, see [modify].
  Expression<DateTime> operator +(Duration duration) {
    return _BaseInfixOperator(this, '+', Variable<int>(duration.inSeconds),
        precedence: Precedence.plusMinus);
  }

  /// Subtracts [duration] from this date.
  ///
  /// Note that the curation is subtracted as a value in seconds. Thus,
  /// subtracting a `Duration(days: 1)` will not necessary yield the same time
  /// yesterday in all cases (due to daylight saving time switches). To change
  /// the value in terms of calendar units, see [modify].
  Expression<DateTime> operator -(Duration duration) {
    return _BaseInfixOperator(this, '-', Variable<int>(duration.inSeconds),
        precedence: Precedence.plusMinus);
  }
}

/// Expression that extracts components out of a date time by using the builtin
/// sqlite function "strftime" and casting the result to an integer.
class _StrftimeSingleFieldExpression extends Expression<int?> {
  final String format;
  final Expression<DateTime?> date;

  _StrftimeSingleFieldExpression(this.format, this.date);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write("CAST(strftime('$format', ");
    date.writeInto(context);
    context.buffer.write(", 'unixepoch') AS INTEGER)");
  }

  @override
  int get hashCode => Object.hash(format, date);

  @override
  bool operator ==(Object other) {
    return other is _StrftimeSingleFieldExpression &&
        other.format == format &&
        other.date == date;
  }
}

/// DateTime modifier constants.
///
/// These modifiers are used on [DateTimeExpressions.modify] and
/// [DateTimeExpressions.modifyAll] to apply transformations on date time
/// values.
///
/// For instance, [DateTimeModifier.days] can be used to add or subtract
/// calendar days from a date time value. Note that this is different from
/// just subtracting a duration with [DateTimeExpressions.+], which only adds a
/// duration as seconds without respecting calendar units.
///
/// For another explanation of modifiers, see the [sqlite3 docs].
///
/// [sqlite3 docs]: https://sqlite.org/lang_datefunc.html#modifiers
class DateTimeModifier extends Constant<String> {
  const DateTimeModifier._(super.value);

  /// Adds or subtracts [days] calendar days from the date time value.
  const DateTimeModifier.days(int days) : this._('$days days');

  /// Adds or subtracts [hours] hours from this date time value.
  const DateTimeModifier.hours(int hours) : this._('$hours hours');

  /// Adds or subtracts [minutes] minutes from this date time value.
  const DateTimeModifier.minutes(int minutes) : this._('$minutes minutes');

  /// Adds or subtracts [seconds] seconds from this date time value.
  ///
  /// Note that drift assumes date time values to be encoded as unix timestamps
  /// (with second accuracy) in the database. So adding seconds with a
  /// fractional value may not always be preserved in a chain of computation.
  const DateTimeModifier.seconds(num seconds) : this._('$seconds seconds');

  /// Adds or subtracts [months] months from this date time value.
  ///
  /// Note that this works by rendering the original date into the `YYYY-MM-DD`
  /// format, adding the [months] value to the `MM` field and normalizing the
  /// result. Thus, for example, the date 2001-03-31 modified by '+1 month'
  /// nitially yields 2001-04-31, but April only has 30 days so the date is
  /// normalized to 2001-05-01.
  const DateTimeModifier.months(int months) : this._('$months months');

  /// Adds or subtracts [years] years from this date time value.
  ///
  /// Similar to the transformation on [DateTimeModifier.months], it may not
  /// always be possible to keep the day and month field the same for this
  /// transformation. For instance, if the original date is February 29 of a
  /// leapyear and one year is added, the result will be in March 1 of the next
  /// year as there is no February 29.
  const DateTimeModifier.years(int years) : this._('$years years');

  /// The "start of day" modifier shifts the date backwards to the beginning of
  /// the day.
  const DateTimeModifier.startOfDay() : this._('start of day');

  /// The "start of month" modifier shifts the date backwards to the beginning
  /// of the month.
  const DateTimeModifier.startOfMonth() : this._('start of month');

  /// The "start of year" modifier shifts the date backwards to the beginning of
  /// the year.
  const DateTimeModifier.startOfYear() : this._('start of year');

  /// The "weekday" modifier shifts the date forward to the next date where the
  /// weekday is the [weekday] provided here.
  ///
  /// If the source date is on the desired weekday, no transformation happens.
  DateTimeModifier.weekday(DateTimeWeekday weekday)
      : this._('weekday ${weekday.index}');

  const DateTimeModifier._unixEpoch() : this._('unixepoch');

  /// Move a date time that is in UTC to the local time zone.
  ///
  /// See also: [DateTime.toLocal].
  const DateTimeModifier.localTime() : this._('localtime');

  /// Move a date time that is in the local time zone back to UTC.
  ///
  /// See also: [DateTime.toLocal].
  const DateTimeModifier.utc() : this._('utc');
}

/// Weekday offset to be used with [DateTimeModifier.weekday]
enum DateTimeWeekday {
  /// Sunday (+0 on [DateTimeModifier.weekday])
  sunday,

  /// Monday (+1 on [DateTimeModifier.weekday])
  monday,

  /// Tueday (+2 on [DateTimeModifier.weekday])
  tuesday,

  /// Wednesday (+3 on [DateTimeModifier.weekday])
  wednesday,

  /// Thursday (+4 on [DateTimeModifier.weekday])
  thursday,

  /// Friday (+5 on [DateTimeModifier.weekday])
  friday,

  /// Saturday (+6 on [DateTimeModifier.weekday])
  saturday
}
