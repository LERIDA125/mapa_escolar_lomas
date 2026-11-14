import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dirección de contacto del Consejo Escolar para consultas de aspirantes.
const supportMailAddress = 'ce062auxiliares.abc.gob.ar';

/// Asunto prearmado del correo de la mesa de ayuda.
const supportMailSubject = 'Consulta - Mapa Escolar';

/// Arma la URI `mailto:` con destinatario y asunto ya codificados.
///
/// Se codifica el asunto con [Uri.encodeComponent] y no con
/// `Uri(queryParameters:)`, porque ese constructor convierte los espacios en
/// `+`, que dentro de `mailto:` no es un espacio sino un signo literal.
Uri buildSupportMailUri() {
  final subject = Uri.encodeComponent(supportMailSubject);
  return Uri.parse('mailto:$supportMailAddress?subject=$subject');
}

/// Abre el cliente de correo del dispositivo.
///
/// Devuelve `false` cuando no hay ninguna aplicación capaz de manejar
/// `mailto:` o cuando el canal de plataforma no está disponible (tests,
/// escritorio). Nunca propaga excepciones de plataforma.
Future<bool> launchSupportMail() async {
  final uri = buildSupportMailUri();
  try {
    if (!await canLaunchUrl(uri)) return false;
    return await launchUrl(uri);
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
