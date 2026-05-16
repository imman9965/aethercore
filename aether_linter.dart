import 'dart:io';

void main() async {
  print('===================================================');
  print('🛡️  Aether Architecture Linter (Diagnostic Mode) 🛡️');
  print('===================================================');

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    print('❌ CRITICAL ERROR: Not running in a Flutter project root.');
    print('💡 HEALING: `cd` into your project directory before running this.');
    return;
  }

  final reportFile = File('ARCHITECTURE_REPORT.md');
  final out = StringBuffer();
  out.writeln('# Aether Diagnostic Report\n');

  // 1. Strict Lints
  print('⏳ Running Diagnostic: Code Quality (flutter analyze)...');
  try {
    final analyze =
        await Process.run('flutter', ['analyze'], runInShell: true);
    if (analyze.exitCode == 0) {
      print('✅ Linter: PASS');
      out.writeln('### 1. Code Quality');
      out.writeln('✅ **PASS:** Zero static analysis warnings.');
    } else {
      print('❌ Linter: FAIL');
      out.writeln('### 1. Code Quality');
      out.writeln('❌ **FAIL:** Static analysis found issues.');
      out.writeln(
          '\n💡 **HEALING ACTION:** Look at the terminal output of `flutter analyze` and resolve the warnings. Did you specify types? Did you await all Futures?');
    }
  } catch (e) {
    print('❌ CRITICAL ERROR: Could not run "flutter analyze". Is Flutter in your PATH?');
    return;
  }

  // 2. Outcome Verification (Tests)
  print('⏳ Running Diagnostic: Concurrency Check (flutter test)...');
  final testFile = File('test/raid_concurrency_test.dart');

  if (!testFile.existsSync()) {
    print('❌ Tests: FAIL (raid_concurrency_test.dart is missing)');
    out.writeln('\n### 2. Concurrency Outcome');
    out.writeln('❌ **FAIL:** Missing test file.');
    out.writeln(
        '\n💡 **HEALING ACTION:** You must place the provided `raid_concurrency_test.dart` file in the `test/` directory.');
  } else {
    try {
      final testResult = await Process.run(
        'flutter',
        ['test', 'test/raid_concurrency_test.dart'],
        runInShell: true,
      );
      if (testResult.exitCode == 0) {
        print('✅ Tests: PASS');
        out.writeln('\n### 2. Concurrency Outcome');
        out.writeln('✅ **PASS:** Your architecture survived the Thundering Herd.');
      } else {
        print('❌ Tests: FAIL');
        out.writeln('\n### 2. Concurrency Outcome');
        out.writeln('❌ **FAIL:** The 50-request blast failed to yield exactly 15 slots.');
        out.writeln(
            '\n💡 **HEALING ACTION:** Read your test failure logs. Did your `joinRaid()` method correctly handle the race condition? Are you using locks or transactions?');
      }
    } catch (e) {
      print('❌ CRITICAL ERROR: Could not execute "flutter test".');
    }
  }

  try {
    reportFile.writeAsStringSync(out.toString());
    print('\n===================================================');
    print('📄 Report saved to ARCHITECTURE_REPORT.md');
    print('👀 Read the report for HEALING ACTIONS to fix your architecture.');
    print('===================================================');
  } catch (e) {
    print('❌ Could not write to ARCHITECTURE_REPORT.md. Check file permissions.');
  }
}
