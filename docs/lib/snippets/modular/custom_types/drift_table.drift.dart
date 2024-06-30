// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_docs/snippets/modular/custom_types/drift_table.drift.dart'
    as i1;
import 'package:drift_docs/snippets/modular/custom_types/type.dart' as i2;

class PeriodicReminders extends i0.Table
    with i0.TableInfo<PeriodicReminders, i1.PeriodicReminder> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  PeriodicReminders(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  static const i0.VerificationMeta _frequencyMeta =
      const i0.VerificationMeta('frequency');
  late final i0.GeneratedColumn<Duration> frequency =
      i0.GeneratedColumn<Duration>('frequency', aliasedName, false,
          type: const i2.DurationType(),
          requiredDuringInsert: true,
          $customConstraints: 'NOT NULL');
  static const i0.VerificationMeta _reminderMeta =
      const i0.VerificationMeta('reminder');
  late final i0.GeneratedColumn<String> reminder = i0.GeneratedColumn<String>(
      'reminder', aliasedName, false,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<i0.GeneratedColumn> get $columns => [id, frequency, reminder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'periodic_reminders';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.PeriodicReminder> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('reminder')) {
      context.handle(_reminderMeta,
          reminder.isAcceptableOrUnknown(data['reminder']!, _reminderMeta));
    } else if (isInserting) {
      context.missing(_reminderMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.PeriodicReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PeriodicReminder(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      frequency: attachedDatabase.typeMapping
          .read(const i2.DurationType(), data['${effectivePrefix}frequency'])!,
      reminder: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}reminder'])!,
    );
  }

  @override
  PeriodicReminders createAlias(String alias) {
    return PeriodicReminders(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PeriodicReminder extends i0.DataClass
    implements i0.Insertable<i1.PeriodicReminder> {
  final int id;
  final Duration frequency;
  final String reminder;
  const PeriodicReminder(
      {required this.id, required this.frequency, required this.reminder});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['frequency'] =
        i0.Variable<Duration>(frequency, const i2.DurationType());
    map['reminder'] = i0.Variable<String>(reminder);
    return map;
  }

  i1.PeriodicRemindersCompanion toCompanion(bool nullToAbsent) {
    return i1.PeriodicRemindersCompanion(
      id: i0.Value(id),
      frequency: i0.Value(frequency),
      reminder: i0.Value(reminder),
    );
  }

  factory PeriodicReminder.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PeriodicReminder(
      id: serializer.fromJson<int>(json['id']),
      frequency: serializer.fromJson<Duration>(json['frequency']),
      reminder: serializer.fromJson<String>(json['reminder']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'frequency': serializer.toJson<Duration>(frequency),
      'reminder': serializer.toJson<String>(reminder),
    };
  }

  i1.PeriodicReminder copyWith(
          {int? id, Duration? frequency, String? reminder}) =>
      i1.PeriodicReminder(
        id: id ?? this.id,
        frequency: frequency ?? this.frequency,
        reminder: reminder ?? this.reminder,
      );
  PeriodicReminder copyWithCompanion(i1.PeriodicRemindersCompanion data) {
    return PeriodicReminder(
      id: data.id.present ? data.id.value : this.id,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      reminder: data.reminder.present ? data.reminder.value : this.reminder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicReminder(')
          ..write('id: $id, ')
          ..write('frequency: $frequency, ')
          ..write('reminder: $reminder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, frequency, reminder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PeriodicReminder &&
          other.id == this.id &&
          other.frequency == this.frequency &&
          other.reminder == this.reminder);
}

class PeriodicRemindersCompanion
    extends i0.UpdateCompanion<i1.PeriodicReminder> {
  final i0.Value<int> id;
  final i0.Value<Duration> frequency;
  final i0.Value<String> reminder;
  const PeriodicRemindersCompanion({
    this.id = const i0.Value.absent(),
    this.frequency = const i0.Value.absent(),
    this.reminder = const i0.Value.absent(),
  });
  PeriodicRemindersCompanion.insert({
    this.id = const i0.Value.absent(),
    required Duration frequency,
    required String reminder,
  })  : frequency = i0.Value(frequency),
        reminder = i0.Value(reminder);
  static i0.Insertable<i1.PeriodicReminder> custom({
    i0.Expression<int>? id,
    i0.Expression<Duration>? frequency,
    i0.Expression<String>? reminder,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (frequency != null) 'frequency': frequency,
      if (reminder != null) 'reminder': reminder,
    });
  }

  i1.PeriodicRemindersCompanion copyWith(
      {i0.Value<int>? id,
      i0.Value<Duration>? frequency,
      i0.Value<String>? reminder}) {
    return i1.PeriodicRemindersCompanion(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      reminder: reminder ?? this.reminder,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (frequency.present) {
      map['frequency'] =
          i0.Variable<Duration>(frequency.value, const i2.DurationType());
    }
    if (reminder.present) {
      map['reminder'] = i0.Variable<String>(reminder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicRemindersCompanion(')
          ..write('id: $id, ')
          ..write('frequency: $frequency, ')
          ..write('reminder: $reminder')
          ..write(')'))
        .toString();
  }
}

typedef $PeriodicRemindersCreateCompanionBuilder = i1.PeriodicRemindersCompanion
    Function({
  i0.Value<int> id,
  required Duration frequency,
  required String reminder,
});
typedef $PeriodicRemindersUpdateCompanionBuilder = i1.PeriodicRemindersCompanion
    Function({
  i0.Value<int> id,
  i0.Value<Duration> frequency,
  i0.Value<String> reminder,
});

class $PeriodicRemindersFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.PeriodicReminders> {
  $PeriodicRemindersFilterComposer(super.$state);
  i0.ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<Duration> get frequency => $state.composableBuilder(
      column: $state.table.frequency,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<String> get reminder => $state.composableBuilder(
      column: $state.table.reminder,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));
}

class $PeriodicRemindersOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.PeriodicReminders> {
  $PeriodicRemindersOrderingComposer(super.$state);
  i0.ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<Duration> get frequency => $state.composableBuilder(
      column: $state.table.frequency,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<String> get reminder => $state.composableBuilder(
      column: $state.table.reminder,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $PeriodicRemindersTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.PeriodicReminders,
    i1.PeriodicReminder,
    i1.$PeriodicRemindersFilterComposer,
    i1.$PeriodicRemindersOrderingComposer,
    $PeriodicRemindersCreateCompanionBuilder,
    $PeriodicRemindersUpdateCompanionBuilder,
    (
      i1.PeriodicReminder,
      i0.BaseWithReferences<i0.GeneratedDatabase, i1.PeriodicReminder>
    ),
    i1.PeriodicReminder> {
  $PeriodicRemindersTableManager(
      i0.GeneratedDatabase db, i1.PeriodicReminders table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              i1.$PeriodicRemindersFilterComposer(i0.ComposerState(db, table)),
          orderingComposer: i1
              .$PeriodicRemindersOrderingComposer(i0.ComposerState(db, table)),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e, i0.BaseWithReferences(db, e))).toList(),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<Duration> frequency = const i0.Value.absent(),
            i0.Value<String> reminder = const i0.Value.absent(),
          }) =>
              i1.PeriodicRemindersCompanion(
            id: id,
            frequency: frequency,
            reminder: reminder,
          ),
          createCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            required Duration frequency,
            required String reminder,
          }) =>
              i1.PeriodicRemindersCompanion.insert(
            id: id,
            frequency: frequency,
            reminder: reminder,
          ),
        ));
}

typedef $PeriodicRemindersProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.PeriodicReminders,
    i1.PeriodicReminder,
    i1.$PeriodicRemindersFilterComposer,
    i1.$PeriodicRemindersOrderingComposer,
    $PeriodicRemindersCreateCompanionBuilder,
    $PeriodicRemindersUpdateCompanionBuilder,
    (
      i1.PeriodicReminder,
      i0.BaseWithReferences<i0.GeneratedDatabase, i1.PeriodicReminder>
    ),
    i1.PeriodicReminder>;
