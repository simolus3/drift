import 'package:build/build.dart';

class CopyCompiledJs extends Builder {
  CopyCompiledJs([BuilderOptions? options]);

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = AssetId(buildStep.inputId.package, 'web/worker.dart.js');
    final input = await buildStep.readAsBytes(inputId);
    await buildStep.writeAsBytes(buildStep.allowedOutputs.single, input);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$package$': ['web/shared_worker.dart.js']
      };
}
