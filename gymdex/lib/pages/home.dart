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
  double _weeklyVolume = 0;
  int _estimatedCalories = 0;
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

    final routine = await service.getRoutineByDay(today);
    final history = await service.getTrainingHistory();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weeklyHistory = history.where((h) {
      final date = DateTime.tryParse(h['fecha']);
      return date != null &&
          date.isAfter(startOfWeek.subtract(Duration(seconds: 1)));
    }).toList();

    final weeklyCount = weeklyHistory.length;
    final weeklyVolume = weeklyHistory.fold(0.0, (double sum, item) {
      return sum + ((item['volumenTotal'] as num?)?.toDouble() ?? 0.0);
    });
    final calories = (weeklyVolume * 0.18).round();

    final prs = await service.getPersonalRecords();

    if (mounted) {
      setState(() {
        _todaysRoutine = routine;
        _workoutsThisWeek = weeklyCount;
        _weeklyVolume = weeklyVolume;
        _estimatedCalories = calories;
        _recentPRs = prs.take(3).toList();
        _isLoading = false;
      });
    }
  }

  // Iniciar entrenamiento
  void _startTraining() async {
    if (_todaysRoutine != null) {
      await Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
          builder: (context) => Traine(rutina: _todaysRoutine),
        ),
      );
      _loadDashboardData();
    } else {
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
    final data = await CloudService().getWeather(_city);
    debugPrint("Clima para $_city: $data");
    if (mounted) {
      setState(() {
        weatherData = data ?? {};
        _isWeatherLoading = false;
      });
    }
  }

  IconData _getWeatherIcon(int? code) {
    if (code == null) return Icons.help_outline;
    if (code == 0) return Icons.wb_sunny; // Despejado
    if (code >= 1 && code <= 3) return Icons.wb_cloudy; // Nublado parcial
    if (code >= 45 && code <= 48) return Icons.cloud; // Niebla
    if (code >= 51 && code <= 67) return Icons.grain; // Lluvia/Llovizna
    if (code >= 71 && code <= 77) return Icons.ac_unit; // Nieve
    if (code >= 80 && code <= 82) return Icons.beach_access; // Chubascos
    if (code >= 95) return Icons.flash_on; // Tormenta
    return Icons.cloud;
  }

  Color _getWeatherColor(int? code) {
    if (code == null) return Colors.grey;
    if (code == 0) return Colors.orange;
    if (code >= 1 && code <= 3) return Colors.orangeAccent;
    if (code >= 45 && code <= 48) return Colors.blueGrey;
    if (code >= 51 && code <= 67) return Colors.blue;
    if (code >= 71 && code <= 77) return Colors.lightBlue;
    if (code >= 80 && code <= 82) return Colors.blueAccent;
    if (code >= 95) return Colors.deepPurple;
    return Colors.blueAccent;
  }

  String _translateWeather(int? code) {
    if (code == null) return "desconocido";
    if (code == 0) return "despejado";
    if (code >= 1 && code <= 3) return "nublado";
    if (code >= 45 && code <= 48) return "con niebla";
    if (code >= 51 && code <= 55) return "con llovizna";
    if (code >= 61 && code <= 67) return "lluvioso";
    if (code >= 71 && code <= 77) return "nevado";
    if (code >= 80 && code <= 82) return "con chubascos";
    if (code >= 95) return "con tormenta";
    return "nublado";
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Dashboard")),
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Material(
          color: Colors.transparent,
          child: ListView(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              if (_isLoading) _buildSkeletonDashboard() else _buildKpiRow(),
              const SizedBox(height: 16),
              if (_isLoading) _buildSkeletonDashboard() else _buildTodayCard(),
              const SizedBox(height: 20),
              if (!_isLoading && _recentPRs.isNotEmpty) ...[
                _buildSectionTitle("Tus mejores marcas"),
                _buildPRList(),
              ],
              if (!_isLoading) ...[
                const SizedBox(height: 20),
                _buildSectionTitle("Resumen semanal"),
                _buildWeeklySummaryCard(),
              ],
              if (!_isLoading &&
                  !_isWeatherLoading &&
                  weatherData.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSectionTitle("Clima para hoy"),
                _buildWeatherCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3B70), Color(0xFF17294F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hola, Guerrero",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Listo para tu sesión? Tu próxima rutina está lista.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricTile(
                "Clima hoy",
                _isWeatherLoading
                    ? "Cargando..."
                    : "${weatherData['current']?['temperature_2m'] ?? '--'}°C",
                Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            Icons.fitness_center,
            "Entrenamientos",
            "$_workoutsThisWeek",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            Icons.bar_chart,
            "Volumen",
            "${_weeklyVolume.round()} kg",
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(IconData icon, String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.indigoAccent, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonDashboard() {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Listo para sudar?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _todaysRoutine != null
                  ? "Hoy toca: ${_todaysRoutine!.nombre}"
                  : "Hoy es día de descanso o sin asignar.",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: _startTraining,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text("Comenzar Entreno"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: const Icon(Icons.show_chart, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Carga Total",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_weeklyVolume.round()} kg",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Calorías",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$_estimatedCalories kcal",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _workoutsThisWeek > 0
                  ? (_workoutsThisWeek / 5).clamp(0.0, 1.0)
                  : 0,
              minHeight: 8,
              color: Colors.lightBlueAccent,
              backgroundColor: Colors.blueGrey.shade50,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _workoutsThisWeek >= 5
                    ? 'Meta semanal alcanzada'
                    : '$_workoutsThisWeek / 5 entrenos',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonWeather() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.withOpacity(0.3),
              radius: 20,
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (weatherData.isEmpty) return const SizedBox.shrink();

    final int? code = weatherData['current']?['weather_code'];
    final icon = _getWeatherIcon(code);
    final color = _getWeatherColor(code);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'hoy será un día ${_translateWeather(code)}',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temperatura: ${weatherData['current']?['temperature_2m']}°C',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.grey.shade200,
              child: const Icon(Icons.edit, color: Colors.black54),
              onPressed: () {
                final textController = TextEditingController(text: _city);
                showCupertinoDialog(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text("Configuración de clima"),
                    content: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud, color: Colors.blue),
                          const SizedBox(width: 10),
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
                        child: const Text("Cancelar"),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      CupertinoDialogAction(
                        child: const Text("Guardar"),
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
          margin: const EdgeInsets.only(top: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 1,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events, color: Colors.amber),
            ),
            title: Text(
              pr['ejercicioNombre'] ?? 'Ejercicio',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${pr['repeticiones']} reps"),
            trailing: Text(
              "${pr['pesoMaximo']} kg",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
