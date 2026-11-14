import 'package:flutter_test/flutter_test.dart';

import 'package:mapa_escolar/data/services/support_mail.dart';

void main() {
  group('URI de la mesa de ayuda', () {
    test('usa el esquema mailto y el destinatario del Consejo', () {
      final uri = buildSupportMailUri();

      expect(uri.scheme, 'mailto');
      expect(uri.path, supportMailAddress);
    });

    test('prearma el asunto con espacios codificados, no con signos más', () {
      final uri = buildSupportMailUri();

      expect(uri.query, 'subject=Consulta%20-%20Mapa%20Escolar');
      expect(uri.queryParameters['subject'], supportMailSubject);
    });

    test('solo lleva el asunto como parámetro', () {
      final uri = buildSupportMailUri();

      expect(uri.queryParameters.keys, ['subject']);
      expect(
        uri.toString(),
        'mailto:ce062auxiliares.abc.gob.ar?subject=Consulta%20-%20Mapa%20Escolar',
      );
    });
  });
}
