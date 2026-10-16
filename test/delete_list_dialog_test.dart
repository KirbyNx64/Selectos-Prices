import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  testWidgets('delete list dialog does not overflow on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      M3ETheme(
        data: M3EThemeData.light(seedColor: const Color(0xFF2E6C37)),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    M3EDialog.show<bool>(
                      context,
                      dialog: Material(
                        type: MaterialType.transparency,
                        child: M3EDialog(
                          title: '¿Eliminar esta lista?',
                          icon: const Icon(Icons.delete_outline_rounded),
                          content: const Text(
                            'Se eliminará la lista del 15/10/2026 · 16:45 y todos sus productos.',
                          ),
                          actions: [
                            M3EButton.text(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            M3EButton.filled(
                              onPressed: () => Navigator.pop(context, true),
                              shape: M3EButtonShape.round,
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
