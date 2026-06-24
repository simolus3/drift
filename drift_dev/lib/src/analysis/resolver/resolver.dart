import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/find_referenced_tables.dart';

import '../driver/driver.dart';
import '../driver/error.dart';
import '../driver/state.dart';
import '../results/element.dart';

import '../serializer.dart';
import 'dart/accessor.dart' as dart_accessor;
import 'dart/index.dart' as dart_index;
import 'dart/table.dart' as dart_table;
import 'dart/view.dart' as dart_view;
import 'drift/element_resolver.dart';
import 'drift/index.dart' as drift_index;
import 'drift/query.dart' as drift_query;
import 'drift/table.dart' as drift_table;
import 'drift/trigger.dart' as drift_trigger;
import 'drift/view.dart' as drift_view;
import 'intermediate_state.dart';

/// Analyzes and resolves drift elements.
final class DriftResolver {
  final DriftAnalysisDriver driver;
  final DriftElementId _entrypoint;

  final Map<DriftElementId, _ResolvingOrCachedElement> _involvedElements = {};

  late final ElementDeserializer _deserializer = ElementDeserializer(
    driver,
    // TODO: Track dependencies here??
    [],
  );

  DriftResolver(this.driver, this._entrypoint);

  Future<DriftElement> resolveEntrypoint() async {
    final resolved = await _restoreOrResolve(_entrypoint);

    // At this stage, all dependencies are part of _involvedElements. Let's
    // resolve them!
    final groups = stronglyConnectedComponents(_DependencyGraph(this));
    for (final group in groups) {
      for (final pending in group) {
        if (pending is _ResolvingElement) {
          final intermediate = pending.intermediate!;
          pending.state.result = intermediate.element;
          pending.intermediate!.resolve(ResolvedDependencies._(this));
        }

        pending.state.isUpToDate = true;
      }
    }

    return resolved.state.result!;
  }

  Future<_ResolvingOrCachedElement> _restoreOrResolve(
    DriftElementId element,
  ) async {
    if (_involvedElements[element] case final involved?) {
      return involved;
    }

    final existing =
        driver.cache.knownFiles[element.libraryUri]?.analysis[element];
    if (existing != null && existing.isUpToDate) {
      final existingElement = existing.result!;
      final resolving = _ExternallyResolvedElement(
        token: DependencyToken(existingElement.reference, existingElement.kind),
        state: existing,
      );
      _involvedElements[element] = resolving;
      return resolving;
    }

    try {
      if (await driver.readStoredAnalysisResult(element.libraryUri) != null) {
        final resolvedElement = await _deserializer.readDriftElement(element);
        final state = driver.cache
            .stateForUri(element.libraryUri)
            .analysis[element]!;
        state.result = resolvedElement;

        final resolving = _ExternallyResolvedElement(
          token: DependencyToken(
            resolvedElement.reference,
            resolvedElement.kind,
          ),
          state: state,
        );
        _involvedElements[element] = resolving;
        return resolving;
      }
    } on CouldNotDeserializeException catch (e, s) {
      driver.backend.log.warning('Could not deserialize $element', e, s);
      if (driver.isTesting) {
        rethrow;
      }
    }

    // We can't resolve the element from cache, so we need to resolve it.
    final owningFile = driver.cache.stateForUri(element.libraryUri);
    await driver.discoverIfNecessary(owningFile);
    final discovered = owningFile.discovery!.locallyDefinedElements.firstWhere(
      (e) => e.ownId == element,
    );

    return await _resolveDependencies(discovered);
  }

  /// Runs the first step of the two-stage resolving process.
  Future<_ResolvingElement> _resolveDependencies(
    DiscoveredElement discovered,
  ) async {
    final fileState = driver.cache.knownFiles[discovered.ownId.libraryUri]!;
    final elementState = fileState.analysis.putIfAbsent(
      discovered.ownId,
      () => ElementAnalysisState(discovered.ownId),
    );

    elementState.errorsDuringAnalysis.clear();

    final pending = _ResolvingElement(
      token: DependencyToken(
        DriftElementReference(discovered.ownId),
        discovered.kind,
      ),
      state: elementState,
    );
    final dependencyAware = DependencyAwareResolver._(pending, this);
    _involvedElements[discovered.ownId] = pending;

    final TwoStageElementResolver resolver = switch (discovered) {
      DiscoveredDriftTable() => drift_table.DriftTableResolver(
        fileState,
        discovered,
        dependencyAware,
        elementState,
      ),
      DiscoveredDriftIndex() => drift_index.DriftIndexResolver(
        fileState,
        discovered,
        dependencyAware,
        elementState,
      ),
      DiscoveredDriftStatement() => drift_query.DriftQueryResolver(
        fileState,
        discovered,
        dependencyAware,
        elementState,
      ),
      DiscoveredDriftTrigger() => drift_trigger.DriftTriggerResolver(
        fileState,
        discovered,
        dependencyAware,
        elementState,
      ),
      DiscoveredDriftView() => drift_view.DriftViewResolver(
        fileState,
        discovered,
        dependencyAware,
        elementState,
      ),
      DiscoveredDartTable() => dart_table.DartTableResolver(
        fileState,
        discovered,
        dependencyAware,
        elementState,
      ),
      DiscoveredDartView() => dart_view.DartViewResolver(
        fileState,
        discovered,
        dependencyAware,
        elementState,
      ),
      DiscoveredDartIndex() => dart_index.DartIndexResolver(
        fileState,
        discovered,
        dependencyAware,
        elementState,
      ),
      DiscoveredBaseAccessor() => dart_accessor.DartAccessorResolver(
        fileState,
        discovered,
        dependencyAware,
        elementState,
      ),
      _ => throw UnimplementedError('TODO: Handle $discovered'),
    };

    pending.resolver = resolver;
    pending.intermediate = await resolver.buildPending();
    return pending;
  }

  /// Attempts to resolve a dependency for an element if that is allowed.
  ///
  /// It usually _is_ allowed, but there could be a forbidden circular reference
  /// in which case the reference is reported to be unavailable.
  /// Further, an internal bug in the analyzer could cause a crash analyzing
  /// the element. To not cause the entire analysis run to fail, this reports
  /// an error message and otherwise continues analysis of other elements.
  Future<ResolveReferencedElementResult> resolveReferencedElement(
    DriftElementId owner,
    DriftElementId reference,
  ) async {
    if (_involvedElements[reference] case final alreadyTracked?) {
      return ResolvedReferenceFound(alreadyTracked.token);
    }

    final pending = driver.cache.discoveredElements[reference];
    if (pending != null) {
      // We know the element exists, but we haven't resolved it yet.
      try {
        final resolved = await _restoreOrResolve(reference);
        return ResolvedReferenceFound(resolved.token);
      } catch (e, s) {
        driver.backend.log.warning('Could not analyze $reference', e, s);
        return ReferencedElementCouldNotBeResolved();
      }
    }

    throw StateError(
      'Unknown pending element $reference, this is a bug in drift_dev',
    );
  }
}

final class DependencyAwareResolver {
  final _ResolvingElement _ownElement;
  final DriftResolver _resolver;
  final Set<DriftElementReference> _references = {};

  DependencyAwareResolver._(this._ownElement, this._resolver);

  DriftAnalysisDriver get driver => _resolver.driver;

  DriftElementReference get ownElementReference => _ownElement.token.reference;

  List<DriftElementReference> get references => _references.toList();

  Future<ResolveReferencedElementResult> resolveReferencedElement(
    DriftElementId reference,
  ) async {
    _ownElement.dependencies.add(reference);
    final resolved = await _resolver.resolveReferencedElement(
      _ownElement.token.id,
      reference,
    );
    if (resolved case ResolvedReferenceFound(:final token)) {
      _references.add(token.reference);
    }

    return resolved;
  }

  /// Resolves a reference in SQL.
  ///
  /// This works by looking at known imports of the file defining the [owner]
  /// and using the results of the discovery step to find a known element with
  /// the same name. If one exists, it is resolved and returned. Otherwise, an
  /// error result is returned.
  Future<ResolveReferencedElementResult> resolveReference(
    String reference,
  ) async {
    final candidates = <DriftElementId>[];
    final owner = _ownElement.token.id;
    final file = driver.cache.knownFiles[owner.libraryUri]!;

    for (final available in driver.cache.crawl(file)) {
      final localElementIds = {
        ...available.analysis.keys,
        ...available.definedElements.map((e) => e.ownId),
      };

      for (final definedLocally in localElementIds) {
        if (definedLocally.sameName(reference)) {
          candidates.add(definedLocally);
        }
      }
    }

    if (candidates.isEmpty) {
      return InvalidReferenceResult(
        InvalidReferenceError.noElementWithSuchName,
        '`$reference` could not be found in any import.',
      );
    } else if (candidates.length > 1) {
      final description = candidates
          .map((c) => '`${c.name}` in `${c.libraryUri}`')
          .join(', ');

      return InvalidReferenceResult(
        InvalidReferenceError.ambigiousElements,
        'Ambigious reference, it could refer to any of: $description',
      );
    }

    return resolveReferencedElement(candidates.single);
  }

  /// Resolves a Dart element reference, if the referenced Dart [element]
  /// defines an element understood by drift.
  Future<ResolveReferencedElementResult> resolveDartReference(
    DriftElementId owner,
    Element element,
  ) async {
    final uri = await driver.backend.uriOfDart(element.library!);
    final state = driver.cache.stateForUri(uri);

    final existing = state.definedElements.firstWhereOrNull(
      (existing) => existing.dartElementName == element.name,
    );

    if (existing != null) {
      return resolveReferencedElement(existing.ownId);
    } else {
      return InvalidReferenceResult(
        InvalidReferenceError.noElementWithSuchName,
        'The referenced element, ${element.name}, is not understood by drift.',
      );
    }
  }
}

final class ResolvedDependencies {
  final DriftResolver _resolver;

  ResolvedDependencies._(this._resolver);

  DriftElement resolve(DependencyToken token) {
    return _resolver._involvedElements[token.id]!.state.result!;
  }

  DriftElement? resolveNullable(DependencyToken? token) {
    return token == null ? null : resolve(token);
  }
}

/// A token for a dependency that is guaranteed to be resolvable.
///
/// We return this instead of the resolved element to support circular
/// references in a two-step resolve procedure.
final class DependencyToken {
  final DriftElementReference reference;
  final DriftElementKind kind;

  DriftElementId get id => reference.id;

  DependencyToken(this.reference, this.kind);
}

abstract class TwoStageElementResolver<T extends DiscoveredElement> {
  final FileState file;
  final T discovered;
  final DependencyAwareResolver resolver;
  final ElementAnalysisState state;

  TwoStageElementResolver(
    this.file,
    this.discovered,
    this.resolver,
    this.state,
  );

  void reportError(DriftAnalysisError error) {
    state.errorsDuringAnalysis.add(error);
  }

  Future<DependencyToken?> resolveSqlReferenceOrReportError(
    String reference,
    DriftAnalysisError Function(String msg) createError, {
    DriftElementKind? enforceKind,
  }) async {
    final result = await resolver.resolveReference(reference);
    if (result case InvalidReferenceResult(
      error: InvalidReferenceError.noElementWithSuchName,
    )) {
      final knownTables = resolver.driver.options.sqliteOptions?.knownTables;
      if (knownTables != null && knownTables.any((e) => e.name == reference)) {
        // This table is external, no need to emit a warning.
        return null;
      }
    }

    return handleReferenceResult(result, createError, enforceKind: enforceKind);
  }

  Future<DependencyToken?> resolveDartReferenceOrReportError(
    Element reference,
    DriftAnalysisError Function(String msg) createError, {
    DriftElementKind? enforceKind,
  }) async {
    final result = await resolver.resolveDartReference(
      discovered.ownId,
      reference,
    );
    return handleReferenceResult(result, createError, enforceKind: enforceKind);
  }

  DependencyToken? handleReferenceResult(
    ResolveReferencedElementResult result,
    DriftAnalysisError Function(String msg) createError, {
    DriftElementKind? enforceKind,
  }) {
    if (result is ResolvedReferenceFound) {
      if (enforceKind != null && result.token.kind != enforceKind) {
        reportError(
          createError(
            'Expected a ${enforceKind.name}, but ${result.token.id.name} is a ${enforceKind.name}',
          ),
        );
        return null;
      }

      return result.token;
    } else {
      reportErrorForUnresolvedReference(result, createError);
      return null;
    }
  }

  void reportErrorForUnresolvedReference(
    ResolveReferencedElementResult result,
    DriftAnalysisError Function(String msg) createError,
  ) {
    if (result is InvalidReferenceResult) {
      reportError(createError(result.message));
    } else if (result is ReferencedElementCouldNotBeResolved) {
      reportError(
        createError(
          'The referenced element could not be analyzed due to a bug in drift.',
        ),
      );
    }
  }

  Future<SqlEngine Function(ResolvedDependencies)> newEngineWithTables(
    Iterable<DependencyToken> references,
  ) async {
    final mapping = await resolver.driver.typeMapping;
    return (ResolvedDependencies dependencies) {
      return mapping.newEngineWithTables([
        for (final reference in references) dependencies.resolve(reference),
      ]);
    };
  }

  Future<List<DependencyToken>> resolveTableReferences(
    AstNode stmt, {
    List<ResolvableSqlReference> additional = const [],
  }) async {
    final engine = resolver.driver.newSqlEngine();
    final references = engine.findReferencedSchemaTables(stmt);
    final found = <DependencyToken>[];
    final missingNames = <String, ResolveReferencedElementResult>{};

    final entries = references
        .map<(String, ResolvableSqlReference?)>((e) => (e, null))
        .followedBy(additional.map((e) => (e.name, e)));

    for (final (table, entry) in entries) {
      // If this is a reference to a table the empty engine already knows, it
      // must be a table builtin to sqlite3, not a drift reference.
      if (engine.knownResultSets.any(
        (e) => e.name.toLowerCase() == table.toLowerCase(),
      )) {
        continue;
      }

      final result = await resolver.resolveReference(table);

      if (result case ResolvedReferenceFound(:final token)) {
        entry?.resolved = token;
        found.add(token);
      } else {
        missingNames[table.toLowerCase()] = result;
      }
    }

    if (missingNames.isNotEmpty) {
      // Ok, there are unresolved table references
      for (final reference in stmt.allDescendants.whereType<TableReference>()) {
        if (reference.resolved == null) {
          final unresolvedBecause =
              missingNames[reference.tableName.toLowerCase()];

          if (unresolvedBecause != null) {
            reportErrorForUnresolvedReference(
              unresolvedBecause,
              (msg) => DriftAnalysisError.inDriftFile(reference, msg),
            );
          }
        }
      }
    }

    return found;
  }

  /// Finds all referenced tables, Dart expressions and Dart types referenced
  /// in [stmt].
  Future<FoundReferencesInSql> resolveSqlReferences(AstNode stmt) async {
    final driftElements = await resolveTableReferences(stmt);

    final identifier = _IdentifyDartElements();
    stmt.accept(identifier, null);

    return FoundReferencesInSql(
      referencedElements: driftElements,
      dartExpressions: identifier.dartExpressions,
      dartTypes: identifier.dartTypes,
    );
  }

  /// Performs async resolve work that might discover dependencies, e.g. for
  /// foreign keys.
  ///
  /// Because references can be circular, this first returns an intermediate
  /// element that is later resolved once all other intermediates are available.
  Future<PendingDriftElement> buildPending();
}

final class PendingDriftElement {
  final DriftElement element;
  final void Function(ResolvedDependencies) resolve;

  PendingDriftElement({required this.element, required this.resolve});
}

final class ResolvableSqlReference {
  final String name;
  DependencyToken? resolved;

  ResolvableSqlReference(this.name);
}

/// A [TwoStageElementResolver] without support for circular references,
/// resolving everything in the first stage.
abstract class LocalElementResolver<T extends DiscoveredElement>
    extends TwoStageElementResolver<T> {
  LocalElementResolver(
    super.file,
    super.discovered,
    super.resolver,
    super.state,
  );

  Future<DriftElement> resolve();

  @override
  Future<PendingDriftElement> buildPending() async {
    final element = await resolve();
    return PendingDriftElement(element: element, resolve: (_) {});
  }
}

sealed class _ResolvingOrCachedElement {
  final DependencyToken token;
  final ElementAnalysisState state;

  _ResolvingOrCachedElement({required this.token, required this.state});
}

final class _ResolvingElement extends _ResolvingOrCachedElement {
  late TwoStageElementResolver resolver;
  final Set<DriftElementId> dependencies = {};

  PendingDriftElement? intermediate;

  _ResolvingElement({required super.token, required super.state});
}

final class _ExternallyResolvedElement extends _ResolvingOrCachedElement {
  _ExternallyResolvedElement({required super.token, required super.state});
}

sealed class ResolveReferencedElementResult {
  const ResolveReferencedElementResult();
}

final class ResolvedReferenceFound extends ResolveReferencedElementResult {
  final DependencyToken token;

  ResolvedReferenceFound(this.token);
}

enum InvalidReferenceError {
  causesCircularReference,

  /// Reported by [DependencyAwareResolver.resolveReference] when no element
  /// with the given name exists in transitive imports.
  noElementWithSuchName,

  /// Reported by [DependencyAwareResolver.resolveReference] when more than one
  /// element with the queried name was found.
  ambigiousElements,
}

final class InvalidReferenceResult extends ResolveReferencedElementResult {
  final InvalidReferenceError error;
  final String message;

  InvalidReferenceResult(this.error, this.message);
}

final class ReferencedElementCouldNotBeResolved
    extends ResolveReferencedElementResult {}

class _IdentifyDartElements extends RecursiveVisitor<void, void> {
  final List<String> dartExpressions = [];
  final Map<SyntacticEntity, String> dartTypes = {};

  @override
  void visitCastExpression(CastExpression e, void arg) {
    final match = FoundReferencesInSql.enumRegex.firstMatch(e.typeName);

    if (match != null) {
      // Found `ENUMNAME(x)`, where `x` is a Dart type that we might want to
      // resolve later.
      dartTypes[e] = match.group(2)!;
    }

    super.visitCastExpression(e, arg);
  }

  @override
  void visitColumnConstraint(ColumnConstraint e, void arg) {
    if (e is MappedBy) {
      dartExpressions.add(e.mapper.dartCode);
    } else {
      super.visitColumnConstraint(e, arg);
    }
  }
}

final class _DependencyGraph
    extends
        UnmodifiableMapBase<
          _ResolvingOrCachedElement,
          Iterable<_ResolvingOrCachedElement>
        > {
  final DriftResolver _resolver;

  _DependencyGraph(this._resolver);

  @override
  Iterable<_ResolvingOrCachedElement>? operator [](Object? key) {
    if (key is _ResolvingElement) {
      return key.dependencies.map((id) => _resolver._involvedElements[id]!);
    }

    return null;
  }

  @override
  Iterable<_ResolvingOrCachedElement> get keys =>
      _resolver._involvedElements.values;
}
