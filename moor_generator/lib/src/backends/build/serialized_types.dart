import 'dart:async';

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// A serialized version of a [DartType].
abstract class SerializedType {
  factory SerializedType.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'interface':
        return _SerializedInterfaceType.fromJson(json);
    }
    throw ArgumentError('Unknown type kind: ${json['type']}');
  }

  SerializedType();

  Map<String, dynamic> toJson();
}

// todo handle non-interface types, recursive types

class _SerializedInterfaceType extends SerializedType {
  final Uri libraryUri;
  final String className;
  final List<SerializedType> typeArgs;

  _SerializedInterfaceType(this.libraryUri, this.className, this.typeArgs);

  factory _SerializedInterfaceType.fromJson(Map<String, dynamic> json) {
    final serializedTypes = json['type_args'] as List;

    return _SerializedInterfaceType(
      Uri.parse(json['library'] as String),
      json['class_name'] as String,
      serializedTypes
          .map((raw) => SerializedType.fromJson(raw as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'interface',
      'library': libraryUri.toString(),
      'class_name': className,
      'type_args': [for (var type in typeArgs) type.toJson()],
    };
  }
}

class TypeSerializer {
  final Resolver resolver;

  TypeSerializer(this.resolver);

  Future<SerializedType> serialize(DartType type) async {
    if (type is InterfaceType) {
      final dartClass = type.element;

      Uri uri;
      if (dartClass.librarySource.uri.scheme == 'dart') {
        uri = dartClass.librarySource.uri;
      } else {
        uri = (await resolver.assetIdForElement(dartClass)).uri;
      }

      final serializedArgs =
          await Future.wait(type.typeArguments.map(serialize));

      return _SerializedInterfaceType(
        uri,
        dartClass.name,
        serializedArgs,
      );
    } else {
      throw UnsupportedError(
          "Couldn't serialize $type, we only support interface types");
    }
  }
}

class TypeDeserializer {
  /// The [BuildStep] used to resolve
  final BuildStep buildStep;

  /// The analysis session used to read libraries from the Dart SDK which can't
  /// be obtained via build apis.
  AnalysisSession _lastSession;

  TypeDeserializer(this.buildStep);

  Future<DartType> deserialize(SerializedType type) async {
    if (type is _SerializedInterfaceType) {
      final library = await _libraryFromUri(type.libraryUri);
      final args = await Future.wait(type.typeArgs.map(deserialize));

      return LibraryReader(library).findType(type.className).instantiate(
          typeArguments: args, nullabilitySuffix: NullabilitySuffix.star);
    }

    throw AssertionError('Unhandled type: $type');
  }

  Future<LibraryElement> _libraryFromUri(Uri uri) async {
    if (uri.scheme == 'dart') {
      var session = await _obtainSession();

      // The session could be invalidated by other builders outside of our
      // control. There's no better way than to continue fetching a new session
      // in that case.
      var attempts = 0;
      const maxAttempts = 5;

      // ignore: literal_only_boolean_expressions
      while (true) {
        try {
          return session.getLibraryByUri(uri.toString());
        } on InconsistentAnalysisException {
          _lastSession = null; // Invalidate session, then try again
          session = await _obtainSession();
          attempts++;

          if (attempts == maxAttempts) rethrow;
        }
      }
    } else {
      final library =
          await buildStep.resolver.libraryFor(AssetId.resolve(uri));
      _lastSession ??= library?.session;
      return library;
    }
  }

  FutureOr<AnalysisSession> _obtainSession() {
    if (_lastSession != null) {
      return _lastSession;
    } else {
      // resolve bogus library that's not going to change often. We can use the
      // session from that library. Technically, this is non-hermetic, but the
      // build runner will throw everything away after an SDK update so it
      // should be safe
      return _libraryFromUri(Uri.parse('package:moor/sqlite_keywords.dart'))
          .then((_) => _lastSession);
    }
  }
}
