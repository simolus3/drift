import 'package:benchmarks/benchmarks.dart';
import 'package:sqlparser/sqlparser.dart';

const file = '''

foo: SELECT
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    o_orderdate,
    o_shippriority
  FROM
    customer,
    orders,
    lineitem
  WHERE
    c_mktsegment = '%s'
    and c_custkey = o_custkey
    and l_orderkey = o_orderkey
    and o_orderdate < '%s'
    and l_shipdate > '%s'
  GROUP BY
    l_orderkey,
    o_orderdate,
    o_shippriority
  ORDER BY
    revenue DESC,
    o_orderdate;

manyColumns:
  SELECT a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z FROM test;
''';

class ParseDriftFile extends BenchmarkBase {
  ParseDriftFile(ScoreEmitter emitter)
      : super('Moor file: Parse only', emitter);

  final _engine = SqlEngine(EngineOptions(useDriftExtensions: true));

  @override
  void exercise() {
    for (var i = 0; i < 10; i++) {
      assert(_engine.parseDriftFile(file).errors.isEmpty);
    }
  }

  @override
  void run() {
    _engine.parseDriftFile(file);
  }
}
