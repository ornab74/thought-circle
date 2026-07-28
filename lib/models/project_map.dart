final class ProjectMapResult {
  const ProjectMapResult({
    required this.name,
    required this.rootPath,
    required this.fileCount,
    required this.totalBytes,
    required this.languages,
    required this.topLevelEntries,
    required this.notableFiles,
    required this.truncated,
    required this.generatedAt,
  });

  final String name;
  final String rootPath;
  final int fileCount;
  final int totalBytes;
  final Map<String, int> languages;
  final List<String> topLevelEntries;
  final List<String> notableFiles;
  final bool truncated;
  final DateTime generatedAt;

  String get sizeLabel {
    const mib = 1024 * 1024;
    if (totalBytes >= mib) return '${(totalBytes / mib).toStringAsFixed(1)} MB';
    return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
  }

  String toGuideContext() {
    final languageText = languages.entries
        .take(12)
        .map((entry) => '${entry.key}: ${entry.value} files')
        .join(', ');
    final structure = topLevelEntries.isEmpty
        ? '(no top-level entries found)'
        : topLevelEntries.take(40).join('\n- ');
    final notable = notableFiles.isEmpty
        ? '(no notable files found)'
        : notableFiles.take(80).join('\n- ');
    return '''
I want to test a repeating belief by building or improving something concrete.
Use this read-only repository map as evidence. Do not claim the code was run.

Project: $name
Files mapped: $fileCount${truncated ? ' (scan limit reached)' : ''}
Indexed size: $sizeLabel
Languages: ${languageText.isEmpty ? 'unknown' : languageText}

Top-level structure:
- $structure

Notable files:
- $notable

Help me choose one small prototype, inspection, or prompt experiment that would
produce new evidence. Preserve valid criticism, mark unknowns, and give a clear
stopping rule.
'''.trim();
  }
}
