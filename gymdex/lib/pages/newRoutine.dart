import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymdex/models/ejercicio.dart';
import 'package:gymdex/models/gruposMusculares.dart';
import 'package:gymdex/models/rutina.dart';
import 'package:gymdex/service/ejercicioService.dart';

class Newroutine extends StatefulWidget {
  final Rutina? rutina;
  const Newroutine({super.key, this.rutina});

  @override
  State<Newroutine> createState() => _NewroutineState();
}

class _NewroutineState extends State<Newroutine> {
  final _formKey = GlobalKey<FormState>();
  final _formKeyEjercicio = GlobalKey<FormState>();

  List<Ejercicio> ejerciciosDisponibles = [];

  List<String> seleccionados = [];
  List<Map<String, dynamic>> ejerciciosRutina = [];

  // Controladores de formulario principal
  final nombreController = TextEditingController();
  final diaController = TextEditingController();

  // Controladores de formulario ejercicio
  final nombreControllerEjercicio = TextEditingController();
  final grupoControllerEjercicio = TextEditingController();
  List<String> gruposSeleccionados = [];

  @override
  void initState() {
    super.initState();
    // Cargamos los ejercicios disponibles
    cargarEjercicios().then((_) {
      if (widget.rutina != null) {
        _loadRutinaData();
      }
    });
  }

  void _loadRutinaData() async {
    final rutina = widget.rutina!;
    nombreController.text = rutina.nombre;
    diaController.text = rutina.dia;

    final ejercicios = await Ejercicioservice().getExercisesByRoutine(
      rutina.id,
    );

    setState(() {
      ejerciciosRutina = ejercicios;
    });
  }

  /// Funcion para cargar los ejercicios disponibles
  Future<void> cargarEjercicios() async {
    final value = await Ejercicioservice().getAll();
    setState(() {
      ejerciciosDisponibles = value;
    });
  }

  /// Guardar rutina
  void guardarRutina() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (seleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Por favor seleccione al menos un grupo muscular",
          ),
          duration: const Duration(milliseconds: 1500),
          width: 280.0, // Width of the SnackBar.
          padding: EdgeInsets.all(10.0),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
      return;
    }

    if (ejerciciosRutina.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Por favor seleccione al menos un ejercicio"),
          duration: const Duration(milliseconds: 1500),
          width: 280.0, // Width of the SnackBar.
          padding: EdgeInsets.all(10.0),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
      return;
    }

    if (widget.rutina != null) {
      // Es una actualización
      await Ejercicioservice().updateRoutine(
        widget.rutina!.id,
        nombreController.text,
        diaController.text,
        ejerciciosRutina,
      );
    } else {
      // Es una creación nueva
      int rutinaId = await Ejercicioservice().saveRoutine(
        nombreController.text,
        diaController.text,
      );

      if (rutinaId != -1) {
        // Guardar relación de ejercicios
        for (var item in ejerciciosRutina) {
          Ejercicio ejercicio = item['ejercicio'];
          await Ejercicioservice().addExerciseToRoutine(
            rutinaId,
            ejercicio.id,
            item['sets'],
            item['reps'],
          );
        }
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rutina guardada"),
          duration: const Duration(milliseconds: 1500),
          width: 280.0, // Width of the SnackBar.
          padding: EdgeInsets.all(10.0),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
    }
  }

  /// Agregar ejercicio a la rutina
  void agregarEjercicio() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  "Ejercicios disponibles",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    crearEjercicio();
                  },
                  child: Text("Crear nuevo"),
                ),
              ],
            ),
            ...ejerciciosDisponibles.map((e) {
              return ListTile(
                title: Text(e.nombre),
                onTap: () {
                  setState(() {
                    ejerciciosRutina.add({
                      "ejercicio": e,
                      "sets": "3",
                      "reps": "10",
                    });
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  /// Crear un ejercicio
  Future<void> crearEjercicio() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        final List<String> availableMuscles = seleccionados.isEmpty
            ? gruposMusculares.values.expand((e) => e).toList()
            : seleccionados
                  .where((g) => gruposMusculares.containsKey(g))
                  .expand((g) => gruposMusculares[g]!)
                  .toList();

        return Form(
          key: _formKeyEjercicio,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Crear nuevo ejercicio",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Nombre del ejercicio"),
              TextFormField(controller: nombreControllerEjercicio),
              const SizedBox(height: 10),
              const Text("Grupo muscular"),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                isExpanded: true,
                hint: const Text("Selecciona un grupo"),
                value: availableMuscles.contains(grupoControllerEjercicio.text)
                    ? grupoControllerEjercicio.text
                    : null,
                items: availableMuscles.toSet().map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    grupoControllerEjercicio.text = val!;
                  });
                },
                validator: (value) =>
                    value == null ? "Seleccione un grupo" : null,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton.tinted(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancelar"),
                  ),
                  const SizedBox(width: 10),
                  CupertinoButton.filled(
                    onPressed: () async {
                      // validacion y guardado de ejercicio
                      if (!_formKeyEjercicio.currentState!.validate()) {
                        return;
                      }

                      // Creacion de objeto
                      final ejercicio = Ejercicio(
                        id: 0,
                        nombre: nombreControllerEjercicio.text,
                        grupo: grupoControllerEjercicio.text,
                      );

                      // Guardado de ejercicio
                      await Ejercicioservice().save(ejercicio);

                      // Recargar y limpiar
                      await cargarEjercicios();
                      nombreControllerEjercicio.clear();
                      grupoControllerEjercicio.clear();

                      // Regresamos a la pantalla anterior
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text("Guardar"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (mounted) agregarEjercicio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rutina == null ? "Nueva rutina" : "Editar rutina"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: guardarRutina,
        child: const Icon(Icons.save),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Nombre de la rutina"),
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingrese un nombre";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              const Text("Día de la semana"),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                initialValue: diaController.text.isEmpty
                    ? null
                    : diaController.text,
                hint: const Text("Selecciona un día"),
                items:
                    [
                      "Lunes",
                      "Martes",
                      "Miercoles",
                      "Jueves",
                      "Viernes",
                      "Sabado",
                      "Domingo",
                    ].map((dia) {
                      return DropdownMenuItem<String>(
                        value: dia,
                        child: Text(dia),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    diaController.text = value!;
                  });
                },
              ),
              const SizedBox(height: 10),

              const Text("Asignar grupo muscular"),

              Wrap(
                spacing: 8,
                children: gruposMusculares.keys.map((e) {
                  final selected = seleccionados.contains(e);

                  return FilterChip(
                    label: Text(e),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          seleccionados.add(e);
                        } else {
                          seleccionados.remove(e);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ejercicios"),
                  OutlinedButton(
                    onPressed: agregarEjercicio,
                    child: const Row(
                      children: [Icon(Icons.add), Text("Agregar ejercicio")],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ...ejerciciosRutina.map((e) {
                final ejercicio = e['ejercicio'] as Ejercicio;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ejercicio.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                initialValue: e['sets'],
                                onChanged: (val) => e['sets'] = val,
                                decoration: const InputDecoration(
                                  labelText: "Sets",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text("x", style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 60,
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                initialValue: e['reps'],
                                onChanged: (val) => e['reps'] = val,
                                decoration: const InputDecoration(
                                  labelText: "Reps",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  ejerciciosRutina.remove(e);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              if (ejerciciosRutina.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text("No hay ejercicios agregados"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
