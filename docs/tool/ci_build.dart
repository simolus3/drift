import 'dart:io';

Future<void> main() async {
  final isReleaseEnv = Platform.environment['IS_RELEASE'];
  print('Is release build: $isReleaseEnv');

  final isRelease = isReleaseEnv == '1';
  final buildArgs = [
    'run',
    'build_runner',
    'build',
    '--release',
    if (isRelease) '--config=deploy',
  ];
  final build = await Process.start('dart', buildArgs,
      mode: ProcessStartMode.inheritStdio);
  await build.exitCode;

  final generatePages = await Process.start(
      'dart', [...buildArgs, '--output=web:deploy'],
      mode: ProcessStartMode.inheritStdio);
  await generatePages.exitCode;
}
