import '../driver/driver.dart';
import '../driver/error.dart';
import '../driver/state.dart';
import '../results/element.dart';

import 'drift/table.dart' as drift_table;
import 'intermediate_state.dart';

class DriftResolver {
  final DriftAnalysisDriver driver;

  final List<DriftElementId> _currentDependencyPath = [];

  DriftResolver(this.driver);

  Future<DriftElement> resolveDiscovered(DiscoveredElement discovered) {
    LocalElementResolver resolver;

    final fileState = driver.cache.knownFiles[discovered.ownId.libraryUri]!;
    final elementState = fileState.analysis.putIfAbsent(
        discovered.ownId, () => ElementAnalysisState(discovered.ownId));

    elementState.errorsDuringAnalysis.clear();

    if (discovered is DiscoveredDriftTable) {
      resolver = drift_table.DriftTableResolver(discovered, this, elementState);
    } else {
      throw UnimplementedError('TODO: Handle $discovered');
    }

    return resolver.resolve();
  }

  Future<ResolveReferencedElementResult> resolveReferencedElement(
      DriftElementId owner, DriftElementId reference) async {
    if (owner == reference) {
      return InvalidReferenceResult(
        InvalidReferenceError.referencesItself,
        'References itself',
      );
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
        InvalidReferenceError.referencesItself,
        'Illegal circular reference found: $message',
      );
    }

    final existing = driver.cache.resolvedElements[reference];
    if (existing != null) {
      // todo: Check for circular references for existing elements
      return ResolvedReferenceFound(existing);
    }

    final pending = driver.cache.discoveredElements[reference];
    if (pending != null) {
      _currentDependencyPath.add(reference);

      try {
        final resolved = await resolveDiscovered(pending);
        return ResolvedReferenceFound(resolved);
      } catch (e, s) {
        driver.backend.log.warning('Could not analze $reference', e, s);
        return ReferencedElementCouldNotBeResolved();
      } finally {
        final removed = _currentDependencyPath.removeLast();
        assert(identical(removed, reference));
      }
    }

    throw StateError(
        'Unknown pending element $reference, this is a bug in drift_dev');
  }

  Future<ResolveReferencedElementResult> resolveReference(
      DriftElementId owner, String reference) async {
    final candidates = <DriftElementId>[];
    final file = driver.cache.knownFiles[owner.libraryUri]!;

    for (final available in driver.cache.crawl(file)) {
      final localElementIds = {
        ...available.analysis.keys,
        ...?available.discovery?.locallyDefinedElements.map((e) => e.ownId),
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
        'This reference could not be found in any import.',
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
  final T discovered;
  final DriftResolver resolver;
  final ElementAnalysisState state;

  LocalElementResolver(this.discovered, this.resolver, this.state);

  void reportError(DriftAnalysisError error) {
    state.errorsDuringAnalysis.add(error);
  }

  Future<DriftElement> resolve();
}

abstract class ResolveReferencedElementResult {}

class ResolvedReferenceFound extends ResolveReferencedElementResult {
  final DriftElement element;

  ResolvedReferenceFound(this.element);
}

enum InvalidReferenceError {
  causesCircularReference,
  referencesItself,

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
