import 'package:gymdex/database/database_helper.dart';
import 'package:gymdex/models/ejercicio.dart';
import 'package:gymdex/models/rutina.dart';

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

  /// Obtener todos los ejercicios
  Future<List<Ejercicio>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('ejercicios');
    return List.generate(maps.length, (i) {
      return Ejercicio(
        id: maps[i]['id'],
        nombre: maps[i]['nombre'],
        grupo: maps[i]['grupo'],
      );
    });
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
      final ejercicio = Ejercicio(
        id: maps[i]['id'],
        nombre: maps[i]['nombre'],
        grupo: maps[i]['grupo'],
      );
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
      SELECT pr.*, ej.nombre as ejercicioNombre
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
}
