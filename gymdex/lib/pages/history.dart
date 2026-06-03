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
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;
  String _selectedGroup = 'Todos';
  final List<String> _groups = [
    'Todos',
    'Pecho',
    'Espalda',
    'Piernas',
    'Hombros',
    'Brazos',
    'Core',
  ];
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = Ejercicioservice();
    final records = await service.getPersonalRecords();
    final history = await service.getTrainingHistory();

    if (mounted) {
      setState(() {
        _records = records;
        _history = history;
        _isLoading = false;
      });
      _filterRecords();
    }
  }

  void _filterRecords() {
    if (_selectedGroup == 'Todos') {
      _filteredRecords = List.from(_records);
    } else {
      _filteredRecords = _records.where((record) {
        final group = (record['grupoNombre'] as String?)?.toLowerCase() ?? '';
        return group.contains(_selectedGroup.toLowerCase());
      }).toList();
    }
  }

  void _onGroupSelected(String group) {
    setState(() {
      _selectedGroup = group;
      _filterRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Récords Personales"),
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : CustomScrollView(
                  slivers: [
                    CupertinoSliverRefreshControl(onRefresh: _loadData),
                    SliverToBoxAdapter(child: _buildSummarySection()),
                    SliverToBoxAdapter(child: _buildFilterSection()),
                    if (_filteredRecords.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            "No hay récords personales para esta categoría",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildRecordCard(_filteredRecords[index]);
                        }, childCount: _filteredRecords.length),
                      ),
                    if (_history.length >= 2)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 20,
                          ),
                          child: _buildChartCard(),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final totalRecs = _records.length;
    final totalWorkouts = _history.length;
    final bestWeight = _records.fold<double>(0.0, (previousValue, record) {
      final weight = (record['pesoMaximo'] as num?)?.toDouble() ?? 0.0;
      return weight > previousValue ? weight : previousValue;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Revisa tus mejores marcas",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryTile('Récords', '$totalRecs')),
              const SizedBox(width: 10),
              Expanded(child: _buildSummaryTile('Entrenos', '$totalWorkouts')),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryTile('Max Kg', '${bestWeight.round()}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _groups.map((group) {
          final selected = group == _selectedGroup;
          return ChoiceChip(
            label: Text(group),
            selected: selected,
            onSelected: (_) => _onGroupSelected(group),
            selectedColor: Colors.indigoAccent,
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final fechaRaw = DateTime.tryParse(record['fecha'] ?? '');
    final fecha = fechaRaw != null
        ? DateFormat('dd MMM yyyy').format(fechaRaw)
        : 'Sin fecha';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 1,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigoAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events, color: Colors.indigoAccent),
          ),
          title: Text(
            record['ejercicioNombre'] ?? 'Ejercicio',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('$fecha • ${record['grupoNombre'] ?? 'Sin grupo'}'),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record['pesoMaximo']} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${record['repeticiones']} reps',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final points = List.generate(_history.length, (index) {
      final entry = _history.reversed.toList()[index];
      return FlSpot(
        index.toDouble(),
        (entry['volumenTotal'] as num?)?.toDouble() ?? 0.0,
      );
    });

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Volumen total (kg)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: Colors.indigoAccent,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.indigoAccent.withOpacity(0.18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
