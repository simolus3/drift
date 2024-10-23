import 'package:dart_style/dart_style.dart';
import 'package:package_config/package_config_types.dart';
import 'package:pub_semver/pub_semver.dart';

String formatDartCode(
  String code,
  Version version, {
  bool includeWidthComment = true,
}) {
  var input = includeWidthComment
      ? '''
// dart format width=80
$code
'''
      : code;

  return DartFormatter(languageVersion: version).format(input);
}

extension LanguageVersionToPubSember on LanguageVersion {
  Version get asPubSemver => Version(major, minor, 0);
}
