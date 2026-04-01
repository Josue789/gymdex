import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gymdex/models/ejercicio.dart';
import 'package:gymdex/models/rutina.dart';
import 'package:gymdex/service/ejercicioService.dart';

class Traine extends StatefulWidget {
  const Traine({super.key, this.rutina});

  final Rutina? rutina;

  @override
  State<Traine> createState() => _TraineState();
}

class _TraineState extends State<Traine> {
  List<Map<String, dynamic>> ejercicios = [];
  int terminado = 0;

  @override
  void initState() {
    super.initState();
    loadEjercicios();
  }

  /// Cargar ejercicios de la rutina
  void loadEjercicios() async {
    final data = await Ejercicioservice().getExercisesByRoutine(
      widget.rutina!.id,
    );

    final ejerciciosConSets = data.map((ej) {
      final int setCount = int.tryParse(ej['sets'] ?? '3') ?? 3;
      final List<Map<String, dynamic>> setsData = List.generate(setCount, (
        index,
      ) {
        return {
          'set_number': index + 1,
          'weight_controller': TextEditingController(),
          'reps_controller': TextEditingController(),
          'is_done': false,
        };
      });

      return {
        'ejercicio': ej['ejercicio'],
        'target_sets': ej['sets'],
        'target_reps': ej['reps'],
        'sets_data': setsData,
        'is_complete': false,
      };
    }).toList();

    setState(() {
      ejercicios = ejerciciosConSets;
    });
  }

  @override
  void dispose() {
    for (var ejercicio in ejercicios) {
      for (var set in (ejercicio['sets_data'] as List)) {
        set['weight_controller'].dispose();
        set['reps_controller'].dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Entrenamiento")),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          onPressed: _finishWorkout,
          child: const Icon(Icons.stop_rounded),
        ),
      ),
      body: GestureDetector(
        onTap: () =>
            FocusScope.of(context).unfocus(), // Cierra teclado al tocar fuera
        child: SafeArea(
          child: Column(
            children: [
              Card(
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            "Progreso de rutina",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(
                              "$terminado / ${ejercicios.length}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            padding: EdgeInsets.all(0),
                            backgroundColor: Colors.blueGrey.shade100,
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: ejercicios.isEmpty
                              ? 0
                              : terminado / ejercicios.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  children: ejercicios.map((e) {
                    return cardEjercicios(e);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cardEjercicios(Map<String, dynamic> ejercicio) {
    final bool isComplete = ejercicio['is_complete'] ?? false;
    return Card(
      color: isComplete ? Colors.green.shade100 : null,
      elevation: 2,
      clipBehavior: Clip.antiAlias, // Mejora bordes visuales
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ExpansionTile(
          title: Text(
            ejercicio['ejercicio'].nombre,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${ejercicio['target_sets']} X ${ejercicio['target_reps']}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          trailing: isComplete
              ? Icon(Icons.check_circle, color: Colors.green)
              : Icon(Icons.keyboard_arrow_down),
          children: <Widget>[
            if (ejercicio['ejercicio'].gifUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: ejercicio['ejercicio'].gifUrl!,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const CupertinoActivityIndicator(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("SET", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "PESO (kg)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("REPS", style: TextStyle(fontWeight: FontWeight.bold)),
                  Icon(Icons.check, color: Colors.transparent), // Placeholder
                ],
              ),
            ),
            ...(ejercicio['sets_data'] as List<Map<String, dynamic>>).map((
              set,
            ) {
              return _buildSetRow(set, ejercicio);
            }).toList(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: OutlinedButton.icon(
                onPressed: () => _addSet(ejercicio),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Agregar Set"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(
    Map<String, dynamic> setData,
    Map<String, dynamic> ejercicioData,
  ) {
    bool isDone = setData['is_done'] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            setData['set_number'].toString(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: setData['weight_controller'],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "0.0",
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 5,
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: setData['reps_controller'],
              keyboardType: TextInputType.numberWithOptions(decimal: false),
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "0",
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 5,
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isDone ? Icons.check_box : Icons.check_box_outline_blank,
              color: isDone ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                setData['is_done'] = !isDone;
                _updateProgress();
              });
            },
          ),
        ],
      ),
    );
  }

  void _addSet(Map<String, dynamic> ejercicio) {
    final sets = ejercicio['sets_data'] as List<Map<String, dynamic>>;
    final int nextNumber = (sets.last['set_number'] as int) + 1;
    setState(() {
      sets.add({
        'set_number': nextNumber,
        'weight_controller': TextEditingController(),
        'reps_controller': TextEditingController(),
        'is_done': false,
      });
    });
  }

  void _updateProgress() {
    int completedExercises = 0;
    for (var ej in ejercicios) {
      final allSetsDone = (ej['sets_data'] as List).every(
        (set) => set['is_done'] == true,
      );
      if (allSetsDone) {
        ej['is_complete'] = true;
        completedExercises++;
      } else {
        ej['is_complete'] = false;
      }
    }
    setState(() {
      terminado = completedExercises;
      if (completedExercises == ejercicios.length) {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: Text("Rutina termina"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lottie
                Text("Buen trabajo!", style: TextStyle(fontSize: 20)),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  _finishWorkout(); // Guarda y sale de la pantalla
                },
              ),
            ],
          ),
        );
      }
    });
  }

  void _finishWorkout() async {
    // Guardamos el entrenamiento
    int trainingId = await Ejercicioservice().saveTraining(widget.rutina?.id);

    if (trainingId != -1) {
      // Recorremos los ejercicios y sus sets
      for (var ej in ejercicios) {
        final ejercicioObj = ej['ejercicio'] as Ejercicio;
        final sets = ej['sets_data'] as List<Map<String, dynamic>>;

        for (var set in sets) {
          // Guardar solo si está marcado como completado
          if (set['is_done'] == true) {
            double weight =
                double.tryParse(set['weight_controller'].text) ?? 0.0;
            int reps = int.tryParse(set['reps_controller'].text) ?? 0;
            int setNum = set['set_number'];

            // Guardar el set en la BD
            await Ejercicioservice().saveSet(
              trainingId,
              ejercicioObj.id,
              setNum,
              reps,
              weight,
            );

            // Verificar si es PR
            await Ejercicioservice().checkAndUpdatePR(
              ejercicioObj.id,
              weight,
              reps,
            );
          }
        }
      }
    }
    if (mounted) Navigator.pop(context);
  }
}
