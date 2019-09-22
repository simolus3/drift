import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/dart/parser.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:test/test.dart';

import '../../utils/test_backend.dart';

void main() {
  test('return expression of methods', () async {
    final backend = TestBackend({
      AssetId.parse('test_lib|lib/main.dart'): r'''
      class Test {
        String get getter => 'foo';
        String function() => 'bar';
        String invalid() {
         return 'baz';
        }
      }
    '''
    });

    final input = Uri.parse('package:test_lib/main.dart');
    final backendTask = backend.startTask(input);

    final library = await backendTask.resolveDart(input);
    final parser = MoorDartParser(ParseDartStep(null, null, library));

    Future<MethodDeclaration> _loadDeclaration(Element element) async {
      final declaration = await parser.loadElementDeclaration(element);
      return declaration.node as MethodDeclaration;
    }

    void _verifyReturnExpressionMatches(Element element, String source) async {
      final node = await _loadDeclaration(element);
      expect(parser.returnExpressionOfMethod(node).toSource(), source);
    }

    final testClass = library.getType('Test');

    _verifyReturnExpressionMatches(testClass.getGetter('getter'), "'foo'");
    _verifyReturnExpressionMatches(testClass.getMethod('function'), "'bar'");

    final invalidDecl = await _loadDeclaration(testClass.getMethod('invalid'));
    expect(parser.returnExpressionOfMethod(invalidDecl), isNull);
    expect(parser.step.errors.errors, isNotEmpty);

    backend.finish();
  });
}
