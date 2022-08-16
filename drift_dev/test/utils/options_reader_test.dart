import 'package:build_config/build_config.dart';
import 'package:drift_dev/src/utils/options_reader.dart';
import 'package:test/test.dart';

void main() {
  test('reads options from build.yaml file', () {
    final config = BuildConfig.parse('a', ['drift_dev'], r'''
targets:
  $default:
    auto_apply_builders: false
    builders:
      drift_dev:preparing_builder:
        enabled: true
      drift_dev:drift_dev:
        enabled: true
        options:
          scoped_dart_components: false
      json_serializable:
        enabled: true
    sources:
     - lib/**
     - test/generated/**
''');

    final options = readOptionsFromConfig(config);
    expect(options.scopedDartComponents, isFalse);
  });

  test('supports reading from non-default target', () {
    final config = BuildConfig.parse('a', ['drift_dev'], r'''
targets:
  $default:
    dependencies: [:source_gen]
  source_gen:
    auto_apply_builders: false
    builders:
      drift_dev:preparing_builder:
        enabled: true
      drift_dev:drift_dev:
        enabled: true
        options:
          scoped_dart_components: false
      json_serializable:
        enabled: true
    sources:
     - lib/**
     - test/generated/**
''');

    final options = readOptionsFromConfig(config);
    expect(options.scopedDartComponents, isFalse);
  });

  test('supports reading for not_shared builder', () {
    final config = BuildConfig.parse('a', ['drift_dev'], r'''
targets:
  $default:
    dependencies: [:source_gen]
  source_gen:
    auto_apply_builders: false
    builders:
      drift_dev:preparing_builder:
        enabled: true
      drift_dev:not_shared:
        enabled: true
        options:
          scoped_dart_components: false
      json_serializable:
        enabled: true
    sources:
     - lib/**
     - test/generated/**
''');

    final options = readOptionsFromConfig(config);
    expect(options.scopedDartComponents, isFalse);
  });

  test('still works with | syntax', () {
    final config = BuildConfig.parse('a', ['drift_dev'], r'''
targets:
  $default:
    dependencies: [:source_gen]
  source_gen:
    auto_apply_builders: false
    builders:
      drift_dev|preparing_builder:
        enabled: true
      drift_dev|not_shared:
        enabled: true
        options:
          scoped_dart_components: false
      json_serializable:
        enabled: true
    sources:
     - lib/**
     - test/generated/**
''');

    final options = readOptionsFromConfig(config);
    expect(options.scopedDartComponents, isFalse);
  });
}
