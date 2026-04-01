import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gymdex/models/ejercicio.dart';
import 'package:gymdex/models/gruposMusculares.dart';
import 'package:gymdex/models/rutina.dart';
import 'package:gymdex/service/ejercicioService.dart';
import 'package:translator/translator.dart';

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
      isScrollControlled: true, // Para ocupar más espacio en pantalla
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Filtrar ejercicios según los grupos seleccionados
            final filteredExercises = ejerciciosDisponibles.where((e) {
              if (seleccionados.isEmpty) return true;
              return seleccionados.contains(e.grupo);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Column(
                children: [
                  // Barra superior del modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Ejercicios ${seleccionados.isNotEmpty ? '(${seleccionados.join(", ")})' : ''}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              setModalState(() {}); // Mostrar loading si hiciera falta
                              bool success = await Ejercicioservice()
                                  .syncExercisesFromApi();
                              if (success && mounted) {
                                await cargarEjercicios();
                                setModalState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Catálogo sincronizado con Simply Fitness'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.sync),
                            tooltip: "Sincronizar Simply Fitness",
                          ),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              crearEjercicio();
                            },
                            child: const Text("Crear"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredExercises.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                ejerciciosDisponibles.isEmpty
                                    ? "No tienes ejercicios guardados localmente.\n\nPresiona el botón de sincronizar (🔄) arriba para cargar la lista de Simply Fitness."
                                    : "No se encontraron ejercicios para los grupos seleccionados.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final e = filteredExercises[index];
                              return TranslatedExerciseTile(
                                ejercicio: e,
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
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Crear un ejercicio
  Future<void> crearEjercicio() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Ahora usamos las categorías principales (keys) como los grupos para filtrar mejor
        final List<String> availableMuscles = seleccionados.isEmpty
            ? gruposMusculares.keys.toList()
            : seleccionados.toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
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

class TranslatedExerciseTile extends StatefulWidget {
  final Ejercicio ejercicio;
  final VoidCallback onTap;

  const TranslatedExerciseTile({
    Key? key,
    required this.ejercicio,
    required this.onTap,
  }) : super(key: key);

  @override
  State<TranslatedExerciseTile> createState() => _TranslatedExerciseTileState();
}

class _TranslatedExerciseTileState extends State<TranslatedExerciseTile> {
  bool translating = false;

  @override
  void initState() {
    super.initState();
    _checkTranslation();
  }

  void _checkTranslation() async {
    if (widget.ejercicio.isTranslated == 0 && widget.ejercicio.gifUrl != null) {
      if (!mounted) return;
      setState(() => translating = true);

      try {
        final translator = GoogleTranslator();
        
        final translatedName = await translator.translate(widget.ejercicio.nombre, to: 'es');
        widget.ejercicio.nombre = translatedName.text;

        if (widget.ejercicio.target != null) {
          final translatedTarget = await translator.translate(widget.ejercicio.target!, to: 'es');
          widget.ejercicio.target = translatedTarget.text;
        }

        if (widget.ejercicio.equipment != null) {
          final translatedEq = await translator.translate(widget.ejercicio.equipment!, to: 'es');
          widget.ejercicio.equipment = translatedEq.text;
        }

        widget.ejercicio.isTranslated = 1;
        await Ejercicioservice().updateExerciseTranslation(widget.ejercicio);
      } catch (e) {
        print("Error translating: \$e");
      }

      if (mounted) {
        setState(() => translating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: widget.ejercicio.gifUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.ejercicio.gifUrl!,
              width: 50,
              height: 50,
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            )
          : const Icon(Icons.fitness_center),
      title: Text(
        widget.ejercicio.nombre,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (translating)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          Expanded(
            child: Text(
              widget.ejercicio.target ?? widget.ejercicio.grupo,
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Permitir hasta 2 líneas para la activación
            ),
          ),
        ],
      ),
      onTap: widget.onTap,
    );
  }
}
