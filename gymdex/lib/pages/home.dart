import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymdex/models/rutina.dart';
import 'package:gymdex/pages/traine.dart';
import 'package:gymdex/service/ejercicioService.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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

  void _startTraining() async {
    final today = _getCurrentDayInSpanish();
    final routineForToday = await Ejercicioservice().getRoutineByDay(today);

    if (!mounted) return;

    if (routineForToday != null) {
      // Navegar a la pantalla de entrenamiento
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => Traine(rutina: routineForToday),
        ),
      );
    } else {
      // Mostrar un diálogo si no hay rutina
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text("Día de descanso"),
          content: Text("No hay ninguna rutina asignada para hoy ($today)."),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text("Ok"),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar.large(
        leading: CircleAvatar(child: Icon(Icons.person)),
        largeTitle: Text("GymDex"),
      ),
      child: SafeArea(
        minimum: EdgeInsets.all(10),
        child: Material(
          color: Colors.transparent,
          child: ListView(
            children: [
              Card.filled(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "¿Listo para sudar?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Tu progreso empieza ahora."),
                      SizedBox(height: 10),
                      CupertinoButton.filled(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow),
                            SizedBox(width: 8),
                            Text("Comenzar entrenamiento"),
                          ],
                        ),
                        onPressed: _startTraining,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
