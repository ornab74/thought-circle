import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thought_circle/services/project_map_service.dart';

void main() {
  test('project mapper builds a read-only structure map', () async {
    final root = await Directory.systemTemp.createTemp('thought-circle-map-');
    addTearDown(() => root.delete(recursive: true));

    await Directory('${root.path}/lib').create(recursive: true);
    await Directory('${root.path}/test').create(recursive: true);
    await Directory('${root.path}/node_modules/pkg').create(recursive: true);
    await File('${root.path}/README.md').writeAsString('# Demo');
    await File('${root.path}/pubspec.yaml').writeAsString('name: demo');
    await File('${root.path}/lib/main.dart').writeAsString('void main() {}');
    await File('${root.path}/test/app_test.dart').writeAsString('// test');
    await File('${root.path}/node_modules/pkg/ignored.js').writeAsString('x');

    final result = await ProjectMapService().scan(root.path);

    expect(result.fileCount, 4);
    expect(result.languages['Dart'], 2);
    expect(result.notableFiles, contains('README.md'));
    expect(result.notableFiles, contains('lib/main.dart'));
    expect(result.notableFiles.any((path) => path.contains('node_modules')), isFalse);
    expect(result.toGuideContext(), contains('Do not claim the code was run'));
    expect(result.toGuideContext(), isNot(contains(root.absolute.path)));
  });
}
