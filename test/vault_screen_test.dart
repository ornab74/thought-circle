import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thought_circle/screens/vault_screen.dart';
import 'package:thought_circle/services/vault_service.dart';
import 'package:thought_circle/state/app_controller.dart';

void main() {
  testWidgets('first boot leads to optional password setup', (tester) async {
    final controller = AppController()..vaultAccess = VaultAccess.setupRequired;

    await tester.pumpWidget(
      MaterialApp(home: VaultScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Welcome to Thought Circle'), findsOneWidget);
    await tester.tap(find.text('Set up my circle'));
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
