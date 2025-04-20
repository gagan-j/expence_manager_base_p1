import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/chart_data.dart';

class ExpensePieChart extends StatelessWidget {
  final List<ChartData> chartData;
  final bool showWeekly;
  final VoidCallback onToggle;

  const ExpensePieChart({
    super.key,
    required this.chartData,
    required this.showWeekly,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    double total = chartData.fold<double>(0, (sum, item) => sum + item.amount);
    double income = total * 0.3; // Dummy static income for now
    double expenses = total;
    double net = income - expenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle arrows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: onToggle,
              ),
              Text(
                showWeekly ? 'Weekly Expenses' : 'Monthly Expenses',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onPressed: onToggle,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryBox("Income", income, Colors.green),
              _buildSummaryBox("Expense", expenses, Colors.red),
              _buildSummaryBox("Total", net, net >= 0 ? Colors.green : Colors.red),
            ],
          ),
        ),
        // Pie Chart
        SizedBox(
          height: 300,
          child: SfCircularChart(
            backgroundColor: Colors.black,
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
                dataLabelSettings: const DataLabelSettings(
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




        // Income / Expenses / Total Row
      ],
    );
  }

  Widget _buildSummaryBox(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
