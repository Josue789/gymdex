import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymdex/models/ejercicio.dart';
import 'package:gymdex/models/rutina.dart';
import 'package:gymdex/pages/newRoutine.dart';
import 'package:gymdex/pages/traine.dart';
import 'package:gymdex/service/ejercicioService.dart';

class Workouts extends StatefulWidget {
  const Workouts({super.key});

  @override
  State<Workouts> createState() => _WorkoutsState();
}

class _WorkoutsState extends State<Workouts> {
  List<Rutina> _rutinas = [];
  Rutina? _todaysRoutine;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    getData();
  }

  String _getCurrentDayInSpanish() {
    final weekday = DateTime.now().weekday;
    const days = {
      1: "Lunes",
      2: "Martes",
      3: "Miercoles",
      4: "Jueves",
      5: "Viernes",
      6: "Sabado",
      7: "Domingo",
    };
    return days[weekday]!;
  }

  Future<void> getData() async {
    final service = Ejercicioservice();
    final allRoutines = await service.getAllRoutines();
    final todayRoutine = await service.getRoutineByDay(
      _getCurrentDayInSpanish(),
    );

    if (mounted) {
      setState(() {
        _rutinas = allRoutines;
        _todaysRoutine = todayRoutine;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Rutinas")),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await showCupertinoDialog(
                context: context,
                builder: (BuildContext context) {
                  return Newroutine();
                },
              );
              getData();
            },
            child: const Icon(Icons.add),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressCard(),
                      const SizedBox(height: 16),
                      if (_todaysRoutine != null) ...[
                        _buildSectionTitle('Rutina del día'),
                        _buildTodayRoutineCard(),
                        const SizedBox(height: 20),
                      ],
                      _buildSectionTitle('Tus rutinas'),
                      Expanded(child: _buildRoutineList()),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final total = _rutinas.length;
    final progress = total > 0 ? 1.0 : 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rutinas guardadas",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    color: Colors.lightBlueAccent,
                    backgroundColor: Colors.blueGrey.shade100,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  "$total rutinas",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _todaysRoutine != null
                  ? 'Rutina de hoy: ${_todaysRoutine!.nombre}'
                  : 'No hay rutina asignada hoy',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTodayRoutineCard() {
    final routine = _todaysRoutine!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(routine.dia, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(
                    builder: (context) => Traine(rutina: routine),
                  ),
                );
              },
              child: const Text('Entrenar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineList() {
    if (_rutinas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Aún no tienes rutinas guardadas.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 10),
            Text(
              'Presiona el botón + para crear una nueva rutina.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _rutinas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildRoutineCard(_rutinas[index]);
      },
    );
  }

  Widget _buildRoutineCard(Rutina rutina) {
    final isToday = _todaysRoutine?.id == rutina.id;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.list_alt, color: Colors.indigoAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rutina.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rutina.dia,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hoy',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await showCupertinoDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Newroutine(rutina: rutina);
                        },
                      );
                      getData();
                    },
                    child: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(
                        CupertinoPageRoute(
                          builder: (context) => Traine(rutina: rutina),
                        ),
                      );
                    },
                    child: const Text('Entrenar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exerciseData) {
    final ej = exerciseData['ejercicio'] as Ejercicio;
    final targetSets = exerciseData['sets'] ?? '3';
    final targetReps = exerciseData['reps'] ?? '10';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.indigoAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ej.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ej.grupo,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$targetSets x $targetReps",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (_todaysRoutine != null) {
                        Navigator.of(context, rootNavigator: true).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                Traine(rutina: _todaysRoutine),
                          ),
                        );
                      }
                    },
                    child: const Text("Log Set"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showExerciseDetails(exerciseData),
                    child: const Text("Review Sets"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetails(Map<String, dynamic> exerciseData) {
    final ej = exerciseData['ejercicio'] as Ejercicio;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ej.nombre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text('Grupo: ${ej.grupo}'),
              const SizedBox(height: 10),
              Text(
                'Series: ${exerciseData['sets']} • Reps: ${exerciseData['reps']}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Descripción',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(ej.target ?? 'No hay descripción disponible'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void verEjercicios(Rutina rutina) async {
    List<Map<String, dynamic>> ejercicios = await Ejercicioservice()
        .getExercisesByRoutine(rutina.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ejercicios de ${rutina.nombre}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ejercicios.isEmpty
                    ? const Center(
                        child: Text("Esta rutina no tiene ejercicios"),
                      )
                    : ListView.separated(
                        itemCount: ejercicios.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = ejercicios[index];
                          final ej = item['ejercicio'] as Ejercicio;
                          return ListTile(
                            title: Text(ej.nombre),
                            subtitle: Text(ej.grupo),
                            leading: const Icon(Icons.fitness_center),
                            trailing: Text("${item['sets']} x ${item['reps']}"),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRoutineActions(Rutina rutina) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text("Opciones para ${rutina.nombre}"),
        actions: [
          CupertinoActionSheetAction(
            child: const Text("Editar"),
            onPressed: () async {
              Navigator.pop(context);
              await showCupertinoDialog(
                context: context,
                builder: (BuildContext context) {
                  return Newroutine(rutina: rutina);
                },
              );
              getData();
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text("Eliminar"),
            onPressed: () async {
              Navigator.pop(context);
              await Ejercicioservice().deleteRoutine(rutina.id);
              getData();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text("Cancelar"),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
