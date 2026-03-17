import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymdex/pages/history.dart';
import 'package:gymdex/pages/home.dart';
import 'package:gymdex/pages/settings.dart';
import 'package:gymdex/pages/workouts.dart';
import 'package:gymdex/pages/theme_manager.dart';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  // Carga el tema guardado antes de correr la app
  await ThemeManager.instance.loadTheme();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.instance.themeMode,
      builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
        return MaterialApp(
          themeMode: themeMode,
          darkTheme: ThemeData.dark(useMaterial3: true),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent),
            brightness: Brightness.light,
          ),
          home: CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center),
                  label: "Workouts",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: "History",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: "Settings",
                ),
              ],
            ),
            tabBuilder: (BuildContext context, int index) {
              switch (index) {
                case 0:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      return Home();
                    },
                  );
                case 1:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      return Workouts();
                    },
                  );
                case 2:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      return History();
                    },
                  );
                case 3:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      return Settings();
                    },
                  );
                default:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      return Home();
                    },
                  );
              }
            },
          ),
        );
      },
    );
  }
}
