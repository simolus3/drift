import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

import '../driver/driver.dart';
import '../driver/error.dart';
import '../driver/state.dart';
import '../results/element.dart';

import '../serializer.dart';
import 'dart/accessor.dart' as dart_accessor;
import 'dart/index.dart' as dart_index;
import 'dart/table.dart' as dart_table;
import 'dart/view.dart' as dart_view;
import 'drift/index.dart' as drift_index;
import 'drift/query.dart' as drift_query;
import 'drift/table.dart' as drift_table;
import 'drift/trigger.dart' as drift_trigger;
import 'drift/view.dart' as drift_view;
import 'intermediate_state.dart';

/// Analyzes and resolves drift elements.
class DriftResolver {
  final DriftAnalysisDriver driver;

  /// The current depth-first path of drift elements being analyzed.
  ///
  /// This path is used to detect and prevent circular references.
  final List<DriftElementId> _currentDependencyPath = [];

  late final ElementDeserializer _deserializer =
      ElementDeserializer(driver, _currentDependencyPath);

  DriftResolver(this.driver);

  Future<DriftElement> resolveEntrypoint(DriftElementId element) async {
    assert(_currentDependencyPath.isEmpty);
    _currentDependencyPath.add(element);

    return await _restoreOrResolve(element);
  }

  Future<DriftElement> _restoreOrResolve(DriftElementId element) async {
    try {
      if (await driver.readStoredAnalysisResult(element.libraryUri) != null) {
        return await _deserializer.readDriftElement(element);
      }
    } on CouldNotDeserializeException catch (e, s) {
      driver.backend.log.fine('Could not deserialize $element', e, s);
    }

    // We can't resolve the element from cache, so we need to resolve it.
    final owningFile = driver.cache.stateForUri(element.libraryUri);
    await driver.discoverIfNecessary(owningFile);
    final discovered = owningFile.discovery!.locallyDefinedElements
        .firstWhere((e) => e.ownId == element);

    return await _resolveDiscovered(discovered);
  }

  /// Resolves a discovered element by analyzing it and its dependencies.
  Future<DriftElement> _resolveDiscovered(DiscoveredElement discovered) async {
    final fileState = driver.cache.knownFiles[discovered.ownId.libraryUri]!;
    final elementState = fileState.analysis.putIfAbsent(
        discovered.ownId, () => ElementAnalysisState(discovered.ownId));

    elementState.errorsDuringAnalysis.clear();

    LocalElementResolver resolver;
    if (discovered is DiscoveredDriftTable) {
      resolver = drift_table.DriftTableResolver(
          fileState, discovered, this, elementState);
    } else if (discovered is DiscoveredDriftIndex) {
      resolver = drift_index.DriftIndexResolver(
          fileState, discovered, this, elementState);
    } else if (discovered is DiscoveredDriftStatement) {
      resolver = drift_query.DriftQueryResolver(
          fileState, discovered, this, elementState);
    } else if (discovered is DiscoveredDriftTrigger) {
      resolver = drift_trigger.DriftTriggerResolver(
          fileState, discovered, this, elementState);
    } else if (discovered is DiscoveredDriftView) {
      resolver = drift_view.DriftViewResolver(
          fileState, discovered, this, elementState);
    } else if (discovered is DiscoveredDartTable) {
      resolver = dart_table.DartTableResolver(
          fileState, discovered, this, elementState);
    } else if (discovered is DiscoveredDartView) {
      resolver =
          dart_view.DartViewResolver(fileState, discovered, this, elementState);
    } else if (discovered is DiscoveredDartIndex) {
      resolver = dart_index.DartIndexResolver(
          fileState, discovered, this, elementState);
    } else if (discovered is DiscoveredBaseAccessor) {
      resolver = dart_accessor.DartAccessorResolver(
          fileState, discovered, this, elementState);
    } else {
      throw UnimplementedError('TODO: Handle $discovered');
    }

    final resolved = await resolver.resolve();

    elementState
      ..result = resolved
      ..isUpToDate = true;
    return resolved;
  }

  /// Attempts to resolve a dependency for an element if that is allowed.
  ///
  /// It usually _is_ allowed, but there could be a forbidden circular reference
  /// in which case the reference is reported to be unavailable.
  /// Further, an internal bug in the analyzer could cause a crash analyzing
  /// the element. To not cause the entire analysis run to fail, this reports
  /// an error message and otherwise continues analysis of other elements.
  Future<ResolveReferencedElementResult> resolveReferencedElement(
      DriftElementId owner, DriftElementId reference) async {
    if (owner == reference) {
      return const ReferencesItself();
    }

    // If this element is in the backlog of things currently being analyzed,
    // that's a circular reference.
    if (_currentDependencyPath.contains(reference)) {
      final offset = _currentDependencyPath.indexOf(reference);
      final message = _currentDependencyPath
          .skip(offset)
          .followedBy([reference])
          .map((e) => '`${e.name}`')
          .join(' -> ');

      return InvalidReferenceResult(
        InvalidReferenceError.causesCircularReference,
        'Illegal circular reference found: $message',
      );
    }

    final existing = driver
        .cache.knownFiles[reference.libraryUri]?.analysis[reference]?.result;
    if (existing != null) {
      // todo: Check for circular references for existing elements
      return ResolvedReferenceFound(existing);
    }

    final pending = driver.cache.discoveredElements[reference];
    if (pending != null) {
      // We know the element exists, but we haven't resolved it yet.
      _currentDependencyPath.add(reference);

      try {
        final resolved = await _restoreOrResolve(reference);
        return ResolvedReferenceFound(resolved);
      } catch (e, s) {
        driver.backend.log.warning('Could not analyze $reference', e, s);
        return ReferencedElementCouldNotBeResolved();
      } finally {
        final removed = _currentDependencyPath.removeLast();
        assert(identical(removed, reference));
      }
    }

    throw StateError(
        'Unknown pending element $reference, this is a bug in drift_dev');
  }

  /// Resolves a Dart element reference, if the referenced Dart [element]
  /// defines an element understood by drift.
  Future<ResolveReferencedElementResult> resolveDartReference(
      DriftElementId owner, Element element) async {
    final uri = await driver.backend.uriOfDart(element.library!);
    final state = driver.cache.stateForUri(uri);

    final existing = state.definedElements.firstWhereOrNull(
        (existing) => existing.dartElementName == element.name);

    if (existing != null) {
      return resolveReferencedElement(owner, existing.ownId);
    } else {
      return InvalidReferenceResult(
        InvalidReferenceError.noElementWichSuchName,
        'The referenced element, ${element.name}, is not understood by drift.',
      );
    }
  }

  /// Resolves a reference in SQL.
  ///
  /// This works by looking at known imports of the file defining the [owner]
  /// and using the results of the discovery step to find a known element with
  /// the same name. If one exists, it is resolved and returned. Otherwise, an
  /// error result is returned.
  Future<ResolveReferencedElementResult> resolveReference(
      DriftElementId owner, String reference) async {
    final candidates = <DriftElementId>[];
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
        InvalidReferenceError.noElementWichSuchName,
        '`$reference` could not be found in any import.',
      );
    } else if (candidates.length > 1) {
      final description =
          candidates.map((c) => '`${c.name}` in `${c.libraryUri}`').join(', ');

      return InvalidReferenceResult(
        InvalidReferenceError.ambigiousElements,
        'Ambigious reference, it could refer to any of: $description',
      );
    }

    return resolveReferencedElement(owner, candidates.single);
  }
}

abstract class LocalElementResolver<T extends DiscoveredElement> {
  final FileState file;
  final T discovered;
  final DriftResolver resolver;
  final ElementAnalysisState state;

  LocalElementResolver(this.file, this.discovered, this.resolver, this.state);

  void reportError(DriftAnalysisError error) {
    state.errorsDuringAnalysis.add(error);
  }

  Future<E?> resolveSqlReferenceOrReportError<E extends DriftElement>(
    String reference,
    DriftAnalysisError Function(String msg) createError,
  ) async {
    final result = await resolver.resolveReference(discovered.ownId, reference);
    return handleReferenceResult(result, createError);
  }

  Future<E?> resolveDartReferenceOrReportError<E extends DriftElement>(
    Element reference,
    DriftAnalysisError Function(String msg) createError,
  ) async {
    final result =
        await resolver.resolveDartReference(discovered.ownId, reference);
    return handleReferenceResult(result, createError);
  }

  E? handleReferenceResult<E extends DriftElement>(
    ResolveReferencedElementResult result,
    DriftAnalysisError Function(String msg) createError,
  ) {
    if (result is ResolvedReferenceFound) {
      final element = result.element;
      if (element is E) {
        return element;
      } else {
        // todo: Better type description in error message
        reportError(
            createError('Expected a $E, but got a ${element.runtimeType}'));
      }
    } else {
      reportErrorForUnresolvedReference(result, createError);
    }

    return null;
  }

  void reportErrorForUnresolvedReference(ResolveReferencedElementResult result,
      DriftAnalysisError Function(String msg) createError) {
    if (result is InvalidReferenceResult) {
      reportError(createError(result.message));
    } else if (result is ReferencedElementCouldNotBeResolved) {
      reportError(createError(
          'The referenced element could not be analyzed due to a bug in drift.'));
    }
  }

  Future<DriftElement> resolve();
}

abstract class ResolveReferencedElementResult {
  const ResolveReferencedElementResult();
}

class ResolvedReferenceFound extends ResolveReferencedElementResult {
  final DriftElement element;

  ResolvedReferenceFound(this.element);
}

enum InvalidReferenceError {
  causesCircularReference,

  /// Reported by [DriftResolver.resolveReference] when no element with the
  /// given name exists in transitive imports.
  noElementWichSuchName,

  /// Reported by [DriftResolver.resolveReference] when more than one element
  /// with the queried name was found.
  ambigiousElements,
}

class InvalidReferenceResult extends ResolveReferencedElementResult {
  final InvalidReferenceError error;
  final String message;

  InvalidReferenceResult(this.error, this.message);
}

class ReferencedElementCouldNotBeResolved
    extends ResolveReferencedElementResult {}

class ReferencesItself extends ResolveReferencedElementResult {
  const ReferencesItself();
}
