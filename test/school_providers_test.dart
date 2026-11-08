import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mapa_escolar/data/repositories/school_repository.dart';
import 'package:mapa_escolar/domain/models/school_models.dart';
import 'package:mapa_escolar/providers/school_providers.dart';

void main() {
  const schools = [
    School(
      id: '901',
      name: 'EP 8',
      level: 'Primaria',
      address: 'GARONA Y PIAGGIO',
      phone: '',
      latitude: -34.7637,
      longitude: -58.4138,
      locality: Locality(id: '1', name: 'LOMAS DE Z', zone: 'Centro'),
      transportLines: [],
    ),
    School(
      id: '903',
      name: 'ES 80',
      level: 'Secundaria',
      address: 'BELGRANO 1675',
      phone: '',
      latitude: -34.7524,
      longitude: -58.3933,
      locality: Locality(id: '2', name: 'BANFIELD', zone: 'Norte'),
      transportLines: [],
    ),
    School(
      id: '904',
      name: 'Jardin 901',
      level: 'Inicial',
      address: 'MEDRANO 175',
      phone: '',
      latitude: -34.7484,
      longitude: -58.3930,
      locality: Locality(id: '3', name: 'TEMPERLEY', zone: 'Sur'),
      transportLines: [],
    ),
  ];

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        schoolRepositoryProvider.overrideWithValue(
          const _FakeSchoolRepository(schools),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('empty query returns the full catalog', () async {
    final container = createContainer();
    await container.read(schoolsProvider.future);

    final result = container.read(filteredSchoolsProvider);

    expect(result.value, hasLength(3));
  });

  test('loading and data states are forwarded untouched', () async {
    final container = createContainer();

    expect(container.read(filteredSchoolsProvider).isLoading, isTrue);

    await container.read(schoolsProvider.future);

    expect(container.read(filteredSchoolsProvider).hasValue, isTrue);
  });

  test('filters by name ignoring case', () async {
    final container = createContainer();
    await container.read(schoolsProvider.future);

    container.read(searchQueryProvider.notifier).state = 'ep 8';

    final result = container.read(filteredSchoolsProvider).value;

    expect(result, hasLength(1));
    expect(result!.single.name, 'EP 8');
  });

  test('trims text query before filtering school names', () async {
    final container = createContainer();
    await container.read(schoolsProvider.future);

    container.read(searchQueryProvider.notifier).state = '  ep 8  ';

    final result = container.read(filteredSchoolsProvider).value;

    expect(result, hasLength(1));
    expect(result!.single.name, 'EP 8');
  });

  test('filters by address', () async {
    final container = createContainer();
    await container.read(schoolsProvider.future);

    container.read(searchQueryProvider.notifier).state = 'belgrano';

    final result = container.read(filteredSchoolsProvider).value;

    expect(result, hasLength(1));
    expect(result!.single.id, '903');
  });

  test('filters by locality name', () async {
    final container = createContainer();
    await container.read(schoolsProvider.future);

    container.read(searchQueryProvider.notifier).state = 'temperley';

    final result = container.read(filteredSchoolsProvider).value;

    expect(result, hasLength(1));
    expect(result!.single.id, '904');
  });

  test('returns an empty list when nothing matches', () async {
    final container = createContainer();
    await container.read(schoolsProvider.future);

    container.read(searchQueryProvider.notifier).state = 'zzz';

    final result = container.read(filteredSchoolsProvider).value;

    expect(result, isEmpty);
  });
}

class _FakeSchoolRepository extends SchoolRepository {
  const _FakeSchoolRepository(this._schools);

  final List<School> _schools;

  @override
  Future<List<School>> getSchools({AssetBundle? bundle}) async => _schools;
}
