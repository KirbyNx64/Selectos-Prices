import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  testWidgets('renders search_off icon inside a circular primary container', (
    tester,
  ) async {
    const seedColor = Color(0xFF2E6C37);

    await tester.pumpWidget(
      M3ETheme(
        data: M3EThemeData.light(seedColor: seedColor),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.4,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No se encontraron productos',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final iconFinder = find.byIcon(Icons.search_off_rounded);
    expect(iconFinder, findsOneWidget);

    final containerFinder = find.ancestor(
      of: iconFinder,
      matching: find.byType(Container),
    );
    expect(containerFinder, findsOneWidget);

    final containerWidget = tester.widget<Container>(containerFinder);
    final boxDecoration = containerWidget.decoration as BoxDecoration?;
    expect(boxDecoration?.shape, BoxShape.circle);

    expect(find.text('No se encontraron productos'), findsOneWidget);
  });
}
