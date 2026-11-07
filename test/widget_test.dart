import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mapa_escolar/data/repositories/school_repository.dart';
import 'package:mapa_escolar/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Ingreso de Aspirantes'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
