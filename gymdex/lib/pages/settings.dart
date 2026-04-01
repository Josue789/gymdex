import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymdex/service/ejercicioService.dart';
import 'package:gymdex/pages/theme_manager.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(middle: Text("Configuraciones")),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: ListView(
            children: [
              // Sección de apariencia
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  "APARIENCIA",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: SwitchListTile(
                  secondary: Icon(Icons.dark_mode),
                  title: Text("Modo oscuro"),
                  value:
                      ThemeManager.instance.themeMode.value == ThemeMode.dark,
                  onChanged: (val) {
                    setState(() {
                      ThemeManager.instance.toggleTheme(val);
                    });
                  },
                ),
              ),

              // Sección de datos
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  "DATOS Y ALMACENAMIENTO",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.fitness_center),
                      title: Text("Gestionar ejercicios"),
                      trailing: Icon(Icons.chevron_right),
                      onTap: _gestionarEjercicios,
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.red),
                      title: Text(
                        "Borrar todos los datos",
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: _confirmarBorrado,
                    ),
                  ],
                ),
              ),

              // Sección de información
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  "ACERCA DE",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text("Acerca de GymDex"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: Text("GymDex"),
                        content: Text(
                          "Versión 1.0.0\nTu compañero de entrenamiento.",
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: Text("Cerrar"),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _gestionarEjercicios() async {
    // Cargamos ejercicios
    final ejercicios = await Ejercicioservice().getAll();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Scaffold(
              appBar: AppBar(
                title: Text("Lista de Ejercicios"),
                automaticallyImplyLeading: false,
              ),
              body: ListView.separated(
                itemCount: ejercicios.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final e = ejercicios[i];
                  return ListTile(
                    title: Text(e.nombre),
                    subtitle: Text(e.grupo),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey),
                      onPressed: () async {
                        await Ejercicioservice().deleteExercise(e.id);
                        // Actualizamos la lista local y redibujamos el modal
                        ejercicios.removeAt(i);
                        setStateModal(() {});
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarBorrado() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text("¿Estás seguro?"),
        content: Text(
          "Esta acción borrará todas tus rutinas, historial y récords personales. No se puede deshacer.",
        ),
        actions: [
          CupertinoDialogAction(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text("Borrar todo"),
            onPressed: () async {
              Navigator.pop(ctx);
              await Ejercicioservice().deleteAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Datos eliminados correctamente")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
