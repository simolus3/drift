import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/analysis/types/types.dart';
import 'package:test/test.dart';

import '../data.dart';

void main() {
  final engine = SqlEngine(EngineOptions(driftOptions: const DriftSqlOptions()))
    ..registerTable(demoTable)
    ..registerTable(anotherTable);

  TypeResolver obtainResolver(String sql, {AnalyzeStatementOptions? options}) {
    final context = engine.analyze(sql, stmtOptions: options);
    return TypeResolver(TypeInferenceSession(context))..run(context.root);
  }

  ResolvedType? resolveFirstVariable(String sql,
      {AnalyzeStatementOptions? options}) {
    final resolver = obtainResolver(sql, options: options);
    final session = resolver.session;
    final variable =
        session.context.root.allDescendants.whereType<Variable>().first;
    return session.typeOf(variable);
  }

  ResolvedType? resolveResultColumn(String sql) {
    final resolver = obtainResolver(sql);
    final session = resolver.session;
    final stmt = session.context.root as SelectStatement;
    return session.typeOf(stmt.resolvedColumns!.single);
  }

  test('resolves literals', () {
    expect(resolveResultColumn('SELECT NULL'),
        const ResolvedType(type: BasicType.nullType, nullable: true));

    expect(resolveResultColumn('SELECT TRUE'), const ResolvedType.bool());
    expect(resolveResultColumn("SELECT x''"),
        const ResolvedType(type: BasicType.blob));
    expect(resolveResultColumn("SELECT ''"),
        const ResolvedType(type: BasicType.text));
    expect(resolveResultColumn('SELECT 3'),
        const ResolvedType(type: BasicType.int));
    expect(resolveResultColumn('SELECT 3.5'),
        const ResolvedType(type: BasicType.real));
  });

  test('infers boolean type in where conditions', () {
    expect(resolveFirstVariable('SELECT * FROM demo WHERE :foo'),
        const ResolvedType.bool());
  });

  test('does not infer boolean for grandchildren of where clause', () {
    expect(resolveFirstVariable("SELECT * FROM demo WHERE 'foo' = :foo"),
        const ResolvedType(type: BasicType.text));
  });

  test('infers boolean type in a join ON clause', () {
    expect(
      resolveFirstVariable('SELECT * FROM demo JOIN tbl ON :foo'),
      const ResolvedType.bool(),
    );
  });

  test('infers type in a string concatenation', () {
    expect(resolveFirstVariable("SELECT '' || :foo"),
        const ResolvedType(type: BasicType.text));
  });

  test('resolves arithmetic expressions', () {
    expect(resolveFirstVariable('SELECT ((3 + 4) * 5) = ?'),
        const ResolvedType(type: BasicType.int));
  });

  group('cast expressions', () {
    test('resolve to type argument', () {
      expect(resolveResultColumn('SELECT CAST(3+4 AS TEXT)'),
          const ResolvedType(type: BasicType.text));
    });

    test('allow anything as their operand', () {
      expect(resolveFirstVariable('SELECT CAST(? AS TEXT)'), null);
    });
  });

  group('iif', () {
    test('has type of arguments', () {
      expect(resolveResultColumn('SELECT IIF(false, 0, 1)'),
          const ResolvedType(type: BasicType.int));
    });

    test('is nullable if argument is', () {
      expect(resolveResultColumn('SELECT IIF(false, NULL, 1)'),
          const ResolvedType(type: BasicType.int, nullable: true));
    });

    test('is not nullable just because the condition is', () {
      expect(resolveResultColumn('SELECT IIF(NULL, 0, 1)'),
          const ResolvedType(type: BasicType.int));
    });

    test('infers one argument based on the other', () {
      expect(resolveFirstVariable('SELECT IIF(false, ?, 1)'),
          const ResolvedType(type: BasicType.int));
      expect(resolveFirstVariable('SELECT IIF(false, 0, ?)'),
          const ResolvedType(type: BasicType.int));
    });

    test('infers condition', () {
      expect(resolveFirstVariable('SELECT IIF(?, 0, 1)'),
          const ResolvedType(type: BasicType.int, hints: [IsBoolean()]));
    });
  });

  group('types in insert statements', () {
    test('for VALUES', () {
      final resolver =
          obtainResolver('INSERT INTO demo VALUES (:id, :content);');
      final root = resolver.session.context.root;
      final variables = root.allDescendants.whereType<Variable>();

      final idVar = variables.singleWhere((v) => v.resolvedIndex == 1);
      final contentVar = variables.singleWhere((v) => v.resolvedIndex == 2);

      expect(resolver.session.typeOf(idVar), id.type);
      expect(resolver.session.typeOf(contentVar), content.type);
    });

    test('for SELECT', () {
      final resolver = obtainResolver('INSERT INTO demo SELECT :id, :content');
      final root = resolver.session.context.root;
      final variables = root.allDescendants.whereType<Variable>();

      final idVar = variables.singleWhere((v) => v.resolvedIndex == 1);
      final contentVar = variables.singleWhere((v) => v.resolvedIndex == 2);

      expect(resolver.session.typeOf(idVar), id.type);
      expect(resolver.session.typeOf(contentVar), content.type);
    });
  });

  test('recognizes that variables are the same', () {
    // semantically, :var and ?1 are the same variable
    final type = resolveFirstVariable('SELECT :var WHERE ?1');
    expect(type, const ResolvedType.bool());
  });

  test('respects variable types set from options', () {
    const type = ResolvedType(type: BasicType.text);
    // should resolve to string, even though it would be a boolean normally
    final found = resolveFirstVariable(
      'SELECT * FROM demo WHERE ?',
      options: const AnalyzeStatementOptions(indexedVariableTypes: {1: type}),
    );

    expect(found, type);
  });

  test('handles LIMIT clauses', () {
    const int = ResolvedType(type: BasicType.int);

    final type = resolveFirstVariable('SELECT 0 LIMIT ?');
    expect(type, int);

    final offsetType = resolveFirstVariable('SELECT 0 LIMIT 1, ?');
    expect(offsetType, int);
  });

  test('handles string matching expressions', () {
    final type =
        resolveFirstVariable('SELECT * FROM demo WHERE content LIKE ?');
    expect(type, const ResolvedType(type: BasicType.text));

    final escapedType = resolveFirstVariable(
        "SELECT * FROM demo WHERE content LIKE 'foo' ESCAPE ?");
    expect(escapedType, const ResolvedType(type: BasicType.text));
  });

  group('function', () {
    test('timediff', () {
      final resultType = resolveResultColumn('SELECT timediff(?, ?)');
      final argType = resolveFirstVariable('SELECT timediff(?, ?)');

      expect(resultType, const ResolvedType(type: BasicType.text));
      expect(argType,
          const ResolvedType(type: BasicType.text, hints: [IsDateTime()]));
    });

    test('octet_length', () {
      expect(resolveResultColumn('SELECT octet_length(?)'),
          equals(const ResolvedType(type: BasicType.int)));
    });

    test('nth_value', () {
      final resolver = obtainResolver("SELECT nth_value('string', ?1) = ?2");
      final variables = resolver.session.context.root.allDescendants
          .whereType<Variable>()
          .iterator;
      variables.moveNext();
      final firstVar = variables.current;
      variables.moveNext();
      final secondVar = variables.current;

      expect(resolver.session.typeOf(firstVar),
          equals(const ResolvedType(type: BasicType.int)));

      expect(resolver.session.typeOf(secondVar),
          equals(const ResolvedType(type: BasicType.text)));
    });
  });

  group('case expressions', () {
    test('infers base clause from when', () {
      final type = resolveFirstVariable("SELECT CASE ? WHEN 1 THEN 'two' END");
      expect(type, const ResolvedType(type: BasicType.int));
    });

    test('infers when condition from base', () {
      final type = resolveFirstVariable("SELECT CASE 1 WHEN ? THEN 'two' END");
      expect(type, const ResolvedType(type: BasicType.int));
    });

    test('infers when conditions as boolean when no base is set', () {
      final type = resolveFirstVariable("SELECT CASE WHEN ? THEN 'two' END;");
      expect(type, const ResolvedType.bool());
    });

    test('infers type of whole when expression', () {
      final type = resolveResultColumn("SELECT CASE WHEN false THEN 'one' "
          "WHEN true THEN 'two' ELSE 'three' END;");
      expect(type, const ResolvedType(type: BasicType.text));
    });
  });

  test('can select columns', () {
    final type = resolveResultColumn('SELECT id FROM demo;');
    expect(type, const ResolvedType(type: BasicType.int));
  });

  test('infers type of EXISTS expressions', () {
    final type = resolveResultColumn('SELECT EXISTS(SELECT * FROM demo);');
    expect(type, const ResolvedType.bool());
  });

  test('resolves subqueries', () {
    final type = resolveResultColumn('SELECT (SELECT COUNT(*) FROM demo);');
    expect(type, const ResolvedType(type: BasicType.int));
  });

  test('infers types for dart placeholders', () {
    final resolver = obtainResolver(r'SELECT * FROM demo WHERE $pred');
    final type = resolver.session.typeOf(resolver
            .session.context.root.allDescendants
            .firstWhere((e) => e is DartExpressionPlaceholder)
        as DartExpressionPlaceholder);

    expect(type, const ResolvedType.bool());
  });

  test('supports unions', () {
    void check(String sql) {
      final resolver = obtainResolver(sql);
      final column = (resolver.session.context.root as CompoundSelectStatement)
          .resolvedColumns!
          .single;
      final type = resolver.session.typeOf(column)!;
      expect(type.type, BasicType.text);
      expect(type.nullable, isTrue);
    }

    check("SELECT 'foo' AS r UNION ALL SELECT NULL AS r");
    check("SELECT NULL AS r UNION ALL SELECT 'foo' AS r");
  });

  test('handles recursive CTEs', () {
    final type = resolveResultColumn('''
WITH RECURSIVE
  cnt(x) AS (
    SELECT 1
      UNION ALL
      SELECT x+1 FROM cnt
      LIMIT 1000000
    )
  SELECT x FROM cnt
      ''');

    expect(type, const ResolvedType(type: BasicType.int));
  });

  test('handles set components in updates', () {
    final type = resolveFirstVariable('UPDATE demo SET id = ?');
    expect(type, const ResolvedType(type: BasicType.int));
  });

  test('infers offsets in frame specs', () {
    final type = resolveFirstVariable('SELECT SUM(id) OVER (ROWS ? PRECEDING)');
    expect(type, const ResolvedType(type: BasicType.int));
  });

  test('resolves type hints from between expressions', () {
    const dateTime = ResolvedType(type: BasicType.int, hints: [IsDateTime()]);
    final session = obtainResolver(
      'SELECT 1 WHERE :date BETWEEN :start AND :end',
      options: const AnalyzeStatementOptions(
        namedVariableTypes: {':date': dateTime},
      ),
    ).session;

    Variable? start, end;
    for (final variable in session.context.root.allDescendants
        .whereType<ColonNamedVariable>()) {
      if (variable.name == ':start') start = variable;
      if (variable.name == ':end') end = variable;
    }
    assert(start != null && end != null);

    expect(session.typeOf(start!), dateTime);
    expect(session.typeOf(end!), dateTime);
  });

  group('IS IN expressions', () {
    test('infer the variable as an array type', () {
      final type = resolveFirstVariable('SELECT 3 IN ?');
      expect(type, const ResolvedType(type: BasicType.int, isArray: true));
    });

    test('does not infer the variable as an array when in a tuple', () {
      final type = resolveFirstVariable('SELECT 3 IN (?)');
      expect(type, const ResolvedType(type: BasicType.int, isArray: false));
    });
  });

  test('columns from LEFT OUTER joins are nullable', () {
    final resolver = obtainResolver('''
    WITH
     sq_1 (one ) AS (SELECT 1),
     sq_2 (two) AS (SELECT 2),
     sq_3 (three) AS (SELECT 3)

    SELECT one, two, three
     FROM sq_1
     LEFT JOIN sq_2
     LEFT OUTER JOIN sq_3
    ''');

    final session = resolver.session;
    final stmt = resolver.session.context.root as SelectStatement;
    final columns = stmt.resolvedColumns!;

    expect(session.typeOf(columns[0]), const ResolvedType(type: BasicType.int));
    expect(session.typeOf(columns[1]),
        const ResolvedType(type: BasicType.int, nullable: true));
    expect(session.typeOf(columns[2]),
        const ResolvedType(type: BasicType.int, nullable: true));
  });

  test('analyzes nested columns', () {
    engine.registerTableFromSql('''
      CREATE TABLE x (
        id INTEGER NOT NULL,
        other INTEGER
      );
    ''');

    final resolver = obtainResolver('''
      SELECT xxx.id FROM (
        SELECT * FROM (
          SELECT id FROM x
        ) xx
      ) xxx;
    ''');

    final session = resolver.session;
    final stmt = resolver.session.context.root as SelectStatement;
    final columns = stmt.resolvedColumns!;

    expect(columns, hasLength(1));
    expect(session.typeOf(columns[0]),
        const ResolvedType(type: BasicType.int, nullable: false));
  });
}
