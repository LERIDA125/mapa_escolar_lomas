/// Domain models for the school catalog.
///
/// The JSON shape mirrors `assets/escuelas_seed.json`, where each school
/// embeds its locality and its transport lines.
library;

class Locality {
  const Locality({required this.id, required this.name, required this.zone});

  final String id;
  final String name;
  final String zone;

  factory Locality.fromJson(Map<String, dynamic> json) {
    return Locality(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'zone': zone};
}

class TransportLine {
  const TransportLine({required this.id, required this.line});

  final String id;
  final String line;

  factory TransportLine.fromJson(Map<String, dynamic> json) {
    return TransportLine(
      id: json['id'] as String? ?? '',
      line: json['line'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'line': line};
}

class School {
  const School({
    required this.id,
    required this.name,
    required this.level,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.locality,
    required this.transportLines,
    this.turnos,
    this.modalidad,
    this.codigoOficial,
  });

  final String id;
  final String name;
  final String level;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final Locality locality;
  final List<TransportLine> transportLines;

  /// Shift(s) offered by the school (e.g. "Mañana", "Tarde"). Null when the
  /// source data does not inform it.
  final String? turnos;

  /// Educational modality (e.g. "Común", "Especial"). Null when unknown.
  final String? modalidad;

  /// Official establishment code from the nomenclador. Null when unknown.
  final String? codigoOficial;

  /// Human-readable placeholder for fields the nomenclador does not provide.
  static const notInformed = 'No informado';

  /// Shift label ready for UI. Never invents data: falls back to [notInformed].
  String get turnosLabel => turnos ?? notInformed;

  /// Modality label ready for UI.
  String get modalidadLabel => modalidad ?? notInformed;

  /// Official code label ready for UI.
  String get codigoOficialLabel => codigoOficial ?? notInformed;

  factory School.fromJson(Map<String, dynamic> json) {
    final locality = json['locality'] as Map<String, dynamic>?;
    final transportLines = json['transportLines'] as List<dynamic>?;

    return School(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      level: json['level'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      locality: locality == null
          ? const Locality(id: '', name: '', zone: '')
          : Locality.fromJson(locality),
      transportLines: (transportLines ?? const <dynamic>[])
          .map((line) => TransportLine.fromJson(line as Map<String, dynamic>))
          .toList(growable: false),
      turnos: json['turnos'] as String?,
      modalidad: json['modalidad'] as String?,
      codigoOficial: json['codigoOficial'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    'address': address,
    'phone': phone,
    'latitude': latitude,
    'longitude': longitude,
    'locality': locality.toJson(),
    'transportLines': transportLines.map((line) => line.toJson()).toList(),
    'turnos': turnos,
    'modalidad': modalidad,
    'codigoOficial': codigoOficial,
  };
}
