import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gymdex/models/ejercicio.dart';
import 'package:gymdex/models/rutina.dart';
import 'package:gymdex/service/ejercicioService.dart';
import 'package:lottie/lottie.dart';

class Traine extends StatefulWidget {
  const Traine({super.key, this.rutina});

  final Rutina? rutina;

  @override
  State<Traine> createState() => _TraineState();
}

class _TraineState extends State<Traine> {
  List<Map<String, dynamic>> ejercicios = [];
  int terminado = 0;
  Timer? _countdownTimer;
  String _weightUnit = 'KG';

  @override
  void initState() {
    super.initState();
    // Cargar ejercicios de la rutina al iniciar la página
    loadEjercicios();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        int time = 3;
        showCupertinoDialog(
          context: context,
          builder: (BuildContext dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (
                timer,
              ) {
                if (!mounted) {
                  timer.cancel();
                  return;
                }

                setDialogState(() {
                  time--;
                });
                if (time == 0) {
                  timer.cancel();
                  _countdownTimer = null;
                  Navigator.of(dialogContext).pop();
                }
              });

              return CupertinoAlertDialog(
                title: const Text("Comienza tu entrenamiento en"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      '$time',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    });
  }

  /// Cargar ejercicios de la rutina
  void loadEjercicios() async {
    final data = await Ejercicioservice().getExercisesByRoutine(
      widget.rutina!.id,
    );

    final personalRecords = await Ejercicioservice().getPersonalRecords();
    final prMap = {
      for (var record in personalRecords)
        (record['ejercicioId'] as int):
            (record['pesoMaximo'] as num?)?.toDouble() ?? 0.0,
    };

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
          'is_added': false,
        };
      });

      final ejercicioObj = ej['ejercicio'] as Ejercicio;
      return {
        'ejercicio': ejercicioObj,
        'target_sets': ej['sets'],
        'target_reps': ej['reps'],
        'sets_data': setsData,
        'pr_weight': prMap[ejercicioObj.id] ?? 0.0,
        'is_complete': false,
      };
    }).toList();

    setState(() {
      ejercicios = ejerciciosConSets;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var ejercicio in ejercicios) {
      for (var set in (ejercicio['sets_data'] as List)) {
        set['weight_controller'].dispose();
        set['reps_controller'].dispose();
      }
    }
    super.dispose();
  }

  Color get _primaryColor => Colors.indigo.shade700;

  Future<void> _confirmFinishWorkout() async {
    final shouldFinish = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text("Finalizar entrenamiento"),
        content: const Text(
          "¿Estás seguro de que deseas finalizar el entrenamiento?",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          CupertinoDialogAction(
            child: const Text("Finalizar"),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (shouldFinish == true && mounted) {
      await _finishWorkout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmFinishWorkout();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.rutina?.nombre ?? 'Entrenamiento'),
          backgroundColor: _primaryColor,
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            onPressed: _confirmFinishWorkout,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Finalizar entrenamiento'),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Progreso de rutina',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${terminado} / ${ejercicios.length} ejercicios completos',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  minHeight: 10,
                                  value: ejercicios.isEmpty
                                      ? 0
                                      : terminado / ejercicios.length,
                                  color: Colors.lightBlueAccent,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Unidad de peso'),
                                    DropdownButton<String>(
                                      value: _weightUnit,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'KG',
                                          child: Text('KG'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'LBS',
                                          child: Text('LBS'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _weightUnit = value;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: ejercicios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildExerciseCard(ejercicios[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> ejercicio) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isComplete = ejercicio['is_complete'] ?? false;
    final ejercicioObj = ejercicio['ejercicio'] as Ejercicio;
    final hasImage =
        ejercicioObj.gifUrl != null && ejercicioObj.gifUrl!.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      color: isComplete
          ? (isDark
                ? Colors.green.shade900.withValues(alpha: 0.4)
                : Colors.green.shade50)
          : (isDark ? Colors.grey[900] : Colors.white),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        collapsedIconColor: Colors.indigo,
        iconColor: Colors.indigo,
        title: Text(
          ejercicioObj.nombre,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${ejercicio['target_sets']} x ${ejercicio['target_reps']}',
          style: const TextStyle(color: Colors.grey),
        ),
        children: [
          if (hasImage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: ejercicioObj.gifUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(
                    height: 140,
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 140,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.error_outline)),
                  ),
                ),
              ),
            ),
          if (hasImage) const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallPill(
                  'PR',
                  ejercicio['pr_weight'] > 0
                      ? '${ejercicio['pr_weight']} kg'
                      : 'Sin PR',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...((ejercicio['sets_data'] as List<Map<String, dynamic>>).map(
            (set) => _buildSetRow(set, ejercicio),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: OutlinedButton.icon(
              onPressed: () => _addSet(ejercicio),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar set'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallPill(String label, String value) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSetRow(
    Map<String, dynamic> setData,
    Map<String, dynamic> ejercicioData,
  ) {
    final bool isDone = setData['is_done'] ?? false;
    final bool isAdded = setData['is_added'] ?? false;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              setData['set_number'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: setData['weight_controller'],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.center,
              enabled: !isDone,
              decoration: InputDecoration(
                hintText: _weightUnit.toLowerCase(),
                filled: isDone,
                fillColor: isDone
                    ? (isDark ? Colors.grey[800] : Colors.grey.shade100)
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: setData['reps_controller'],
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              enabled: !isDone,
              decoration: InputDecoration(
                hintText: 'reps',
                filled: isDone,
                fillColor: isDone
                    ? (isDark ? Colors.grey[800] : Colors.grey.shade100)
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                setData['is_done'] = !isDone;
              });
              _updateProgress();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDone ? Colors.green.shade100 : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDone ? Icons.check_box : Icons.check_box_outline_blank,
                color: isDone ? Colors.green : Colors.grey.shade700,
              ),
            ),
          ),
          if (isAdded)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red.shade400,
              onPressed: () => _removeSet(ejercicioData, setData),
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
        'is_added': true,
      });
    });
  }

  void _removeSet(
    Map<String, dynamic> ejercicio,
    Map<String, dynamic> setData,
  ) {
    setState(() {
      final sets = ejercicio['sets_data'] as List<Map<String, dynamic>>;
      sets.remove(setData);
      for (var i = 0; i < sets.length; i++) {
        sets[i]['set_number'] = i + 1;
      }
      _updateProgress();
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
      if (completedExercises == ejercicios.length && ejercicios.isNotEmpty) {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: const Text("Rutina terminada"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "¡Buen trabajo! Has completado todos los ejercicios.",
                ),
                Lottie.asset(
                  'assets/Trophy.json',
                  width: 100,
                  height: 100,
                  repeat: false,
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("Ok"),
                onPressed: () {
                  Navigator.pop(context);
                  _finishWorkout();
                },
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _finishWorkout() async {
    final trainingId = await Ejercicioservice().saveTraining(widget.rutina?.id);

    if (trainingId != -1) {
      for (var ej in ejercicios) {
        final ejercicioObj = ej['ejercicio'] as Ejercicio;
        final sets = ej['sets_data'] as List<Map<String, dynamic>>;

        for (var set in sets) {
          if (set['is_done'] == true) {
            final enteredWeight =
                double.tryParse(set['weight_controller'].text) ?? 0.0;
            final weight = _weightUnit == 'LBS'
                ? enteredWeight * 0.45359237
                : enteredWeight;
            final reps = int.tryParse(set['reps_controller'].text) ?? 0;
            final setNum = set['set_number'];

            await Ejercicioservice().saveSet(
              trainingId,
              ejercicioObj.id,
              setNum,
              reps,
              weight,
            );

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
