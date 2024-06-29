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

  test('works when disabling default builder', () {
    // https://github.com/simolus3/drift/issues/3066
    final config = BuildConfig.parse('a', ['drift_dev'], r'''
targets:
  $default:
    builders:
      drift_dev:
        # Disable the default builder in favor of the modular builders configured
        # below.
        enabled: false

      drift_dev:analyzer:
        enabled: true
        options: &options
          store_date_time_values_as_text: true
          named_parameters: true
          sql:
            dialect: sqlite
            options:
              version: "3.45.3"
              modules: [fts5]
      drift_dev:modular:
        enabled: true
        options: *options
''');

    final options = readOptionsFromConfig(config);
    expect(options.storeDateTimeValuesAsText, isTrue);
  });
}
