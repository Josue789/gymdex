import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymdex/models/rutina.dart';
import 'package:gymdex/pages/traine.dart';
import 'package:gymdex/service/cloudService.dart';
import 'package:gymdex/service/ejercicioService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Rutina? _todaysRoutine;
  bool _isLoading = true;
  int _workoutsThisWeek = 0;
  List<Map<String, dynamic>> _recentPRs = [];
  Map<String, dynamic> weatherData = {};
  bool _isWeatherLoading = true;
  String _city = "Moroleon";

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadSavedCity();
  }

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

  // Cargar datos del dashboard
  void _loadDashboardData() async {
    final today = _getCurrentDayInSpanish();
    final service = Ejercicioservice();

    // 1. Obtener rutina de hoy
    final routine = await service.getRoutineByDay(today);

    // 2. Calcular entrenamientos de esta semana
    final history = await service.getTrainingHistory();
    final now = DateTime.now();
    // Obtener el lunes de la semana actual
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    // Filtrar historial
    final weeklyCount = history.where((h) {
      final date = DateTime.parse(h['fecha']);
      return date.isAfter(startOfWeek.subtract(Duration(seconds: 1)));
    }).length;

    // 3. Obtener algunos PRs (tomamos los primeros 3 para mostrar)
    final prs = await service.getPersonalRecords();

    if (mounted) {
      setState(() {
        _todaysRoutine = routine;
        _workoutsThisWeek = weeklyCount;
        _recentPRs = prs.take(3).toList();
        _isLoading = false;
      });
    }
  }

  // Iniciar entrenamiento
  void _startTraining() async {
    if (_todaysRoutine != null) {
      // Navegar a la pantalla de entrenamiento
      await Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
          builder: (context) => Traine(rutina: _todaysRoutine),
        ),
      );
      // Recargar datos al volver
      _loadDashboardData();
    } else {
      // Mostrar un diálogo si no hay rutina
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text("Día de descanso"),
          content: Text("No hay ninguna rutina asignada para hoy."),
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

  // Cargar ciudad guardada
  void _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('saved_city');
    if (savedCity != null && mounted) {
      setState(() => _city = savedCity);
    }
    _loadWeather();
  }

  // Cargar clima
  void _loadWeather() async {
    final data = await Cloudservice().getWeather(_city);
    if (mounted) {
      setState(() {
        // Si data es null, asignamos un mapa vacío
        weatherData = data ?? {};
        _isWeatherLoading = false;
      });
    }
  }

  // Mapeo de descripción a Icono
  IconData _getWeatherIcon(String? description) {
    if (description == null) return Icons.help_outline;
    if (description.contains("Sunny") || description.contains("Clear"))
      return Icons.wb_sunny;
    if (description.contains("Partly")) return Icons.wb_cloudy;
    if (description.contains("Cloudy") || description.contains("Mist"))
      return Icons.cloud;
    if (description.contains("Rain") || description.contains("Shower"))
      return Icons.grain;
    if (description.contains("Snow")) return Icons.ac_unit;
    if (description.contains("Thunder")) return Icons.flash_on;
    return Icons.cloud; // Default
  }

  // Mapeo de descripción a Color
  Color _getWeatherColor(String? description) {
    if (description == null) return Colors.grey;
    if (description.contains("Sunny") || description.contains("Clear"))
      return Colors.orange;
    if (description.contains("Partly")) return Colors.orangeAccent;
    if (description.contains("Cloudy") || description.contains("Mist"))
      return Colors.blueGrey;
    if (description.contains("Rain") || description.contains("Shower"))
      return Colors.blue;
    if (description.contains("Snow")) return Colors.lightBlue;
    if (description.contains("Thunder")) return Colors.deepPurple;
    return Colors.blueAccent;
  }

  String _translateWeather(String? description) {
    if (description == null) return "";
    const translations = {
      'Sunny': 'soleado',
      'Partly cloudy': 'parcialmente nublado',
      'Cloudy': 'nublado',
      'Rain': 'lluvioso',
      'Clear': 'despejado',
      'Snow': 'nevado',
      'Thunderstorm': 'tormenta',
      'Light rain': 'lluvia ligera',
      'Mist': 'neblina',
    };
    return translations[description] ?? description;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text("GymDex")),
      child: SafeArea(
        minimum: EdgeInsets.all(10),
        child: Material(
          color: Colors.transparent,
          child: ListView(
            children: [
              _isWeatherLoading ? _buildSkeletonWeather() : _buildWeatherCard(),

              // Dashboard Principal (Rutina de hoy)
              _isLoading ? _buildSkeletonDashboard() : _buildTodayCard(),

              SizedBox(height: 20),

              // Títulos y secciones inferiores (Solo visible cuando carga el dashboard)
              if (!_isLoading) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    "Tu semana",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                // Tarjeta de Resumen Semanal
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Entrenamientos",
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "$_workoutsThisWeek completados",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_recentPRs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      "Tus mejores marcas (PRs)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPRList(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta de "Rutina de Hoy" con datos cargados
  Widget _buildTodayCard() {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¿Listo para sudar?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              _todaysRoutine != null
                  ? "Hoy toca: ${_todaysRoutine!.nombre}"
                  : "Hoy es día de descanso o sin asignar.",
            ),
            SizedBox(height: 10),
            CupertinoButton.filled(
              onPressed: _startTraining,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text("Comenzar entrenamiento"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SKELETON: Dashboard principal
  Widget _buildSkeletonDashboard() {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título simulado
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            SizedBox(height: 10),
            // Texto cuerpo simulado
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            SizedBox(height: 20),
            // Botón simulado
            Container(
              width: double.infinity,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SKELETON: Clima
  Widget _buildSkeletonWeather() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.grey.withOpacity(0.3)),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  color: Colors.grey.withOpacity(0.3),
                ),
                SizedBox(height: 5),
                Container(
                  width: 80,
                  height: 14,
                  color: Colors.grey.withOpacity(0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (weatherData.isEmpty)
      return SizedBox.shrink(); // Si falló la carga, no mostrar nada

    final description = weatherData['description'];
    final icon = _getWeatherIcon(description);
    final color = _getWeatherColor(description);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'hoy será un día ${_translateWeather(description)}',
                    style: TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Temperatura: ${weatherData['temperature']}'),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                final textController = TextEditingController(text: _city);
                showCupertinoDialog(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: Text("Configuracion de clima"),
                    content: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Row(
                        children: [
                          Icon(Icons.cloud, color: Colors.blue),
                          SizedBox(width: 10),
                          Expanded(
                            child: CupertinoTextField(
                              controller: textController,
                              placeholder: "Ciudad a consultar",
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: Text("Cancelar"),
                        onPressed: () {
                          Navigator.pop(ctx);
                        },
                      ),
                      CupertinoDialogAction(
                        child: Text("Guardar"),
                        onPressed: () async {
                          if (textController.text.isNotEmpty) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                              'saved_city',
                              textController.text,
                            );
                            if (mounted) {
                              setState(() {
                                _city = textController.text;
                                _isWeatherLoading = true;
                              });
                              _loadWeather();
                            }
                          }
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.edit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRList() {
    return Column(
      children: _recentPRs.map((pr) {
        return Card(
          margin: EdgeInsets.only(top: 8),
          child: ListTile(
            leading: Icon(Icons.emoji_events, color: Colors.amber),
            title: Text(
              pr['ejercicioNombre'] ?? 'Ejercicio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "${pr['pesoMaximo']} kg",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            subtitle: Text("${pr['repeticiones']} reps"),
          ),
        );
      }).toList(),
    );
  }
}
