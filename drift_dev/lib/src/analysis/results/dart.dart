import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';

part '../../generated/analysis/results/dart.g.dart';

class AnnotatedDartCode {
  static final Uri drift = Uri.parse('package:drift/drift.dart');

  final List<dynamic /* String|DartTopLevelSymbol */ > elements;

  AnnotatedDartCode(this.elements);

  factory AnnotatedDartCode.ast(AstNode node) {
    return AnnotatedDartCode.build(((builder) => builder.addAstNode(node)));
  }

  factory AnnotatedDartCode.type(DartType type) {
    return AnnotatedDartCode.build(((builder) => builder.addDartType(type)));
  }

  factory AnnotatedDartCode.build(
      void Function(AnnotatedDartCodeBuilder builder) build) {
    final builder = AnnotatedDartCodeBuilder();
    build(builder);
    return builder.build();
  }

  factory AnnotatedDartCode.topLevelElement(Element element) {
    return AnnotatedDartCode([DartTopLevelSymbol.topLevelElement(element)]);
  }

  factory AnnotatedDartCode.fromJson(Map json) {
    final serializedElements = json['elements'] as List;

    return AnnotatedDartCode([
      for (final part in serializedElements)
        if (part is Map) DartTopLevelSymbol.fromJson(json) else part as String
    ]);
  }

  Map<String, Object?> toJson() {
    return {
      'elements': [
        for (final element in elements)
          if (element is DartTopLevelSymbol) element.toJson() else element
      ],
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    for (final entry in elements) {
      if (entry is DartTopLevelSymbol) {
        buffer.write(entry.lexeme);
      } else {
        buffer.write(entry);
      }
    }

    return buffer.toString();
  }
}

class AnnotatedDartCodeBuilder {
  final List<dynamic> _elements = [];
  final StringBuffer _pendingText = StringBuffer();

  void _addPendingText() {
    if (_pendingText.isNotEmpty) {
      _elements.add(_pendingText.toString());
      _pendingText.clear();
    }
  }

  void addText(String lexeme) => _pendingText.write(lexeme);

  void addSymbol(String lexeme, Uri? importUri) {
    _addPendingText();
    _elements.add(DartTopLevelSymbol(lexeme, importUri));
  }

  void addTopLevelElement(Element element) {
    _addPendingText();
    _elements.add(DartTopLevelSymbol.topLevelElement(element));
  }

  void addDartType(DartType type) {
    final visitor = _AddFromDartType(this);
    type.accept(visitor);
  }

  void addAstNode(AstNode node) {
    final visitor = _AddFromAst(this);
    node.accept(visitor);
  }

  AnnotatedDartCode build() {
    _addPendingText();
    return AnnotatedDartCode(_elements);
  }
}

@JsonSerializable()
class DartTopLevelSymbol {
  final String lexeme;
  final Uri? importUri;

  DartTopLevelSymbol(this.lexeme, this.importUri);

  factory DartTopLevelSymbol.topLevelElement(Element element) {
    assert(element.library?.topLevelElements.contains(element) == true);

    // We're using this to recover the right import URI when using
    // `package:build`:
    // https://github.com/dart-lang/build/blob/62cef9fae18dbde3ada7993986cca102270752d0/build_resolvers/lib/src/resolver.dart#L309-L319
    var sourceUri = element.library!.source.uri;
    if (sourceUri.isScheme('package') || sourceUri.isScheme('asset')) {
      sourceUri = AssetId.resolve(sourceUri).uri;
    }

    return DartTopLevelSymbol(element.name ?? '(???)', sourceUri);
  }

  factory DartTopLevelSymbol.fromJson(Map json) =>
      _$DartTopLevelSymbolFromJson(json);

  Map<String, Object?> toJson() => _$DartTopLevelSymbolToJson(this);
}

/// A visitor for Dart types automatically converting their representation to a
/// [AnnotatedDartCode].
///
/// This representation allwos emitting the Dart type with relevant imports
/// managed dynamically.
class _AddFromDartType extends TypeVisitor<void> {
  final AnnotatedDartCodeBuilder _builder;

  _AddFromDartType(this._builder);

  void _writeSuffix(NullabilitySuffix suffix) {
    switch (suffix) {
      case NullabilitySuffix.question:
        return _builder.addText('?');
      case NullabilitySuffix.star:
        return _builder.addText('*');
      case NullabilitySuffix.none:
        return;
    }
  }

  @override
  void visitRecordType(RecordType type) {
    throw UnsupportedError('RecordType to Dart source code');
  }

  @override
  void visitDynamicType(DynamicType type) {
    _builder.addText('dynamic');
    _writeSuffix(type.nullabilitySuffix);
  }

  @override
  void visitFunctionType(FunctionType type) {
    type.returnType.accept(this);

    _builder.addText(' Function');
    final formals = type.typeFormals;
    if (formals.isNotEmpty) {
      _builder.addText('<');
      var i = 0;
      for (final arg in formals) {
        if (i != 0) {
          _builder.addText(', ');
        }

        _builder.addText(arg.name);
        final bound = arg.bound;
        if (bound != null) {
          _builder.addText(' extends ');
          bound.accept(this);
        }
        i++;
      }
      _builder.addText('>');
    }

    // Write parameters
    _builder.addText('(');
    var i = 0;

    String? activeOptionalBlock;

    for (final parameter in type.parameters) {
      if (parameter.isNamed) {
        if (activeOptionalBlock == null) {
          _builder.addText('{');
          i = 0; // Don't put a comma before the first named parameter
          activeOptionalBlock = '}';
        }
      } else if (parameter.isOptionalPositional) {
        if (activeOptionalBlock == null) {
          _builder.addText('[');
          i = 0; // Don't put a comma before the first optional parameter
          activeOptionalBlock = ']';
        }
      }

      if (i != 0) {
        _builder.addText(', ');
      }

      parameter.type.accept(this);
      if (parameter.isNamed) {
        _builder.addText(' ${parameter.name}');
      }
      i++;
    }

    if (activeOptionalBlock != null) {
      _builder.addText(activeOptionalBlock);
    }

    _builder.addText(')');
    _writeSuffix(type.nullabilitySuffix);
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    final alias = type.alias;
    if (alias != null) {
      _builder.addTopLevelElement(alias.element);
    } else {
      _builder.addTopLevelElement(type.element2);
    }

    if (type.typeArguments.isNotEmpty) {
      _builder.addText('<');
      var i = 0;
      for (final arg in type.typeArguments) {
        if (i != 0) {
          _builder.addText(', ');
        }

        arg.accept(this);
        i++;
      }
      _builder.addText('>');
    }

    _writeSuffix(type.nullabilitySuffix);
  }

  @override
  void visitNeverType(NeverType type) {
    _builder.addText('Never');
    _writeSuffix(type.nullabilitySuffix);
  }

  @override
  void visitTypeParameterType(TypeParameterType type) {
    _builder.addText(type.element2.name);
    _writeSuffix(type.nullabilitySuffix);
  }

  @override
  void visitVoidType(VoidType type) {
    _builder.addText('void');
    _writeSuffix(type.nullabilitySuffix);
  }
}

class _AddFromAst extends GeneralizingAstVisitor<void> {
  final AnnotatedDartCodeBuilder _builder;

  _AddFromAst(this._builder);

  @override
  void visitNode(AstNode node) {
    int? offset;

    for (final childEntity in node.childEntities) {
      if (offset != null && childEntity.offset > offset) {
        _builder.addText(' ');
      }
      offset = childEntity.end;

      if (childEntity is Token) {
        _builder.addText(childEntity.lexeme);
      } else {
        (childEntity as AstNode).accept(this);
      }
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final targetOfPrefix = node.prefix.staticElement;
    if (targetOfPrefix is PrefixElement) {
      // Ignore the prefix: We will add it back either way when generating
      // imports in the generated code later.
      visitSimpleIdentifier(node.identifier);
    } else {
      super.visitPrefixedIdentifier(node);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final target = node.staticElement;
    final targetLibrary = target?.library;

    // Referencing an element from an import, add necessary import prefix.
    final isTopLevel = targetLibrary != null &&
        targetLibrary.topLevelElements.contains(target);

    if (isTopLevel) {
      _builder.addTopLevelElement(target!);
    } else {
      _builder.addText(node.name);
    }
  }
}
