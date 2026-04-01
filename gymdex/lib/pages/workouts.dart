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
  List<Rutina> rutinas = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    final data = await Ejercicioservice().getAllRoutines();
    setState(() {
      rutinas = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text("Rutinas")),
      child: SafeArea(child: Content()),
    );
  }

  Widget Content() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return Newroutine();
            },
          );
          // Recargar al volver
          getData();
        },
        child: Icon(Icons.add),
      ),
      body: rutinas.isEmpty
          ? Center(
              child: Text(
                "No hay rutinas registradas",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  decoration: TextDecoration.none,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: rutinas.length,
              itemBuilder: (context, index) {
                return RoutineCard(rutinas[index]);
              },
            ),
    );
  }

  // Modal para ver ejercicios
  void verEjercicios(Rutina rutina) async {
    List<Map<String, dynamic>> ejercicios = await Ejercicioservice()
        .getExercisesByRoutine(rutina.id);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ejercicios de ${rutina.nombre}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ejercicios.isEmpty
                    ? Center(child: Text("Esta rutina no tiene ejercicios"))
                    : ListView.separated(
                        itemCount: ejercicios.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, index) {
                          final item = ejercicios[index];
                          final ej = item['ejercicio'] as Ejercicio;
                          return ListTile(
                            title: Text(ej.nombre),
                            subtitle: Text(ej.grupo),
                            leading: Icon(Icons.fitness_center),
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

  // Tarjeta de rutina
  Widget RoutineCard(Rutina rutina) {
    return Card(
      child: InkWell(
        onTap: () {
          verEjercicios(rutina);
        },
        onLongPress: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              title: Text("Opciones para ${rutina.nombre}"),
              actions: [
                CupertinoActionSheetAction(
                  child: Text("Editar"),
                  onPressed: () async {
                    Navigator.pop(context);
                    await showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Newroutine(rutina: rutina);
                      },
                    );
                    // Recargar al volver
                    getData();
                  },
                ),
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  child: Text("Eliminar"),
                  onPressed: () async {
                    Navigator.pop(context);
                    await Ejercicioservice().deleteRoutine(rutina.id);
                    getData();
                  },
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                child: Text("Cancelar"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              Row(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rutina.dia,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        rutina.nombre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Botón de opciones explícito
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          title: Text("Opciones para ${rutina.nombre}"),
                          actions: [
                            CupertinoActionSheetAction(
                              child: Text("Editar"),
                              onPressed: () async {
                                Navigator.pop(context);
                                await showCupertinoDialog(
                                  context: context,
                                  builder: (ctx) => Newroutine(rutina: rutina),
                                );
                                getData();
                              },
                            ),
                            CupertinoActionSheetAction(
                              isDestructiveAction: true,
                              child: Text("Eliminar"),
                              onPressed: () async {
                                Navigator.pop(context);
                                await Ejercicioservice().deleteRoutine(
                                  rutina.id,
                                );
                                getData();
                              },
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            child: Text("Cancelar"),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Mostrar los grupos musuculares que se trabajan
              FutureBuilder(
                future: Ejercicioservice().getExercisesByRoutine(rutina.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final exercises =
                        snapshot.data as List<Map<String, dynamic>>;
                    final groups = exercises
                        .map((e) => (e['ejercicio'] as Ejercicio).grupo)
                        .toSet()
                        .join(", ");
                    return Text(
                      groups.isEmpty ? "Sin ejercicios" : groups,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  }
                  return const Text(
                    "Cargando...",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  );
                },
              ),
              SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  CupertinoButton.filled(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    minSize: 40,
                    child: Row(
                      spacing: 2,
                      children: [Icon(Icons.play_arrow), Text("Entrenar")],
                    ),
                    onPressed: () async {
                      await Navigator.of(context, rootNavigator: true).push(
                        CupertinoPageRoute(
                          builder: (context) => Traine(rutina: rutina),
                        ),
                      );
                      getData();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
