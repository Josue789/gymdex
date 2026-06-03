import 'package:gymdex/database/database_helper.dart';
import 'package:gymdex/models/ejercicio.dart';
import 'package:gymdex/models/rutina.dart';
import 'package:gymdex/service/api_service.dart';

class Ejercicioservice {
  /// Agregar ejercicio
  Future<int> save(Ejercicio data) async {
    final db = await DatabaseHelper.instance.database;
    try {
      return await db.insert('ejercicios', {
        'nombre': data.nombre,
        'grupo': data.grupo,
      });
    } catch (e) {
      return -1;
    }
  }

  /// Agregar rutina
  Future<int> saveRoutine(String nombre, String dia) async {
    final db = await DatabaseHelper.instance.database;

    try {
      return await db.insert('rutinas', {'nombre': nombre, 'dia': dia});
    } catch (e) {
      return -1;
    }
  }

  /// Añadir ejercicio a rutina
  Future<int> addExerciseToRoutine(
    int rutinaId,
    int ejercicioId,
    String sets,
    String reps,
  ) async {
    final db = await DatabaseHelper.instance.database;

    try {
      return await db.insert('rutinas_ejercicios', {
        'rutina_id': rutinaId,
        'ejercicio_id': ejercicioId,
        'series': int.tryParse(sets) ?? 3,
        'repeticiones': int.tryParse(reps) ?? 10,
      });
    } catch (e) {
      return -1;
    }
  }

  /// Añadir rutina a entrenamiento
  Future<int> addRoutineToTraining(Ejercicio data) async {
    final db = await DatabaseHelper.instance.database;

    try {
      return await db.insert('entrenamientos_rutinas', {
        'entrenamiento_id': data.nombre,
        'rutina_id': data.grupo,
      });
    } catch (e) {
      return -1;
    }
  }

  /// Actualizar traducción
  Future<void> updateExerciseTranslation(Ejercicio ej) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'ejercicios',
      ej.toMap(),
      where: 'id = ?',
      whereArgs: [ej.id],
    );
  }

  /// Sincronizar desde la lista local de Simply Fitness (Reemplaza la API anterior)
  Future<bool> syncExercisesFromApi() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Lista predefinida de Simply Fitness
      final simplyFitnessData = {
        "ejercicios_simply_fitness": [
          {
            "grupo_muscular": "Pectorales",
            "ejercicios": [
              {
                "nombre": "Press de banca con barra",
                "activacion_principal":
                    "Pectoral mayor, tríceps, deltoides anterior",
              },
              {
                "nombre": "Press banca inclinado con mancuernas",
                "activacion_principal": "Pectoral superior, deltoides anterior",
              },
              {
                "nombre": "Cruce de poleas",
                "activacion_principal":
                    "Pectoral mayor (enfoque en fibras internas)",
              },
              {
                "nombre": "Aperturas con mancuernas",
                "activacion_principal": "Pectoral mayor",
              },
              {
                "nombre": "Flexiones",
                "activacion_principal": "Pectoral, tríceps, core",
              },
            ],
          },
          {
            "grupo_muscular": "Espalda",
            "ejercicios": [
              {
                "nombre": "Jalón al pecho con agarre ancho",
                "activacion_principal": "Dorsal ancho, redondo mayor",
              },
              {
                "nombre": "Remo con mancuerna a una mano",
                "activacion_principal": "Dorsal ancho, romboides, trapecio",
              },
              {
                "nombre": "Remo con barra",
                "activacion_principal":
                    "Espalda media, dorsal ancho, erectores espinales",
              },
              {
                "nombre": "Peso muerto con barra",
                "activacion_principal":
                    "Cadena posterior, erectores espinales, dorsales",
              },
              {
                "nombre": "Jalón dorsal con brazos rectos",
                "activacion_principal": "Dorsal ancho (aislamiento)",
              },
            ],
          },
          {
            "grupo_muscular": "Hombros",
            "ejercicios": [
              {
                "nombre": "Press Militar (barra o mancuernas)",
                "activacion_principal": "Deltoides anterior y medio",
              },
              {
                "nombre": "Elevación lateral con mancuernas",
                "activacion_principal": "Deltoides medio",
              },
              {
                "nombre": "Elevación frontal con mancuernas",
                "activacion_principal": "Deltoides anterior",
              },
              {
                "nombre": "Cruces inversos en polea alta",
                "activacion_principal": "Deltoides posterior, romboides",
              },
              {
                "nombre": "Remo alto con barra",
                "activacion_principal": "Deltoides lateral, trapecio superior",
              },
            ],
          },
          {
            "grupo_muscular": "Piernas",
            "ejercicios": [
              {
                "nombre": "Sentadilla frontal",
                "activacion_principal": "Cuádriceps, core, glúteos",
              },
              {
                "nombre": "Peso muerto rumano (barra o mancuernas)",
                "activacion_principal": "Isquiotibiales, glúteo mayor",
              },
              {
                "nombre": "Sentadilla búlgara",
                "activacion_principal": "Cuádriceps, glúteos, estabilizadores",
              },
              {
                "nombre": "Extensión de piernas en máquina",
                "activacion_principal": "Cuádriceps (aislamiento)",
              },
              {
                "nombre": "Curl de piernas sentado",
                "activacion_principal": "Isquiotibiales",
              },
            ],
          },
          {
            "grupo_muscular": "Brazos y Core",
            "ejercicios": [
              {
                "nombre": "Curl de bíceps con barra",
                "activacion_principal": "Bíceps braquial",
              },
              {
                "nombre": "Jalón en polea con cuerda (tríceps)",
                "activacion_principal": "Tríceps braquial",
              },
              {
                "nombre": "Press francés",
                "activacion_principal": "Tríceps (cabeza larga)",
              },
              {
                "nombre": "Crunch abdominal",
                "activacion_principal": "Recto abdominal",
              },
              {
                "nombre": "Elevación de piernas",
                "activacion_principal":
                    "Abdominales inferiores, flexores de cadera",
              },
            ],
          },
        ],
      };

      await db.transaction((txn) async {
        // 1. Limpiar ejercicios anteriores por completo
        await txn.delete('ejercicios');

        // 2. Insertar los nuevos de Simply Fitness
        for (var grupo in simplyFitnessData["ejercicios_simply_fitness"]!) {
          String nombreGrupo = grupo["grupo_muscular"] as String;
          List ejercicios = grupo["ejercicios"] as List;

          for (var ej in ejercicios) {
            await txn.insert('ejercicios', {
              'nombre': ej['nombre'],
              'grupo': nombreGrupo,
              'target': ej['activacion_principal'],
              'isTranslated': 1,
            });
          }
        }
      });

      return true;
    } catch (e) {
      print("Error syncing local catalog: $e");
      return false;
    }
  }

  /// Obtener todos los ejercicios
  Future<List<Ejercicio>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('ejercicios');
    return maps.map((map) => Ejercicio.fromMap(map)).toList();
  }

  /// Obtener todas las rutinas
  Future<List<Rutina>> getAllRoutines() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('rutinas');
    return List.generate(maps.length, (i) {
      return Rutina(
        id: maps[i]['id'],
        nombre: maps[i]['nombre'],
        dia: maps[i]['dia'] ?? 'Sin día',
      );
    });
  }

  /// Obtener ejercicios por ID de rutina
  Future<List<Map<String, dynamic>>> getExercisesByRoutine(
    int routineId,
  ) async {
    final db = await DatabaseHelper.instance.database;

    // Hacemos un JOIN para traer los ejercicios asociados a la rutina
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT e.*, re.series, re.repeticiones
      FROM ejercicios e
      INNER JOIN rutinas_ejercicios re ON e.id = re.ejercicio_id
      WHERE re.rutina_id = ?
    ''',
      [routineId],
    );

    return List.generate(maps.length, (i) {
      final ejercicio = Ejercicio.fromMap(maps[i]);
      return {
        'ejercicio': ejercicio,
        'sets': (maps[i]['series'] ?? 3).toString(),
        'reps': (maps[i]['repeticiones'] ?? 10).toString(),
      };
    });
  }

  /// Eliminar rutina
  Future<void> deleteRoutine(int id) async {
    final db = await DatabaseHelper.instance.database;
    // Primero eliminamos las relaciones
    await db.delete(
      'rutinas_ejercicios',
      where: 'rutina_id = ?',
      whereArgs: [id],
    );
    // Luego eliminamos la rutina
    await db.delete('rutinas', where: 'id = ?', whereArgs: [id]);
  }

  /// Actualizar una rutina existente
  Future<void> updateRoutine(
    int rutinaId,
    String nombre,
    String dia,
    List<Map<String, dynamic>> ejercicios,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Actualizar los detalles de la rutina
      await txn.update(
        'rutinas',
        {'nombre': nombre, 'dia': dia},
        where: 'id = ?',
        whereArgs: [rutinaId],
      );

      // 2. Eliminar las asociaciones de ejercicios antiguas
      await txn.delete(
        'rutinas_ejercicios',
        where: 'rutina_id = ?',
        whereArgs: [rutinaId],
      );

      // 3. Insertar las nuevas asociaciones de ejercicios
      for (var item in ejercicios) {
        Ejercicio ejercicio = item['ejercicio'];
        String sets = item['sets'] ?? '3';
        String reps = item['reps'] ?? '10';
        await txn.insert('rutinas_ejercicios', {
          'rutina_id': rutinaId,
          'ejercicio_id': ejercicio.id,
          'series': int.tryParse(sets) ?? 3,
          'repeticiones': int.tryParse(reps) ?? 10,
        });
      }
    });
  }

  /// Guardar entrenamiento
  Future<int> saveTraining(int? rutinaId) async {
    final db = await DatabaseHelper.instance.database;
    try {
      return await db.insert('entrenamientos', {
        'fecha': DateTime.now().toIso8601String(),
        'rutinaId': rutinaId,
      });
    } catch (e) {
      return -1;
    }
  }

  /// Guardar set individual
  Future<void> saveSet(
    int trainingId,
    int exerciseId,
    int serie,
    int reps,
    double peso,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('registro_series', {
      'entrenamientoId': trainingId,
      'ejercicioId': exerciseId,
      'serie': serie,
      'repeticiones': reps,
      'peso': peso,
    });
  }

  /// Verificar y actualizar PR
  Future<void> checkAndUpdatePR(int ejercicioId, double peso, int reps) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> records = await db.query(
      'record_personal',
      where: 'ejercicioId = ?',
      whereArgs: [ejercicioId],
    );

    if (records.isEmpty) {
      await db.insert('record_personal', {
        'ejercicioId': ejercicioId,
        'pesoMaximo': peso,
        'repeticiones': reps,
        'fecha': DateTime.now().toIso8601String(),
      });
    } else {
      final pr = records.first;
      final double maxPeso = pr['pesoMaximo'];
      // Si el peso es mayor, actualizamos el PR
      if (peso > maxPeso) {
        await db.update(
          'record_personal',
          {
            'pesoMaximo': peso,
            'repeticiones': reps,
            'fecha': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [pr['id']],
        );
      }
    }
  }

  /// Obtener historial de entrenamientos con volumen total
  Future<List<Map<String, dynamic>>> getTrainingHistory() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT e.id, e.fecha, r.nombre as rutinaNombre, SUM(rs.peso * rs.repeticiones) as volumenTotal
      FROM entrenamientos e
      LEFT JOIN rutinas r ON e.rutinaId = r.id
      LEFT JOIN registro_series rs ON e.id = rs.entrenamientoId
      GROUP BY e.id
      ORDER BY e.fecha DESC
    ''');
  }

  /// Obtener PRs
  Future<List<Map<String, dynamic>>> getPersonalRecords() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT pr.*, ej.nombre as ejercicioNombre, ej.grupo as grupoNombre
      FROM record_personal pr
      INNER JOIN ejercicios ej ON pr.ejercicioId = ej.id
      ORDER BY ej.nombre ASC
    ''');
  }

  /// Eliminar un ejercicio específico y sus datos relacionados
  Future<void> deleteExercise(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Borramos referencias para mantener consistencia
      await txn.delete(
        'rutinas_ejercicios',
        where: 'ejercicio_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'record_personal',
        where: 'ejercicioId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'registro_series',
        where: 'ejercicioId = ?',
        whereArgs: [id],
      );
      // Borramos el ejercicio
      await txn.delete('ejercicios', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Borrar todos los datos de usuario (Reset de fábrica)
  Future<void> deleteAllData() async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('registro_series');
      await txn.delete('entrenamientos');
      await txn.delete('record_personal');
      await txn.delete('rutinas_ejercicios');
      await txn.delete('rutinas');
      // Opcional: await txn.delete('ejercicios'); si quisieras borrar el catálogo también
    });
  }

  /// Obtener rutina por día de la semana
  Future<Rutina?> getRoutineByDay(String day) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rutinas',
      where: 'LOWER(dia) = LOWER(?)',
      whereArgs: [day],
      limit: 1, // Solo necesitamos la primera coincidencia
    );

    if (maps.isNotEmpty) {
      return Rutina(
        id: maps.first['id'],
        nombre: maps.first['nombre'],
        dia: maps.first['dia'],
      );
    }
    return null; // No se encontró rutina para ese día
  }
}
