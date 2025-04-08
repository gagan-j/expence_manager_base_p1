import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/chart_data.dart';

class ExpensePieChart extends StatelessWidget {
  final List<ChartData> chartData;

  const ExpensePieChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    double total = chartData.fold<double>(0, (sum, item) => sum + item.amount);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        height: 400,
        child: SfCircularChart(
          backgroundColor: Colors.black,
          title: ChartTitle(
            text: 'Monthly Expenses',
            textStyle: TextStyle(color: Colors.white),
          ),
          series: <CircularSeries>[
            DoughnutSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.category,
              yValueMapper: (ChartData data, _) => data.amount,
              explode: true,
              explodeAll: true,
              explodeOffset: '5%',
              radius: '60%',
              innerRadius: '50%',
              dataLabelMapper: (ChartData data, _) {
                final percent = ((data.amount / total) * 100).toStringAsFixed(1);
                return '${data.category}:\n$percent%';
              },
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelPosition: ChartDataLabelPosition.outside,
                connectorLineSettings: ConnectorLineSettings(
                  type: ConnectorType.curve,
                  length: '15%',
                ),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
