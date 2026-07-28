import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../models/project_map.dart';

final class ProjectMapService {
  static const int maxFiles = 2500;
  static const int maxIndexedBytes = 64 * 1024 * 1024;

  static bool get isSupportedPlatform =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  static const Set<String> _ignoredDirectories = <String>{
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    'build',
    'coverage',
    'dist',
    'node_modules',
    'vendor',
    'Pods',
    'DerivedData',
    '.gradle',
  };

  Future<ProjectMapResult?> chooseAndScan() async {
    if (!isSupportedPlatform) {
      throw UnsupportedError(
        'Project mapping is available on Linux, Windows, and macOS.',
      );
    }
    final path = await getDirectoryPath(
      confirmButtonText: 'Map this project',
    );
    if (path == null || path.trim().isEmpty) return null;
    return scan(path);
  }

  Future<ProjectMapResult> scan(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw FileSystemException('The selected folder no longer exists.', rootPath);
    }

    final rootNormalized = root.absolute.path;
    final topLevel = <String>{};
    final notable = <String>[];
    final languages = <String, int>{};
    var count = 0;
    var bytes = 0;
    var truncated = false;

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (count >= maxFiles || bytes >= maxIndexedBytes) {
        truncated = true;
        break;
      }
      if (entity is! File) continue;
      final relative = _relativePath(rootNormalized, entity.absolute.path);
      if (relative.isEmpty || _isIgnored(relative)) continue;

      final stat = await entity.stat();
      if (stat.type != FileSystemEntityType.file) continue;
      if (bytes + stat.size > maxIndexedBytes) {
        truncated = true;
        break;
      }
      count += 1;
      bytes += stat.size;

      final segments = relative.split('/');
      if (segments.isNotEmpty) topLevel.add(segments.first);
      final language = _languageFor(relative);
      languages[language] = (languages[language] ?? 0) + 1;
      if (_isNotable(relative) || notable.length < 80) notable.add(relative);
    }

    final sortedLanguages = languages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedTop = topLevel.toList()..sort();
    notable.sort((a, b) {
      final aScore = _notableScore(a);
      final bScore = _notableScore(b);
      if (aScore != bScore) return bScore.compareTo(aScore);
      return a.compareTo(b);
    });

    final nameParts = root.uri.pathSegments
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    final projectName = nameParts.isEmpty ? rootNormalized : nameParts.last;

    return ProjectMapResult(
      name: projectName,
      rootPath: rootNormalized,
      fileCount: count,
      totalBytes: bytes,
      languages: <String, int>{for (final entry in sortedLanguages) entry.key: entry.value},
      topLevelEntries: sortedTop,
      notableFiles: notable.take(120).toList(growable: false),
      truncated: truncated,
      generatedAt: DateTime.now(),
    );
  }

  String _relativePath(String root, String path) {
    var relative = path.startsWith(root) ? path.substring(root.length) : path;
    relative = relative.replaceAll('\\', '/');
    while (relative.startsWith('/')) {
      relative = relative.substring(1);
    }
    return relative;
  }

  bool _isIgnored(String relative) {
    final ignored = _ignoredDirectories.map((item) => item.toLowerCase()).toSet();
    final parts = relative.split('/').map((part) => part.toLowerCase());
    return parts.any(ignored.contains);
  }

  bool _isNotable(String path) {
    final lower = path.toLowerCase();
    final name = lower.split('/').last;
    return name == 'readme.md' ||
        name == 'pubspec.yaml' ||
        name == 'package.json' ||
        name == 'pyproject.toml' ||
        name == 'requirements.txt' ||
        name == 'cargo.toml' ||
        name == 'go.mod' ||
        name == 'build.gradle' ||
        name == 'build.gradle.kts' ||
        name == 'settings.gradle' ||
        name == 'settings.gradle.kts' ||
        name == 'dockerfile' ||
        name.endsWith('.sln') ||
        name.endsWith('.xcodeproj') ||
        lower.startsWith('lib/') ||
        lower.startsWith('src/') ||
        lower.startsWith('app/') ||
        lower.startsWith('test/');
  }

  int _notableScore(String path) {
    final lower = path.toLowerCase();
    final name = lower.split('/').last;
    if (name == 'readme.md') return 100;
    if (<String>{
      'pubspec.yaml',
      'package.json',
      'pyproject.toml',
      'cargo.toml',
      'go.mod',
    }.contains(name)) {
      return 90;
    }
    if (lower.startsWith('lib/') || lower.startsWith('src/')) return 70;
    if (lower.startsWith('test/')) return 60;
    return 10;
  }

  String _languageFor(String path) {
    final lower = path.toLowerCase();
    final dot = lower.lastIndexOf('.');
    final extension = dot < 0 ? '' : lower.substring(dot + 1);
    return switch (extension) {
      'dart' => 'Dart',
      'py' => 'Python',
      'js' || 'mjs' || 'cjs' => 'JavaScript',
      'ts' || 'tsx' => 'TypeScript',
      'java' => 'Java',
      'kt' || 'kts' => 'Kotlin',
      'swift' => 'Swift',
      'm' || 'mm' => 'Objective-C',
      'c' || 'h' => 'C',
      'cc' || 'cpp' || 'cxx' || 'hpp' => 'C++',
      'cs' => 'C#',
      'rs' => 'Rust',
      'go' => 'Go',
      'rb' => 'Ruby',
      'php' => 'PHP',
      'html' || 'htm' => 'HTML',
      'css' || 'scss' || 'sass' => 'CSS',
      'json' || 'yaml' || 'yml' || 'toml' => 'Configuration',
      'md' || 'txt' || 'rst' => 'Documentation',
      'sh' || 'bash' || 'zsh' || 'ps1' => 'Shell',
      _ => 'Other',
    };
  }
}
