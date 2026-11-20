import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/previsao.dart';

/// Gráfico de linhas com as temperaturas máxima e mínima dos dias previstos.
/// Dias sem o valor correspondente são omitidos da linha, sem quebrar o gráfico.
class GraficoTemperaturas extends StatelessWidget {
  final List<PrevisaoDia> dias;

  const GraficoTemperaturas({super.key, required this.dias});

  static const Color _corMaxima = Colors.deepOrange;
  static const Color _corMinima = Colors.blue;

  List<FlSpot> _pontos(double? Function(PrevisaoDia dia) valor) {
    final pontos = <FlSpot>[];
    for (var i = 0; i < dias.length; i++) {
      final v = valor(dias[i]);
      if (v != null) pontos.add(FlSpot(i.toDouble(), v));
    }
    return pontos;
  }

  String _rotuloDoDia(int indice) {
    if (indice < 0 || indice >= dias.length) return '';
    final data = dias[indice].data;
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes';
  }

  LineChartBarData _linha(List<FlSpot> pontos, Color cor) {
    return LineChartBarData(
      spots: pontos,
      isCurved: true,
      color: cor,
      barWidth: 3,
      dotData: const FlDotData(show: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maximas = _pontos((dia) => dia.maxima);
    final minimas = _pontos((dia) => dia.minima);
    final todos = [...maximas, ...minimas];

    if (todos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Temperaturas indisponíveis para o gráfico.'),
      );
    }

    final menor = todos.map((p) => p.y).reduce(math.min);
    final maior = todos.map((p) => p.y).reduce(math.max);
    final minY = (menor - 2).floorToDouble();
    final maxY = (maior + 2).ceilToDouble();
    final intervalo = math.max(1.0, ((maxY - minY) / 4).ceilToDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temperaturas (°C)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.circle, size: 12, color: _corMaxima),
            SizedBox(width: 4),
            Text('Máxima'),
            SizedBox(width: 16),
            Icon(Icons.circle, size: 12, color: _corMinima),
            SizedBox(width: 4),
            Text('Mínima'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: math.max(1, dias.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: intervalo,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: intervalo,
                    getTitlesWidget: (valor, meta) =>
                        Text('${valor.toInt()}°'),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (valor, meta) {
                      // Evita rótulos em posições fracionárias.
                      if (valor != valor.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _rotuloDoDia(valor.toInt()),
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                if (maximas.isNotEmpty) _linha(maximas, _corMaxima),
                if (minimas.isNotEmpty) _linha(minimas, _corMinima),
              ],
            ),
          ),
        ),
      ],
    );
  }
}