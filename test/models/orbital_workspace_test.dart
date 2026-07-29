import 'package:flutter_test/flutter_test.dart';
import 'package:thought_circle/models/orbital_workspace.dart';

void main() {
  test('assigns rings and round-trips moons', () {
    final moon = OrbitalMoon(
      id: 'moon-1',
      thoughtId: 'thought-1',
      label: 'What evidence would change my mind?',
      kind: OrbitalMoonKind.question,
      createdAt: DateTime.utc(2026, 7, 29),
    );

    final workspace = const OrbitalWorkspace()
        .assignRing('thought-1', 2)
        .addMoon(moon);
    final restored = OrbitalWorkspace.decode(OrbitalWorkspace.encode(workspace));

    expect(restored.ringFor('thought-1'), 2);
    expect(restored.moonsFor('thought-1'), hasLength(1));
    expect(restored.moons.single.kind, OrbitalMoonKind.question);
  });

  test('normalization migrates old thoughts and removes orphan moons', () {
    final workspace = OrbitalWorkspace(
      ringByThoughtId: const <String, int>{'kept': 1, 'removed': 2},
      moons: <OrbitalMoon>[
        OrbitalMoon(
          id: 'kept-moon',
          thoughtId: 'kept',
          label: 'Keep this',
          kind: OrbitalMoonKind.note,
          createdAt: DateTime.utc(2026, 7, 29),
        ),
        OrbitalMoon(
          id: 'orphan',
          thoughtId: 'removed',
          label: 'Remove this',
          kind: OrbitalMoonKind.note,
          createdAt: DateTime.utc(2026, 7, 29),
        ),
      ],
    );

    final normalized = workspace.normalizedFor(<String>['kept', 'new']);

    expect(normalized.ringFor('kept'), 1);
    expect(normalized.ringByThoughtId.containsKey('new'), isTrue);
    expect(normalized.moons.map((moon) => moon.id), <String>['kept-moon']);
  });

  test('ring values are clamped to supported layers', () {
    expect(const OrbitalWorkspace().assignRing('a', -20).ringFor('a'), 0);
    expect(const OrbitalWorkspace().assignRing('b', 20).ringFor('b'), 2);
  });
}
