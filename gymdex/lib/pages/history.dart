import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymdex/service/ejercicioService.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  int _selectedSegment = 0;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _prs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final history = await Ejercicioservice().getTrainingHistory();
    final prs = await Ejercicioservice().getPersonalRecords();
    setState(() {
      _history = history;
      _prs = prs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar.large(
        leading: CircleAvatar(child: Icon(Icons.person)),
        largeTitle: const Text("Progreso"),
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedSegment,
                    children: const {
                      0: Text("Historial"),
                      1: Text("Récords (PR)"),
                    },
                    onValueChanged: (value) {
                      setState(() {
                        _selectedSegment = value!;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: _selectedSegment == 0
                    ? _buildHistoryList()
                    : _buildPrList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return const Center(child: Text("No hay entrenamientos registrados"));
    }
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final date = DateTime.parse(item['fecha']);
        final formattedDate = "${date.day}/${date.month}/${date.year}";
        final volumen = item['volumenTotal'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.history, color: Colors.blueGrey),
            title: Text(item['rutinaNombre'] ?? "Entrenamiento libre"),
            subtitle: Text(formattedDate),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Volumen Total", style: TextStyle(fontSize: 10)),
                Text(
                  "${(volumen as num).toStringAsFixed(1)} kg",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrList() {
    if (_prs.isEmpty) {
      return Center(
        child: Text(
          "Aún no tienes récords personales",
          style: TextStyle(fontSize: 20),
        ),
      );
    }
    return ListView.builder(
      itemCount: _prs.length,
      itemBuilder: (context, index) {
        final item = _prs[index];
        final date = DateTime.parse(item['fecha']);
        final formattedDate = "${date.day}/${date.month}/${date.year}";

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.amber),
            title: Text(item['ejercicioNombre']),
            subtitle: Text("Logrado el: $formattedDate"),
            trailing: Text(
              "${item['pesoMaximo']} kg\n(x${item['repeticiones']})",
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
