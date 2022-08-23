import 'package:sqlparser/sqlparser.dart';

class Spellfix1Extension implements Extension {
  const Spellfix1Extension();

  @override
  void register(SqlEngine engine) {
    engine.registerModule(_Spellfix1Module());
  }
}

class _Spellfix1Module extends Module {
  _Spellfix1Module() : super('spellfix1');

  @override
  Table parseTable(CreateVirtualTableStatement stmt) {
    return Table(
        name: stmt.tableName,
        resolvedColumns: [
          TableColumn('word', const ResolvedType(type: BasicType.text)),
          TableColumn(
              'rank', const ResolvedType(type: BasicType.int, nullable: true)),
          TableColumn('distance',
              const ResolvedType(type: BasicType.int, nullable: true)),
          TableColumn('langid',
              const ResolvedType(type: BasicType.int, nullable: true)),
          TableColumn(
              'score', const ResolvedType(type: BasicType.int, nullable: true)),
          TableColumn('matchlen',
              const ResolvedType(type: BasicType.int, nullable: true)),
          HiddenColumn(
            'top',
            const ResolvedType(type: BasicType.int),
          ),
          HiddenColumn(
            'scope',
            const ResolvedType(type: BasicType.int),
          ),
          HiddenColumn(
            'srchcnt',
            const ResolvedType(type: BasicType.int),
          ),
          HiddenColumn(
            'soundslike',
            const ResolvedType(type: BasicType.text),
          ),
          HiddenColumn(
            'command',
            const ResolvedType(type: BasicType.int),
          ),
        ],
        definition: stmt,
        isVirtual: true);
  }
}
