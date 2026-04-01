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
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final CupertinoTabController _controller = CupertinoTabController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Lógica para manejar el swipe
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    // Si la velocidad es negativa, el usuario deslizó hacia la IZQUIERDA (<-), quiere ir a la SIGUIENTE tab
    if (details.primaryVelocity! < -200) {
      if (_controller.index < 3) {
        _controller.index += 1;
      }
    }
    // Si la velocidad es positiva, el usuario deslizó hacia la DERECHA (->), quiere ir a la tab ANTERIOR
    else if (details.primaryVelocity! > 200) {
      if (_controller.index > 0) {
        _controller.index -= 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _controller,
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "Workouts",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        // Envolvemos el contenido en un GestureDetector para capturar el deslizamiento
        return GestureDetector(
          onHorizontalDragEnd: _onHorizontalDragEnd,
          // HitTestBehavior.translucent asegura que detecte el gesto incluso en áreas vacías
          behavior: HitTestBehavior.translucent,
          child: CupertinoTabView(
            builder: (BuildContext context) {
              switch (index) {
                case 0:
                  return const Home();
                case 1:
                  return const Workouts();
                case 2:
                  return const History();
                case 3:
                  return const Settings();
                default:
                  return const Home();
              }
            },
          ),
        );
      },
    );
  }
}
