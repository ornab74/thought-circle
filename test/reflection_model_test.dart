import 'package:flutter_test/flutter_test.dart';
import 'package:thought_circle/models/reflection.dart';

void main() {
  test('journal entries survive a JSON round trip', () {
    final now = DateTime.utc(2026, 7, 26, 12, 30);
    final original = JournalEntry(
      id: 'entry-1',
      title: 'A clearer afternoon',
      body: 'I noticed the same thought and took a short walk.',
      summary: 'A short walk made the thought feel more manageable.',
      highlights: const <String>['Paused before reacting', 'Moved my body'],
      source: JournalSource.voice,
      mood: JournalMood.hopeful,
      createdAt: now,
      updatedAt: now,
      linkedThoughtId: 'thought-1',
    );

    final restored = JournalEntry.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.source, JournalSource.voice);
    expect(restored.mood, JournalMood.hopeful);
    expect(restored.highlights, hasLength(2));
    expect(restored.linkedThoughtId, 'thought-1');
    expect(restored.shareText, contains('• Paused before reacting'));
  });

  test('guide turns survive a JSON round trip', () {
    final original = ChatTurn(
      id: 'turn-1',
      role: ChatRole.guide,
      text: 'Choose the smallest useful step.',
      createdAt: DateTime.utc(2026, 7, 26),
    );

    final restored = ChatTurn.fromJson(original.toJson());

    expect(restored.role, ChatRole.guide);
    expect(restored.text, original.text);
  });

  test('mood colors survive a JSON round trip', () {
    final original = MoodColorEntry(
      id: 'mood-1',
      colorValue: 0xFF7357FF,
      label: 'Violet',
      energy: 0.63,
      createdAt: DateTime.utc(2026, 7, 26),
      note: 'Quieter after a walk.',
    );

    final restored = MoodColorEntry.fromJson(original.toJson());

    expect(restored.colorValue, 0xFF7357FF);
    expect(restored.label, 'Violet');
    expect(restored.energy, 0.63);
    expect(restored.note, original.note);
  });
}
