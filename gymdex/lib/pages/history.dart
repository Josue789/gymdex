import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymdex/service/ejercicioService.dart';
import 'package:intl/intl.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await Ejercicioservice().getTrainingHistory();
    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Historial y Progreso"),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : CustomScrollView(
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _loadData),
                  if (_history.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "No hay entrenamientos registrados",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    if (_history.length >= 2)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                "Volumen Total (kg)",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(height: 180, child: _buildChart()),
                            ],
                          ),
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = _history[index];
                        final volumen = item['volumenTotal'];
                        final fechaRaw = DateTime.parse(item['fecha']);
                        final fecha = DateFormat(
                          'dd MMM yyyy - HH:mm',
                        ).format(fechaRaw);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: ListTile(
                            title: Text(
                              item['rutinaNombre'] ?? 'Entrenamiento libre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(fecha),
                            trailing: Text(
                              "${(volumen as num?)?.toStringAsFixed(1) ?? '0'} kg",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }, childCount: _history.length),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildChart() {
    // Invertimos la lista para que la gráfica vaya de izquierda (antiguo) a derecha (nuevo)
    final dataAscending = _history.reversed.toList();

    final spots = List.generate(dataAscending.length, (index) {
      final vol =
          (dataAscending[index]['volumenTotal'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(index.toDouble(), vol);
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          show: false,
        ), // Ocultamos ejes para diseño limpio
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.indigoAccent,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.indigoAccent.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
