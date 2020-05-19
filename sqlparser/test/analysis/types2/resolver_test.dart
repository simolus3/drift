import 'package:sqlparser/sqlparser.dart' hide TypeResolver;
import 'package:sqlparser/src/analysis/types2/types.dart';
import 'package:test/test.dart';

import '../data.dart';

void main() {
  final engine = SqlEngine(EngineOptions(useMoorExtensions: true))
    ..registerTable(demoTable)
    ..registerTable(anotherTable);

  TypeResolver _obtainResolver(String sql, {AnalyzeStatementOptions options}) {
    final context = engine.analyze(sql, stmtOptions: options);
    return TypeResolver(TypeInferenceSession(context))..run(context.root);
  }

  ResolvedType _resolveFirstVariable(String sql,
      {AnalyzeStatementOptions options}) {
    final resolver = _obtainResolver(sql, options: options);
    final session = resolver.session;
    final variable =
        session.context.root.allDescendants.whereType<Variable>().first;
    return session.typeOf(variable);
  }

  ResolvedType _resolveResultColumn(String sql) {
    final resolver = _obtainResolver(sql);
    final session = resolver.session;
    final stmt = session.context.root as SelectStatement;
    return session.typeOf(stmt.resolvedColumns.single);
  }

  test('resolves literals', () {
    expect(_resolveResultColumn('SELECT NULL'),
        const ResolvedType(type: BasicType.nullType, nullable: true));

    expect(_resolveResultColumn('SELECT TRUE'), const ResolvedType.bool());
    expect(_resolveResultColumn("SELECT x''"),
        const ResolvedType(type: BasicType.blob));
    expect(_resolveResultColumn("SELECT ''"),
        const ResolvedType(type: BasicType.text));
    expect(_resolveResultColumn('SELECT 3'),
        const ResolvedType(type: BasicType.int));
    expect(_resolveResultColumn('SELECT 3.5'),
        const ResolvedType(type: BasicType.real));
  });

  test('infers boolean type in where conditions', () {
    expect(_resolveFirstVariable('SELECT * FROM demo WHERE :foo'),
        const ResolvedType.bool());
  });

  test('does not infer boolean for grandchildren of where clause', () {
    expect(_resolveFirstVariable("SELECT * FROM demo WHERE 'foo' = :foo"),
        const ResolvedType(type: BasicType.text));
  });

  test('infers boolean type in a join ON clause', () {
    expect(
      _resolveFirstVariable('SELECT * FROM demo JOIN tbl ON :foo'),
      const ResolvedType.bool(),
    );
  });

  test('infers type in a string concatenation', () {
    expect(_resolveFirstVariable("SELECT '' || :foo"),
        const ResolvedType(type: BasicType.text));
  });

  test('resolves arithmetic expressions', () {
    expect(_resolveFirstVariable('SELECT ((3 + 4) * 5) = ?'),
        const ResolvedType(type: BasicType.int));
  });

  group('cast expressions', () {
    test('resolve to type argument', () {
      expect(_resolveResultColumn('SELECT CAST(3+4 AS TEXT)'),
          const ResolvedType(type: BasicType.text));
    });

    test('allow anything as their operand', () {
      expect(_resolveFirstVariable('SELECT CAST(? AS TEXT)'), null);
    });
  });

  group('types in insert statements', () {
    test('for VALUES', () {
      final resolver =
          _obtainResolver('INSERT INTO demo VALUES (:id, :content);');
      final root = resolver.session.context.root;
      final variables = root.allDescendants.whereType<Variable>();

      final idVar = variables.singleWhere((v) => v.resolvedIndex == 1);
      final contentVar = variables.singleWhere((v) => v.resolvedIndex == 2);

      expect(resolver.session.typeOf(idVar), id.type);
      expect(resolver.session.typeOf(contentVar), content.type);
    });

    test('for SELECT', () {
      final resolver = _obtainResolver('INSERT INTO demo SELECT :id, :content');
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
    final type = _resolveFirstVariable('SELECT :var WHERE ?1');
    expect(type, const ResolvedType.bool());
  });

  test('respects variable types set from options', () {
    const type = ResolvedType(type: BasicType.text);
    // should resolve to string, even though it would be a boolean normally
    final found = _resolveFirstVariable(
      'SELECT * FROM demo WHERE ?',
      options: const AnalyzeStatementOptions(indexedVariableTypes: {1: type}),
    );

    expect(found, type);
  });

  test('handles LIMIT clauses', () {
    const int = ResolvedType(type: BasicType.int);

    final type = _resolveFirstVariable('SELECT 0 LIMIT ?');
    expect(type, int);

    final offsetType = _resolveFirstVariable('SELECT 0 LIMIT 1, ?');
    expect(offsetType, int);
  });

  test('handles string matching expressions', () {
    final type =
        _resolveFirstVariable('SELECT * FROM demo WHERE content LIKE ?');
    expect(type, const ResolvedType(type: BasicType.text));

    final escapedType = _resolveFirstVariable(
        "SELECT * FROM demo WHERE content LIKE 'foo' ESCAPE ?");
    expect(escapedType, const ResolvedType(type: BasicType.text));
  });

  test('handles nth_value', () {
    final resolver = _obtainResolver("SELECT nth_value('string', ?1) = ?2");
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

  group('case expressions', () {
    test('infers base clause from when', () {
      final type = _resolveFirstVariable("SELECT CASE ? WHEN 1 THEN 'two' END");
      expect(type, const ResolvedType(type: BasicType.int));
    });

    test('infers when condition from base', () {
      final type = _resolveFirstVariable("SELECT CASE 1 WHEN ? THEN 'two' END");
      expect(type, const ResolvedType(type: BasicType.int));
    });

    test('infers when conditions as boolean when no base is set', () {
      final type = _resolveFirstVariable("SELECT CASE WHEN ? THEN 'two' END;");
      expect(type, const ResolvedType.bool());
    });

    test('infers type of whole when expression', () {
      final type = _resolveResultColumn("SELECT CASE WHEN false THEN 'one' "
          "WHEN true THEN 'two' ELSE 'three' END;");
      expect(type, const ResolvedType(type: BasicType.text));
    });
  });

  test('can select columns', () {
    final type = _resolveResultColumn('SELECT id FROM demo;');
    expect(type, const ResolvedType(type: BasicType.int));
  });

  test('resolves subqueries', () {
    final type = _resolveResultColumn('SELECT (SELECT COUNT(*) FROM demo);');
    expect(type, const ResolvedType(type: BasicType.int));
  });

  test('infers types for dart placeholders', () {
    final resolver = _obtainResolver(r'SELECT * FROM demo WHERE $pred');
    final type = resolver.session.typeOf(resolver
            .session.context.root.allDescendants
            .firstWhere((e) => e is DartExpressionPlaceholder)
        as DartExpressionPlaceholder);

    expect(type, const ResolvedType.bool());
  });

  test('handles recursive CTEs', () {
    final type = _resolveResultColumn('''
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
    final type = _resolveFirstVariable('UPDATE demo SET id = ?');
    expect(type, const ResolvedType(type: BasicType.int));
  });

  test('infers offsets in frame specs', () {
    final type =
        _resolveFirstVariable('SELECT SUM(id) OVER (ROWS ? PRECEDING)');
    expect(type, const ResolvedType(type: BasicType.int));
  });

  group('IS IN expressions', () {
    test('infer the variable as an array type', () {
      final type = _resolveFirstVariable('SELECT 3 IN ?');
      expect(type, const ResolvedType(type: BasicType.int, isArray: true));
    });

    test('does not infer the variable as an array when in a tuple', () {
      final type = _resolveFirstVariable('SELECT 3 IN (?)');
      expect(type, const ResolvedType(type: BasicType.int, isArray: false));
    });
  });
}
