import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mapa_escolar/data/repositories/school_repository.dart';
import 'package:mapa_escolar/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Sin esto, la restauración de sesión del Splash consulta un canal de
    // plataforma inexistente en el entorno de test.
    SharedPreferences.setMockInitialValues({});
  });

  test('SchoolRepository parses the bundled seed asset', () async {
    final schools = await const SchoolRepository().getSchools();

    expect(schools, isNotEmpty);

    final school = schools.first;
    expect(school.id, isNotEmpty);
    expect(school.name, isNotEmpty);
    expect(school.locality.name, isNotEmpty);
    expect(school.transportLines, isA<List>());
  });

  testWidgets('splash hands off to the login screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: MapaEscolarApp()));

    expect(find.text('Consejo Escolar'), findsOneWidget);
    expect(find.text('MODO OFFLINE'), findsOneWidget);

    // El Splash espera 2700 ms de carga mínima más la restauración de sesión.
    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pumpAndSettle();

    expect(find.text('Ingreso de Aspirantes'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
