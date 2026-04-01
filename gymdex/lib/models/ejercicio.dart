class Ejercicio {
  int id;
  String nombre;
  String grupo;
  String? gifUrl;
  String? target;
  String? equipment;
  String? instructions;
  int isTranslated; // 0 para falso, 1 para verdadero

  Ejercicio({
    required this.id,
    required this.nombre,
    required this.grupo,
    this.gifUrl,
    this.target,
    this.equipment,
    this.instructions,
    this.isTranslated = 0,
  });

  static final Map<String, String> _traduccionesGrupos = {
    'back': 'Espalda',
    'cardio': 'Cardio',
    'chest': 'Pecho',
    'lower arms': 'Antebrazos',
    'lower legs': 'Pantorrillas',
    'neck': 'Cuello',
    'shoulders': 'Hombros',
    'upper arms': 'Brazos',
    'upper legs': 'Piernas',
    'waist': 'Abdomen',
  };

  // Constructor factory para crear desde JSON (útil para la API)
  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    String englishGrupo = (json['bodyPart'] ?? '').toString().toLowerCase();
    String spanishGrupo = _traduccionesGrupos[englishGrupo] ?? json['bodyPart'] ?? '';

    return Ejercicio(
      id: 0, // El ID se asinga al guardar en BD local
      nombre: json['name'] ?? '',
      grupo: spanishGrupo,
      gifUrl: json['gifUrl'],
      target: json['target'],
      equipment: json['equipment'],
      instructions: json['instructions'] != null
          ? (json['instructions'] as List).join('\n')
          : null,
      isTranslated: 0,
    );
  }

  // Convertir a Map para SQFlite
  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id, // Solo lo incluimos si ya tiene un ID en la BD
      'nombre': nombre,
      'grupo': grupo,
      'gifUrl': gifUrl,
      'target': target,
      'equipment': equipment,
      'instructions': instructions,
      'isTranslated': isTranslated,
    };
  }

  // Crear desde Map de SQFlite
  factory Ejercicio.fromMap(Map<String, dynamic> map) {
    return Ejercicio(
      id: map['id'],
      nombre: map['nombre'],
      grupo: map['grupo'],
      gifUrl: map['gifUrl'],
      target: map['target'],
      equipment: map['equipment'],
      instructions: map['instructions'],
      isTranslated: map['isTranslated'] ?? 0,
    );
  }
}
