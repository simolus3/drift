import '../driver/driver.dart';
import '../driver/state.dart';
import '../results/element.dart';

import 'drift/table.dart' as drift_table;
import 'intermediate_state.dart';

class DriftResolver {
  final DriftAnalysisDriver driver;

  DriftResolver(this.driver);

  Future<DriftElement> resolveDiscovered(DiscoveredElement discovered) {
    LocalElementResolver resolver;

    if (discovered is DiscoveredDriftTable) {
      resolver = drift_table.DriftTableResolver(discovered, this);
    } else {
      throw UnimplementedError('TODO: Handle $discovered');
    }

    return resolver.resolve();
  }

  Future<ResolveReferencedElementResult> resolveReferencedElement(
      DriftElementId owner, DriftElementId reference) async {
    final existing = driver.cache.resolvedElements[reference];
    if (existing != null) {
      // todo: Check for circular references
      return ResolvedReferenceFound(existing);
    }

    final pending = driver.cache.discoveredElements[reference];
    if (pending != null) {
      try {
        // todo: Check for circular references
        final resolved = await resolveDiscovered(pending);
        return ResolvedReferenceFound(resolved);
      } catch (e, s) {
        driver.backend.log.warning('Could not analze $reference', e, s);
        return ReferencedElementCouldNotBeResolved();
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
      final result = available.results;
      final discovery = available.discovery;

      if (result != null) {
        // todo
        throw UnimplementedError('Pre-read results');
      } else {
        for (final definedLocally in discovery!.locallyDefinedElements) {
          if (definedLocally.ownId.sameName(reference)) {
            candidates.add(definedLocally.ownId);
          }
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

  LocalElementResolver(this.discovered, this.resolver);

  Future<DriftElement> resolve();
}

abstract class ResolveReferencedElementResult {}

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
