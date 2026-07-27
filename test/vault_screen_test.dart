import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thought_circle/screens/vault_screen.dart';
import 'package:thought_circle/services/vault_service.dart';
import 'package:thought_circle/state/app_controller.dart';

void main() {
  testWidgets('setup password fields accept focus by keyboard and click', (
    tester,
  ) async {
    final controller = AppController()..vaultAccess = VaultAccess.setupRequired;

    await tester.pumpWidget(
      MaterialApp(home: VaultScreen(controller: controller)),
    );
    await tester.pump();

    final fields = find.byType(EditableText);
    expect(fields, findsNWidgets(2));
    expect(
      tester.widget<EditableText>(fields.at(0)).focusNode.hasFocus,
      isTrue,
    );

    await tester.tap(find.widgetWithText(TextField, 'Confirm password'));
    await tester.pump();

    expect(
      tester.widget<EditableText>(fields.at(1)).focusNode.hasFocus,
      isTrue,
    );
  });
}
