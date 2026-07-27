import 'dart:io';

void main() {
  _configureAndroid();
  _configureIos();
  _configureLinux();
  _configureMacOs();
  stdout.writeln('Thought Circle platform settings applied.');
}

void _configureLinux() {
  final mainFile = File('linux/runner/main.cc');
  if (!mainFile.existsSync()) return;

  var text = mainFile.readAsStringSync();
  if (text.contains('FLUTTER_ENGINE_SWITCHES')) return;

  const softwareRenderingSetup =
      '''  // Disable GPU rendering before GTK or the Flutter engine initializes.
  // X11 avoids Wayland pointer-routing issues in Linux containers/VMs.
  g_setenv("GDK_BACKEND", "x11", TRUE);
  // This is the Linux embedder's renderer selector. The engine switch alone
  // does not replace the GTK OpenGL compositor.
  g_setenv("FLUTTER_LINUX_RENDERER", "software", TRUE);
  g_setenv("FLUTTER_ENGINE_SWITCHES", "3", TRUE);
  g_setenv("FLUTTER_ENGINE_SWITCH_1", "enable-software-rendering=true", TRUE);
  g_setenv("FLUTTER_ENGINE_SWITCH_2", "enable-impeller=false", TRUE);
  g_setenv("FLUTTER_ENGINE_SWITCH_3", "enable-flutter-gpu=false", TRUE);
  g_setenv("LIBGL_ALWAYS_SOFTWARE", "1", TRUE);
  g_setenv("GALLIUM_DRIVER", "llvmpipe", TRUE);
  g_print("Thought Circle platform check: GTK backend=x11; native "
          "renderer=software; GPU disabled; Mesa driver=llvmpipe.\\n");''';

  const oldSoftwareRenderingSetup =
      '''  // Force Mesa's CPU renderer before GTK or the Flutter engine initializes.
  // This keeps the desktop app usable on machines without working GPU
  // acceleration (including VMs and remote desktop sessions).
  g_setenv("LIBGL_ALWAYS_SOFTWARE", "1", TRUE);
  g_setenv("GALLIUM_DRIVER", "llvmpipe", TRUE);''';

  if (text.contains(oldSoftwareRenderingSetup)) {
    text = text.replaceFirst(oldSoftwareRenderingSetup, softwareRenderingSetup);
  } else {
    text = text.replaceFirst(
      'int main(int argc, char** argv) {',
      'int main(int argc, char** argv) {\n$softwareRenderingSetup',
    );
  }
  mainFile.writeAsStringSync(text);
}

void _configureAndroid() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync()) {
    var text = manifest.readAsStringSync();
    if (!text.contains('android.permission.INTERNET')) {
      text = text.replaceFirstMapped(
        RegExp(r'<manifest([^>]*)>'),
        (match) =>
            '<manifest${match.group(1)}>\n'
            '    <uses-permission android:name="android.permission.INTERNET"/>',
      );
    }
    if (!text.contains('android.permission.RECORD_AUDIO')) {
      text = text.replaceFirstMapped(
        RegExp(r'<manifest([^>]*)>'),
        (match) =>
            '<manifest${match.group(1)}>\n'
            '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>',
      );
    }
    text = text.replaceAll(
      'android:label="thought_circle"',
      'android:label="Thought Circle"',
    );
    text = text.replaceAll(
      'android:label="Thought circle"',
      'android:label="Thought Circle"',
    );
    if (!text.contains('android:allowBackup=')) {
      text = text.replaceFirst(
        'android:icon="@mipmap/ic_launcher"',
        'android:icon="@mipmap/ic_launcher"\n        android:allowBackup="false"\n        android:fullBackupContent="false"',
      );
    }
    manifest.writeAsStringSync(text);
  }

  final gradle = File('android/app/build.gradle.kts');
  if (gradle.existsSync()) {
    var text = gradle.readAsStringSync();
    if (!text.contains('abiFilters += "arm64-v8a"')) {
      text = text.replaceFirstMapped(
        RegExp(r'(versionName\s*=\s*flutter\.versionName\s*)'),
        (match) =>
            '${match.group(1)}\n'
            '        ndk {\n'
            '            abiFilters += "arm64-v8a"\n'
            '        }\n',
      );
    }
    gradle.writeAsStringSync(text);
  }
}

void _configureIos() {
  final podfile = File('ios/Podfile');
  if (podfile.existsSync()) {
    var text = podfile.readAsStringSync();
    final platformPattern = RegExp(r"#?\s*platform\s*:ios,\s*'[^']+'");
    if (platformPattern.hasMatch(text)) {
      text = text.replaceFirst(platformPattern, "platform :ios, '16.0'");
    } else {
      text = "platform :ios, '16.0'\n\n$text";
    }
    if (!text.contains('use_frameworks! :linkage => :static')) {
      text = text.replaceFirst(
        'target \'Runner\' do',
        "target 'Runner' do\n  use_frameworks! :linkage => :static",
      );
    }
    podfile.writeAsStringSync(text);
  }

  final plist = File('ios/Runner/Info.plist');
  if (plist.existsSync()) {
    var text = plist.readAsStringSync();
    text = text.replaceAll(
      '<string>thought_circle</string>',
      '<string>Thought Circle</string>',
    );
    if (!text.contains('NSMicrophoneUsageDescription')) {
      text = text.replaceFirst(
        '</dict>\n</plist>',
        '\t<key>NSMicrophoneUsageDescription</key>\n'
            '\t<string>Record a short voice journal.</string>\n'
            '</dict>\n</plist>',
      );
    }
    plist.writeAsStringSync(text);
  }
}

void _configureMacOs() {
  for (final path in <String>[
    'macos/Runner/DebugProfile.entitlements',
    'macos/Runner/Release.entitlements',
  ]) {
    final file = File(path);
    if (!file.existsSync()) continue;
    var text = file.readAsStringSync();
    final additions = StringBuffer();
    if (!text.contains('com.apple.security.network.client')) {
      additions.writeln('\t<key>com.apple.security.network.client</key>');
      additions.writeln('\t<true/>');
    }
    if (!text.contains('com.apple.security.files.user-selected.read-only')) {
      additions.writeln(
        '\t<key>com.apple.security.files.user-selected.read-only</key>',
      );
      additions.writeln('\t<true/>');
    }
    if (!text.contains('com.apple.security.device.audio-input')) {
      additions.writeln('\t<key>com.apple.security.device.audio-input</key>');
      additions.writeln('\t<true/>');
    }
    if (additions.isNotEmpty) {
      text = text.replaceFirst('</dict>', '${additions.toString()}</dict>');
      file.writeAsStringSync(text);
    }
  }

  final plist = File('macos/Runner/Info.plist');
  if (plist.existsSync()) {
    var text = plist.readAsStringSync();
    if (!text.contains('NSMicrophoneUsageDescription')) {
      text = text.replaceFirst(
        '</dict>\n</plist>',
        '\t<key>NSMicrophoneUsageDescription</key>\n'
            '\t<string>Record a short voice journal.</string>\n'
            '</dict>\n</plist>',
      );
      plist.writeAsStringSync(text);
    }
  }
}
