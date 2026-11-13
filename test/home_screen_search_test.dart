import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mapa_escolar/domain/models/school_models.dart';
import 'package:mapa_escolar/presentation/screens/home_screen.dart';
import 'package:mapa_escolar/providers/school_providers.dart';

School _school({
  required String id,
  required String name,
  required String level,
  required double latitude,
  required double longitude,
}) {
  return School(
    id: id,
    name: name,
    level: level,
    address: 'Calle 1',
    phone: '',
    latitude: latitude,
    longitude: longitude,
    locality: const Locality(id: 'l', name: 'Lomas de Zamora', zone: 'Centro'),
    transportLines: const [],
  );
}

void main() {
  testWidgets('narrowing the search to a single school does not crash', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final schools = [
      _school(
        id: '1',
        name: '32',
        level: 'Primarias',
        latitude: -34.75,
        longitude: -58.40,
      ),
      _school(
        id: '2',
        name: '80',
        level: 'Secundarias',
        latitude: -34.75,
        longitude: -58.40,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [schoolsProvider.overrideWith((ref) async => schools)],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '32');
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    expect(find.text('PP 32'), findsOneWidget);
  });

  testWidgets('map markers show school abbreviations and numbers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final schools = [
      _school(
        id: '1',
        name: '940',
        level: 'Jardines de Infantes',
        latitude: -34.75,
        longitude: -58.40,
      ),
      _school(
        id: '2',
        name: '80',
        level: 'Secundarias',
        latitude: -34.75,
        longitude: -58.40,
      ),
      _school(
        id: '3',
        name: '12',
        level: 'Técnicas',
        latitude: -34.75,
        longitude: -58.40,
      ),
      _school(
        id: '4',
        name: '7',
        level: 'Adultos',
        latitude: -34.75,
        longitude: -58.40,
      ),
      _school(
        id: '5',
        name: '450',
        level: 'CENS',
        latitude: -34.75,
        longitude: -58.40,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [schoolsProvider.overrideWith((ref) async => schools)],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('JI 940'), findsOneWidget);
    expect(find.text('ES 80'), findsOneWidget);
    expect(find.text('MT 12'), findsOneWidget);
    expect(find.text('EEPA 7'), findsOneWidget);
    expect(find.text('CENS 450'), findsOneWidget);
  });
}
