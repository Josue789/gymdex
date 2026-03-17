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
      navigationBar: CupertinoNavigationBar.large(
        leading: CircleAvatar(child: Icon(Icons.person)),
      ),
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
          ? Center(child: Text("No hay rutinas creadas"))
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
        onTap: () {},
        onLongPress: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
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
                children: [
                  Text(
                    rutina.dia,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    rutina.nombre,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              // Podrías agregar una descripción o conteo de ejercicios aquí si quisieras
              // Text("Grupo muscular", ...),
              Text(
                "Toca para detalles",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  CupertinoButton.tinted(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Ver ejercicios"),
                    onPressed: () => verEjercicios(rutina),
                  ),
                  CupertinoButton.filled(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      spacing: 2,
                      children: [Icon(Icons.play_arrow), Text("Entrenar")],
                    ),
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            Traine(rutina: rutina),
                      );
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
