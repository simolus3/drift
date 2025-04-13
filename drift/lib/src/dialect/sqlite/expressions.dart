import 'package:drift/drift.dart';

import 'dialect.dart';

/// Provides additional options to [regexp] that are only available when using
/// SQLite.
extension SqliteSpecificStringOperators on Expression<String> {
  /// Matches this string against the regular expression in [regex].
  ///
  /// The [multiLine], [caseSensitive], [unicode] and [dotAll] parameters
  /// correspond to the parameters on [RegExp].
  ///
  /// Note that this function is only available when using a `NativeDatabase`.
  /// If you need to support the web or `moor_flutter`, consider using [like]
  /// instead.
  Expression<bool> regexp(
    String regex, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) {
    // We have a special regexp sql function that takes a third parameter
    // to encode flags. If the least significant bit is set, multiLine is
    // enabled. The next three bits enable case INSENSITIVITY (it's sensitive
    // by default), unicode and dotAll.
    var flags = 0;

    if (multiLine) {
      flags |= 1;
    }
    if (!caseSensitive) {
      flags |= 2;
    }
    if (unicode) {
      flags |= 4;
    }
    if (dotAll) {
      flags |= 8;
    }

    if (flags != 0) {
      return FunctionCallExpression<bool>(
        'regexp_drift',
        [
          Variable.withString(regex),
          this,
          Variable.withInt(flags),
        ],
      );
    }

    // No special flags enabled, use the regular REGEXP operator
    return BinaryExpression(
        this, BinaryOperator.regexp, Variable.withString(regex));
  }
}

/// Provides the SQLite-specific [strftime], [modify], [+] and [-] APIs for date
/// time values.
extension SqliteSpecificDateTimeOperators on Expression<DateTime> {
  /// Formats this datetime according to the format string specified as the
  /// first argument. The format string supports the most common substitutions
  /// found in the strftime() function from the standard C library plus two new
  /// substitutions, %f and %J. The following is a complete list of valid
  /// strftime() substitutions:
  ///
  /// ```
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
  /// ```
  Expression<String> strftime(String format) {
    return _DependingOnDateTimeExpression.generate((datesAsText) {
      return FunctionCallExpression('STRFTIME', [
        Literal(format),
        this,
        if (!datesAsText) const DateTimeModifier._unixEpoch(),
      ]);
    });
  }

  /// Apply a modifier that alters the date and/or time.
  ///
  /// See the factories on [DateTimeModifier] for a list of modifiers that can
  /// be used with this method.
  Expression<DateTime> modify(DateTimeModifier modifier) {
    return _DependingOnDateTimeExpression(
      forTimestamps: FunctionCallExpression(
          'unixepoch', [this, const DateTimeModifier._unixEpoch(), modifier]),
      forIsoString: FunctionCallExpression('datetime', [this, modifier]),
    );
  }

  /// Applies modifiers that alters the date and/or time.
  ///
  /// The [modifiers] are applied in sequence from left to right.
  /// For a list of modifiers and how they behave, see the docs on
  /// [DateTimeModifier] factories.
  Expression<DateTime> modifyAll(Iterable<DateTimeModifier> modifiers) {
    return _DependingOnDateTimeExpression(
      forTimestamps: FunctionCallExpression('unixepoch',
          [this, const DateTimeModifier._unixEpoch(), ...modifiers]),
      forIsoString: FunctionCallExpression('datetime', [this, ...modifiers]),
    );
  }

  /// Returns an expression containing the amount of seconds from the unix
  /// epoch (January 1st, 1970) to `this` datetime expression.
  @Deprecated('Use the `unixepoch` getter instead')
  Expression<int> get secondsSinceEpoch => unixepoch;

  /// Adds a [duration] to this date.
  ///
  /// Note that the curation is added as a value in seconds. Thus, adding a
  /// `Duration(days: 1)` will not necessary yield the same time tomorrow in all
  /// cases (due to daylight saving time switches).
  /// To change the value in terms of calendar units, see [modify].
  Expression<DateTime> operator +(Duration duration) {
    return _DependingOnDateTimeExpression(
      // Date times are integers (unix timestamps), so we can do arithmetic on
      // them directly.
      forTimestamps:
          (dartCast<int>() + Variable<int>(duration.inSeconds)).dartCast(),
      forIsoString:
          modify(DateTimeModifier.seconds(duration.inMilliseconds / 1000)),
    );
  }

  /// Subtracts [duration] from this date.
  ///
  /// Note that the curation is subtracted as a value in seconds. Thus,
  /// subtracting a `Duration(days: 1)` will not necessary yield the same time
  /// yesterday in all cases (due to daylight saving time switches). To change
  /// the value in terms of calendar units, see [modify].
  Expression<DateTime> operator -(Duration duration) {
    return _DependingOnDateTimeExpression(
      // Date times are integers (unix timestamps), so we can do arithmetic on
      // them directly.
      forTimestamps:
          (dartCast<int>() - Variable<int>(duration.inSeconds)).dartCast(),
      forIsoString:
          modify(DateTimeModifier.seconds(-duration.inMilliseconds / 1000)),
    );
  }
}

/// DateTime modifier constants.
///
/// These modifiers are used on [SqliteSpecificDateTimeOperators.modify] and
/// [SqliteSpecificDateTimeOperators.modifyAll] to apply transformations on date
/// time values.
///
/// For instance, [DateTimeModifier.days] can be used to add or subtract
/// calendar days from a date time value. Note that this is different from
/// just subtracting a duration with [DateTimeExpressions.+], which only adds a
/// duration as seconds without respecting calendar units.
///
/// For another explanation of modifiers, see the [sqlite3 docs].
///
/// [sqlite3 docs]: https://sqlite.org/lang_datefunc.html#modifiers
extension type const DateTimeModifier._(Literal<String> _inner)
    implements Literal<String> {
  /// Adds or subtracts [days] calendar days from the date time value.
  DateTimeModifier.days(int days) : this._(Literal('$days days'));

  /// Adds or subtracts [hours] hours from this date time value.
  DateTimeModifier.hours(int hours) : this._(Literal('$hours hours'));

  /// Adds or subtracts [minutes] minutes from this date time value.
  DateTimeModifier.minutes(int minutes) : this._(Literal('$minutes minutes'));

  /// Adds or subtracts [seconds] seconds from this date time value.
  ///
  /// Note that drift assumes date time values to be encoded as unix timestamps
  /// (with second accuracy) in the database. So adding seconds with a
  /// fractional value may not always be preserved in a chain of computation.
  DateTimeModifier.seconds(num seconds) : this._(Literal('$seconds seconds'));

  /// Adds or subtracts [months] months from this date time value.
  ///
  /// Note that this works by rendering the original date into the `YYYY-MM-DD`
  /// format, adding the [months] value to the `MM` field and normalizing the
  /// result. Thus, for example, the date 2001-03-31 modified by '+1 month'
  /// nitially yields 2001-04-31, but April only has 30 days so the date is
  /// normalized to 2001-05-01.
  DateTimeModifier.months(int months) : this._(Literal('$months months'));

  /// Adds or subtracts [years] years from this date time value.
  ///
  /// Similar to the transformation on [DateTimeModifier.months], it may not
  /// always be possible to keep the day and month field the same for this
  /// transformation. For instance, if the original date is February 29 of a
  /// leapyear and one year is added, the result will be in March 1 of the next
  /// year as there is no February 29.
  DateTimeModifier.years(int years) : this._(Literal('$years years'));

  /// The "start of day" modifier shifts the date backwards to the beginning of
  /// the day.
  const DateTimeModifier.startOfDay() : this._(const Literal('start of day'));

  /// The "start of month" modifier shifts the date backwards to the beginning
  /// of the month.
  const DateTimeModifier.startOfMonth()
      : this._(const Literal('start of month'));

  /// The "start of year" modifier shifts the date backwards to the beginning of
  /// the year.
  const DateTimeModifier.startOfYear() : this._(const Literal('start of year'));

  /// The "weekday" modifier shifts the date forward to the next date where the
  /// weekday is the [weekday] provided here.
  ///
  /// The [weekday] parameter must be a valid weekday from [DateTime.monday] to
  /// [DateTime.sunday].
  ///
  /// If the source date is on the desired weekday, no transformation happens.
  DateTimeModifier.weekday(int weekday)
      : this._(Literal('weekday ${weekday % 7}'));

  /// Move a date time that is in UTC to the local time zone.
  ///
  /// See also: [DateTime.toLocal].
  const DateTimeModifier.localTime() : this._(const Literal('localtime'));

  /// Move a date time that is in the local time zone back to UTC.
  ///
  /// See also: [DateTime.toLocal].
  const DateTimeModifier.utc() : this._(const Literal('utc'));

  const DateTimeModifier._unixEpoch() : this._(const Literal('unixepoch'));
}

final class _DependingOnDateTimeExpression<D extends Object>
    extends Expression<D> {
  final Expression<D> forTimestamps;
  final Expression<D> forIsoString;

  const _DependingOnDateTimeExpression({
    required this.forTimestamps,
    required this.forIsoString,
  });

  factory _DependingOnDateTimeExpression.generate(
    Expression<D> Function(bool datesAsText) generate,
  ) {
    return _DependingOnDateTimeExpression(
      forTimestamps: generate(false),
      forIsoString: generate(true),
    );
  }

  @override
  int get hashCode =>
      Object.hash(_DependingOnDateTimeExpression, forTimestamps, forIsoString);

  @override
  void compileWith(StatementCompiler compiler) {
    final storeAsText =
        (compiler.dialect as SqliteDialect).options.storeDateTimesAsText;
    return (storeAsText ? forIsoString : forTimestamps).compileWith(compiler);
  }

  @override
  bool operator ==(Object other) {
    return other is _DependingOnDateTimeExpression &&
        other.forTimestamps == forTimestamps &&
        other.forIsoString == forIsoString;
  }
}

/// Extension to use the `rowid` of a table in Dart queries.

extension RowIdExtension on GeneratedTable {
  /// In sqlite, each table that isn't virtual and hasn't been created with the
  /// `WITHOUT ROWID` modified has a [row id](https://www.sqlite.org/rowidtable.html).
  /// When the table has a single primary key column which is an integer, that
  /// column is an _alias_ to the row id in sqlite3.
  ///
  /// If the row id has not explicitly been declared as a column aliasing it,
  /// the [rowId] will not be part of a drift-generated data class. In this
  /// case, the [rowId] getter can be used to refer to a table's row id in a
  /// query.
  Expression<int> get rowId {
    if (withoutRowId || this is VirtualTableInfo) {
      throw ArgumentError('Cannot use rowId on a table without a rowid!');
    }

    return TableColumn<int>(
        name: '_rowid_', type: BuiltinDriftType.int, isNullable: false)
      ..owningResultSet = this;
  }
}
