import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';

import 'element.dart';
import 'query.dart';
import 'result_sets.dart';
import 'types.dart';

part '../../generated/analysis/results/dart.g.dart';

/// A syntactic representation of Dart code where top-level symbols (that would)
/// have to be imported are explicitly represented with their defining URL.
///
/// This allows generating code with independent import management.
class AnnotatedDartCode {
  static final Uri dartAsync = Uri.parse('dart:async');
  static final Uri dartCore = Uri.parse('dart:core');
  static final Uri drift = Uri.parse('package:drift/drift.dart');

  final List<DartCodeElement> elements;

  AnnotatedDartCode(this.elements);

  AnnotatedDartCode.text(String e) : elements = [DartLexeme(e)];

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
      for (final part in serializedElements) DartCodeElement.fromJson(part)
    ]);
  }

  factory AnnotatedDartCode.importedSymbol(Uri uri, String name) {
    return AnnotatedDartCode([DartTopLevelSymbol(name, uri)]);
  }

  Map<String, Object?> toJson() {
    return {
      'elements': [for (final element in elements) element.toJson()],
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
  final List<DartCodeElement> _elements = [];
  final StringBuffer _pendingText = StringBuffer();

  void _addPendingText() {
    if (_pendingText.isNotEmpty) {
      _elements.add(DartLexeme(_pendingText.toString()));
      _pendingText.clear();
    }
  }

  void addText(String lexeme) => _pendingText.write(lexeme);

  void addCode(AnnotatedDartCode code) {
    _addPendingText();
    _elements.addAll(code.elements);
  }

  void addSymbol(String lexeme, Uri? importUri) {
    _addPendingText();
    _elements.add(DartTopLevelSymbol(lexeme, importUri));
  }

  void addTopLevel(DartTopLevelSymbol symbol) {
    _addPendingText();
    _elements.add(symbol);
  }

  void addTopLevelElement(Element element) {
    _addPendingText();
    _elements.add(DartTopLevelSymbol.topLevelElement(element));
  }

  void addTagged(String lexeme, String tag) {
    _addPendingText();
    _elements.add(TaggedDartLexeme(lexeme, tag));
  }

  void addDartType(DartType type) {
    type.accept(_AddFromDartType(this));
  }

  void addAstNode(
    AstNode node, {
    Set<AstNode> exclude = const {},
    Map<Element, String> taggedElements = const {},
  }) {
    final visitor = _AddFromAst(this, exclude, taggedElements);
    node.accept(visitor);
  }

  /// Writes the Dart type of a drift column.
  void addDriftType(HasType hasType) {
    void addNonListType() {
      final converter = hasType.typeConverter;

      if (converter != null) {
        final nullable = converter.canBeSkippedForNulls && hasType.nullable;

        addDartType(converter.dartType);
        if (nullable) addText('?');
      } else {
        switch (hasType.sqlType) {
          case ColumnDriftType():
            addTopLevel(dartTypeNames[hasType.sqlType.builtin]!);
          case ColumnCustomType(:final custom):
            addDartType(custom.dartType);
        }
        if (hasType.nullable) addText('?');
      }
    }

    if (hasType.isArray) {
      addSymbol('List', AnnotatedDartCode.dartCore);
      addText('<');
      addNonListType();
      addText('>');
    } else {
      addNonListType();
    }
  }

  void addGeneratedElement(DriftElement element, String dartName) {
    addSymbol(dartName, element.id.modularImportUri);
  }

  /// Writes the row type used to represent a row in [element], which is either
  /// a table or a view.
  void addElementRowType(DriftElementWithResultSet element) {
    final existing = element.existingRowClass;
    if (existing != null && !existing.isRecord) {
      addDartType(existing.targetType);
    } else {
      addGeneratedElement(element, element.nameOfRowClass);
    }
  }

  void addQueryResultRowType(SqlQuery query) {
    final resultSet = query.resultSet;
    if (resultSet == null) {
      throw ArgumentError(
          'This query (${query.name}) does not have a result set');
    }

    addResultSetRowType(resultSet, () => query.resultClassName);
  }

  void addResultSetRowType(
      InferredResultSet resultSet, String Function() resultClassName) {
    if (resultSet.existingRowType != null) {
      return addCode(resultSet.existingRowType!.rowType);
    }

    if (resultSet.matchingTable != null) {
      return addElementRowType(resultSet.matchingTable!.table);
    }

    if (resultSet.singleColumn) {
      return addDriftType(resultSet.scalarColumns.single);
    }

    return addText(resultClassName());
  }

  void addTypeOfNestedResult(NestedResult nested) {
    if (nested is NestedResultTable) {
      return addResultSetRowType(
          nested.innerResultSet, () => nested.nameForGeneratedRowClass);
    } else if (nested is NestedResultQuery) {
      addSymbol('List', AnnotatedDartCode.dartCore);
      addText('<');
      addQueryResultRowType(nested.query);
      addText('>');
    } else {
      throw ArgumentError.value(nested, 'nested', 'Unknown nested type');
    }
  }

  AnnotatedDartCode build() {
    _addPendingText();
    return AnnotatedDartCode(_elements);
  }
}

sealed class DartCodeElement {
  Object? toJson();

  factory DartCodeElement.fromJson(Object? json) {
    return switch (json) {
      String s => DartLexeme(s),
      {'import_uri': _} => DartTopLevelSymbol.fromJson(json),
      {'tag': _} => TaggedDartLexeme.fromJson(json),
      _ => throw ArgumentError.value(json, 'json', 'Unknown code element'),
    };
  }
}

final class DartLexeme implements DartCodeElement {
  final String lexeme;

  const DartLexeme(this.lexeme);

  @override
  Object? toJson() {
    return lexeme;
  }

  @override
  String toString() {
    return lexeme;
  }
}

/// A variant of [DartLexeme] with a custom associated [tag].
///
/// For a motivation, see `ColumnParser._columnsInSameTable` - essentially, some
/// drift tools need to resolve column references in Dart code to rewrite them
/// depending on the generation mode.
@JsonSerializable()
final class TaggedDartLexeme implements DartCodeElement {
  final String lexeme;
  final String tag;

  TaggedDartLexeme(this.lexeme, this.tag);

  factory TaggedDartLexeme.fromJson(Map json) =>
      _$TaggedDartLexemeFromJson(json);

  @override
  Map<String, Object?> toJson() => _$TaggedDartLexemeToJson(this);

  @override
  String toString() {
    return lexeme;
  }
}

/// A variant of [DartLexeme] that is used for top-level elements to also store
/// the import URI. This allows drift's code generator, when encountering such
/// element, to automatically add the relevant import to generated Dart files.
@JsonSerializable()
final class DartTopLevelSymbol implements DartCodeElement {
  static final _driftUri = Uri.parse('package:drift/drift.dart');

  static final list = DartTopLevelSymbol('List', AnnotatedDartCode.dartCore);

  final String lexeme;
  final Uri? importUri;

  const DartTopLevelSymbol(this.lexeme, this.importUri);

  factory DartTopLevelSymbol.drift(String name) {
    return DartTopLevelSymbol(name, _driftUri);
  }

  factory DartTopLevelSymbol.topLevelElement(Element element,
      [String? elementName]) {
    assert(element.library?.topLevelElements.contains(element) == true,
        '${element.name} is not a top-level element');

    // We're using this to recover the right import URI when using
    // `package:build`:
    // https://github.com/dart-lang/build/blob/62cef9fae18dbde3ada7993986cca102270752d0/build_resolvers/lib/src/resolver.dart#L309-L319
    var sourceUri = element.library!.source.uri;
    if (sourceUri.isScheme('package') || sourceUri.isScheme('asset')) {
      sourceUri = AssetId.resolve(sourceUri).uri;
    }

    return DartTopLevelSymbol(
        elementName ?? element.name ?? '(???)', sourceUri);
  }

  factory DartTopLevelSymbol.fromJson(Map json) =>
      _$DartTopLevelSymbolFromJson(json);

  @override
  Map<String, Object?> toJson() => _$DartTopLevelSymbolToJson(this);
}

/// A visitor for Dart types automatically converting their representation to a
/// [AnnotatedDartCode].
///
/// This representation allwos emitting the Dart type with relevant imports
/// managed dynamically.
class _AddFromDartType extends UnifyingTypeVisitor<void> {
  final AnnotatedDartCodeBuilder _builder;

  _AddFromDartType(this._builder);

  void _writeSuffix(NullabilitySuffix suffix) {
    switch (suffix) {
      case NullabilitySuffix.question:
        return _builder.addText('?');
      case NullabilitySuffix.star:
      // Really, the star suffix should never occur since we only support null-
      // safe code. However, the analyzer seems to report this suffix for
      // interface types in annotations.
      case NullabilitySuffix.none:
        return;
    }
  }

  @override
  void visitDartType(DartType type) {
    _builder
      ..addText('dynamic')
      ..addText(
          '/* unhandled ${type.getDisplayString(withNullability: true)} */'); // ignore: deprecated_member_use
  }

  @override
  void visitRecordType(RecordType type) {
    _builder.addText('(');
    var first = true;

    for (final field in type.positionalFields) {
      if (!first) {
        _builder.addText(', ');
      }
      first = false;

      field.type.accept(this);
    }

    if (type.namedFields.isNotEmpty) {
      _builder.addText('{');
      first = true;
      for (final field in type.namedFields) {
        if (!first) {
          _builder.addText(', ');
        }
        first = false;

        field.type.accept(this);
        _builder
          ..addText(' ')
          ..addText(field.name);
      }
      _builder.addText('}');
    }

    _builder.addText(')');
    _writeSuffix(type.nullabilitySuffix);
  }

  @override
  void visitDynamicType(DynamicType type) {
    _builder.addText('dynamic');
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
      _builder.addTopLevelElement(type.element);
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
  void visitInvalidType(InvalidType type) {
    _builder
      ..addText('dynamic')
      ..addText('/* = invalid*/');
  }

  @override
  void visitNeverType(NeverType type) {
    _builder.addText('Never');
    _writeSuffix(type.nullabilitySuffix);
  }

  @override
  void visitTypeParameterType(TypeParameterType type) {
    _builder.addText(type.element.name);
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
  final Set<AstNode> _excluding;
  final Map<Element, String> _taggedElements;

  _AddFromAst(this._builder, this._excluding, this._taggedElements);

  void _addTopLevelReference(Element? element, Token name2) {
    if (element == null || (element.isSynthetic && element.library == null)) {
      _builder.addText(name2.lexeme);
    } else {
      _builder.addTopLevel(
          DartTopLevelSymbol.topLevelElement(element, name2.lexeme));
    }
  }

  void _visitCommaSeparated(NodeList nodes) {
    var first = true;
    for (final arg in nodes) {
      if (!first) _builder.addText(',');

      arg.accept(this);
      first = false;
    }
  }

  void _childEntities(Iterable<SyntacticEntity> childEntities) {
    int? offset;

    for (final childEntity in childEntities) {
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
  void visitNode(AstNode node) {
    if (_excluding.contains(node)) return;
    _childEntities(node.childEntities);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    // Workaround to the analyzer not including commas: https://github.com/dart-lang/sdk/blob/20ad5db3ab3f2ae49f9668b75331e51c84267011/pkg/analyzer/lib/src/dart/ast/ast.dart#L389
    _builder.addText('(');
    _visitCommaSeparated(node.arguments);
    _builder.addText(')');
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _addTopLevelReference(node.element, node.name); // Transform identifier
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Rewrite extension invocations (e.g. `myList.indexed`) to explicitly
    // mention the extension in use (e.g `IterableExtensions(myList).indexed`).
    // This is because extensions aren't visible as soon as the library defining
    // them is imported under an import alias. Explicitly mentioning the
    // extension fixes this problem.
    if (node.target == null || node.realTarget != node.target) {
      // Unfortunately there's no easy way to apply this to cascade expressions
      return super.visitMethodInvocation(node);
    }

    final element = node.methodName.staticElement;
    final enclosing = element?.enclosingElement;
    if (enclosing is! ExtensionElement || enclosing.name == null) {
      return super.visitMethodInvocation(node);
    }

    _builder
      ..addTopLevel(
          DartTopLevelSymbol.topLevelElement(enclosing, enclosing.name!))
      ..addText('(');
    node.target?.accept(this);
    _builder
      ..addText(node.isNullAware ? ')?.' : ').')
      ..addText(node.methodName.name);

    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    _addTopLevelReference(node.element, node.name2);
    if (node.typeArguments case final typeArgs?) {
      visitTypeArgumentList(typeArgs);
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
    } else if (_taggedElements[target] case final tag?) {
      _builder.addTagged(node.token.lexeme, tag);
    } else {
      _builder.addText(node.name);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _childEntities(
        [node.constKeyword, node.typeArguments, node.leftBracket].whereType());
    _visitCommaSeparated(node.elements);
    _childEntities([node.rightBracket]);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _childEntities(
        [node.constKeyword, node.typeArguments, node.leftBracket].whereType());
    _visitCommaSeparated(node.elements);
    _childEntities([node.rightBracket]);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _builder.addText('<');
    _visitCommaSeparated(node.arguments);
    _builder.addText('>');
  }
}
