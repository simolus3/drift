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
  Expression<DateTime?> modify(DateTimeModifier modifier) =>
      FunctionCallExpression('strftime', [
        const Constant<String>('%s'),
        this,
        const DateTimeModifier._unixEpoch(),
        modifier
      ]);

  /// Applies modifiers that alters the date and/or time. Each modifier is a
  /// transformation that is applied to the time value to its left. Modifiers
  /// are applied from left to right; order is important.
  Expression<DateTime?> modifyThough(Iterable<DateTimeModifier> modifiers) =>
      FunctionCallExpression('strftime', [
        const Constant<String>('%s'),
        this,
        const DateTimeModifier._unixEpoch(),
        ...modifiers
      ]);

  /// Returns an expression containing the amount of seconds from the unix
  /// epoch (January 1st, 1970) to `this` datetime expression. The datetime is
  /// assumed to be in utc.
  // for drift, date times are just unix timestamps, so we don't need to rewrite
  // anything when converting
  Expression<int> get secondsSinceEpoch => dartCast();

  /// Adds [duration] from this date.
  Expression<DateTime> operator +(Duration duration) {
    return _BaseInfixOperator(this, '+', Variable<int>(duration.inSeconds),
        precedence: Precedence.plusMinus);
  }

  /// Subtracts [duration] from this date.
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

/// DateTime modifier constants
class DateTimeModifier extends Constant<String> {
  const DateTimeModifier._(super.value);

  /// The "n days" modifiers simply add the specified amount of time to the date
  /// and time specified by the arguments to the left. Note that "±NNN months"
  /// works by rendering the original date into the YYYY-MM-DD format, adding
  /// the ±NNN to the MM month value, then normalizing the result. Thus, for
  /// example, the date 2001-03-31 modified by '+1 month' initially yields
  /// 2001-04-31, but April only has 30 days so the date is normalized to
  /// 2001-05-01. A similar effect occurs when the original date is February 29
  /// of a leapyear and the modifier is ±N years where N is not a multiple of
  /// four.
  const DateTimeModifier.days(int days) : this._('$days days');

  /// The "n hours" modifiers simply add the specified amount of time to the
  /// date and time specified by the arguments to the left. Note that "±NNN
  /// months" works by rendering the original date into the YYYY-MM-DD format,
  /// adding the ±NNN to the MM month value, then normalizing the result. Thus,
  /// for example, the date 2001-03-31 modified by '+1 month' initially yields
  /// 2001-04-31, but April only has 30 days so the date is normalized to
  /// 2001-05-01. A similar effect occurs when the original date is February 29
  /// of a leapyear and the modifier is ±N years where N is not a multiple of
  /// four.
  DateTimeModifier.hours(int hours) : this._('$hours hours');

  /// The "n minutes" modifiers simply add the specified amount of time to the
  /// date and time specified by the arguments to the left. Note that "±NNN
  /// months" works by rendering the original date into the YYYY-MM-DD format,
  /// adding the ±NNN to the MM month value, then normalizing the result. Thus,
  /// for example, the date 2001-03-31 modified by '+1 month' initially yields
  /// 2001-04-31, but April only has 30 days so the date is normalized to
  /// 2001-05-01. A similar effect occurs when the original date is February 29
  /// of a leapyear and the modifier is ±N years where N is not a multiple of
  /// four.
  DateTimeModifier.minutes(int minutes) : this._('$minutes minutes');

  /// The "n seconds" modifiers simply add the specified amount of time to the
  /// date and time specified by the arguments to the left. Note that "±NNN
  /// months" works by rendering the original date into the YYYY-MM-DD format,
  /// adding the ±NNN to the MM month value, then normalizing the result. Thus,
  /// for example, the date 2001-03-31 modified by '+1 month' initially yields
  /// 2001-04-31, but April only has 30 days so the date is normalized to
  /// 2001-05-01. A similar effect occurs when the original date is February 29
  /// of a leapyear and the modifier is ±N years where N is not a multiple of
  /// four.
  DateTimeModifier.seconds(double seconds) : this._('$seconds seconds');

  /// The "n months" modifiers simply add the specified amount of time to the
  /// date and time specified by the arguments to the left. Note that "±NNN
  /// months" works by rendering the original date into the YYYY-MM-DD format,
  /// adding the ±NNN to the MM month value, then normalizing the result. Thus,
  /// for example, the date 2001-03-31 modified by '+1 month' initially yields
  /// 2001-04-31, but April only has 30 days so the date is normalized to
  /// 2001-05-01. A similar effect occurs when the original date is February 29
  /// of a leapyear and the modifier is ±N years where N is not a multiple of
  /// four.
  DateTimeModifier.months(int months) : this._('$months months');

  /// The "n years" modifiers simply add the specified amount of time to the
  /// date and time specified by the arguments to the left. Note that "±NNN
  /// months" works by rendering the original date into the YYYY-MM-DD format,
  /// adding the ±NNN to the MM month value, then normalizing the result. Thus,
  /// for example, the date 2001-03-31 modified by '+1 month' initially yields
  /// 2001-04-31, but April only has 30 days so the date is normalized to
  /// 2001-05-01. A similar effect occurs when the original date is February 29
  /// of a leapyear and the modifier is ±N years where N is not a multiple of
  /// four.
  DateTimeModifier.years(int years) : this._('$years years');

  /// The "start of day" modifier shift the date backwards to the beginning of
  /// the day.
  const DateTimeModifier.startOfDay() : this._('start of day');

  /// The "start of month" modifier shift the date backwards to the beginning of
  /// the month.
  const DateTimeModifier.startOfMonth() : this._('start of month');

  /// The "start of year" modifier shift the date backwards to the beginning of
  /// the year.
  const DateTimeModifier.startOfYear() : this._('start of year');

  /// The "weekday" modifier advances the date forward, if necessary, to the
  /// next date where the weekday number is N. Sunday is 0, Monday is 1, and so
  /// forth. If the date is already on the desired weekday, the "weekday"
  /// modifier leaves the date unchanged.
  DateTimeModifier.weekday(DateTimeWeekday weekday)
      : this._('weekday ${weekday.index}');

  /// The "unixepoch" modifier only works if it immediately follows a time
  /// value in the DDDDDDDDDD format. This modifier causes the DDDDDDDDDD to be
  /// interpreted not as a Julian day number as it normally would be, but as
  /// Unix Time - the number of seconds since 1970. If the "unixepoch" modifier
  /// does not follow a time value of the form DDDDDDDDDD which expresses the
  /// number of seconds since 1970 or if other modifiers separate the
  /// "unixepoch" modifier from prior DDDDDDDDDD then the behavior is undefined.
  /// For SQLite versions before 3.16.0 (2017-01-02), the "unixepoch" modifier
  /// only works for dates between 0000-01-01 00:00:00 and 5352-11-01 10:52:47
  /// (unix times of -62167219200 through 106751991167).
  const DateTimeModifier._unixEpoch() : this._('unixepoch');

  // The "julianday" modifier must immediately follow the initial time-value
  // which must be of the form DDDDDDDDD. Any other use of the 'julianday'
  // modifier is an error and causes the function to return NULL. The
  // 'julianday' modifier forces the time-value number to be interpreted as a
  // julian-day number. As this is the default behavior, the 'julianday'
  // modifier is scarcely more than a no-op. The only difference is that adding
  // 'julianday' forces the DDDDDDDDD time-value format, and causes a NULL to
  // be returned if any other time-value format is used.
  //const DateTimeModifier.julianDay() : this._('julianday');

  // The "auto" modifier must immediately follow the initial time-value. If the
  // time-value is numeric (the DDDDDDDDDD format) then the 'auto' modifier
  // causes the time-value to interpreted as either a julian day number or a
  // unix timestamp, depending on its magnitude. If the value is between 0.0
  // and 5373484.499999, then it is interpreted as a julian day number
  // (corresponding to dates between -4713-11-24 12:00:00 and 9999-12-31
  // 23:59:59, inclusive). For numeric values outside of the range of valid
  // julian day numbers, but within the range of -210866760000 to 253402300799,
  // the 'auto' modifier causes the value to be interpreted as a unix
  // timestamp. Other numeric values are out of range and cause a NULL return.
  // The 'auto' modifier is a no-op for text time-values.
  //const DateTimeModifier.auto() : this._('auto');

  /// The "localtime" modifier (14) assumes the time value to its left is in
  /// Universal Coordinated Time (UTC) and adjusts that time value so that it is
  /// in localtime. If "localtime" follows a time that is not UTC, then the
  /// behavior is undefined.
  const DateTimeModifier.localTime() : this._('localtime');

  /// The "utc" modifier is the opposite of "localtime". "utc" assumes that the
  /// time value to its left is in the local timezone and adjusts that time
  /// value to be in UTC. If the time to the left is not in localtime, then the
  /// result of "utc" is undefined.
  const DateTimeModifier.utc() : this._('utc');
}

/// Weekday offset to be used with [DateTimeModifier.weekday]
enum DateTimeWeekday {
  /// Sunday (+0)
  sunday,

  /// Monday (+1)
  monday,

  /// Tueday (+2)
  tuesday,

  /// Wednesday (+3)
  wednesday,

  /// Thursday (+4)
  thursday,

  /// Friday (+5)
  friday,

  /// Saturday (+6)
  saturday,
}
