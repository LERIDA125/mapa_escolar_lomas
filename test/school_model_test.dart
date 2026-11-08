import 'package:flutter_test/flutter_test.dart';

import 'package:mapa_escolar/domain/models/school_models.dart';

void main() {
  test('fromJson maps the optional school data fields', () {
    final school = School.fromJson({
      'id': '901',
      'name': 'EP 8',
      'level': 'Primaria',
      'address': 'GARONA Y PIAGGIO',
      'phone': '',
      'latitude': -34.7637,
      'longitude': -58.4138,
      'locality': {'id': '1', 'name': 'LOMAS DE Z', 'zone': 'Centro'},
      'transportLines': [],
      'turnos': 'Mañana',
      'modalidad': 'Común',
      'codigoOficial': '060123400',
    });

    expect(school.turnos, 'Mañana');
    expect(school.modalidad, 'Común');
    expect(school.codigoOficial, '060123400');
  });

  test('fromJson tolerates a seed without the optional fields', () {
    final school = School.fromJson({
      'id': '901',
      'name': 'EP 8',
      'locality': {'id': '1', 'name': 'LOMAS DE Z', 'zone': 'Centro'},
      'transportLines': [],
    });

    expect(school.turnos, isNull);
    expect(school.modalidad, isNull);
    expect(school.codigoOficial, isNull);
    expect(school.turnosLabel, School.notInformed);
    expect(school.modalidadLabel, School.notInformed);
    expect(school.codigoOficialLabel, School.notInformed);
  });

  test('toJson round-trips the optional school data fields', () {
    final school = School.fromJson({
      'id': '901',
      'name': 'EP 8',
      'locality': {'id': '1', 'name': 'LOMAS DE Z', 'zone': 'Centro'},
      'transportLines': [],
      'turnos': 'Tarde',
      'modalidad': 'Especial',
      'codigoOficial': '060123400',
    });

    final json = school.toJson();

    expect(json['turnos'], 'Tarde');
    expect(json['modalidad'], 'Especial');
    expect(json['codigoOficial'], '060123400');
    expect(School.fromJson(json).codigoOficial, '060123400');
  });
}
