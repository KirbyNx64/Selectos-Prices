import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/screens/settings/settings_screen.dart';

void main() {
  final testBranches = [
    const SelectosBranch(
      id: '64',
      name: 'Sonsonate Los Leones',
      address: 'Avenida Oidor Ramírez de Quiñonez y Paseo 15 de Septiembre, Sonsonate.',
      zoneId: 'c4bc6420-14d7-4956-8271-b41711a9d74b',
      department: 'Sonsonate',
      municipality: 'Sonsonate',
    ),
    const SelectosBranch(
      id: '119',
      name: 'Acajutla',
      address: 'Centro Comercial Acajutla, avenida Obando y calle Las Conchitas, Sonsonate.',
      zoneId: '381eabe6-1f79-481f-baa7-9bb4f3e7b03f',
      department: 'Sonsonate',
      municipality: 'Acajutla',
    ),
    const SelectosBranch(
      id: '7',
      name: 'Escalón',
      address: 'Centro Comercial El Paseo local #7, Paseo General Escalón, San Salvador.',
      zoneId: '22dc8df4-5834-4b47-9c21-280a94d2ebaa',
      department: 'San Salvador',
      municipality: 'San Salvador',
    ),
  ];

  testWidgets('BranchPickerSheet displays web labels and pre-selects existing branch', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BranchPickerSheet(
            branches: testBranches,
            selectedBranchId: '64',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check web labels are present
    expect(
      find.text('Departamento de la sala de venta dónde desea retirar los productos'),
      findsOneWidget,
    );
    expect(
      find.text('Municipio de la sala de venta dónde desea retirar los productos'),
      findsOneWidget,
    );
    expect(
      find.text('Seleccione la sala de venta dónde retirará los productos'),
      findsOneWidget,
    );

    // Initial pre-selected values for Sonsonate Los Leones
    expect(find.text('Sonsonate'), findsNWidgets(2)); // Department and Municipality
    expect(find.text('Sonsonate Los Leones'), findsNWidgets(2)); // In dropdown and in preview card
    expect(find.text('Confirmar sala'), findsOneWidget);
  });

  testWidgets('BranchPickerSheet clearing department disables municipality and branch', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BranchPickerSheet(
            branches: testBranches,
            selectedBranchId: '64',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap clear on the first field (department)
    final closeButtons = find.byIcon(Icons.close_rounded);
    expect(closeButtons, findsWidgets);
    await tester.tap(closeButtons.first);
    await tester.pumpAndSettle();

    // Department should now be placeholder
    expect(find.text('Seleccione el departamento'), findsOneWidget);
    expect(find.text('Primero seleccione un departamento'), findsOneWidget);
    expect(find.text('Primero seleccione un municipio'), findsOneWidget);
  });
}
