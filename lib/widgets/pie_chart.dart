import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/chart_data.dart';

class ExpensePieChart extends StatelessWidget {
  final List<ChartData> chartData;
  final bool showWeekly;
  final VoidCallback onToggle;

  const ExpensePieChart({
    Key? key,
    required this.chartData,
    required this.showWeekly,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate total expenses
    final total = chartData.fold(0.0, (sum, item) => sum + item.amount);

    // Define colors for the chart sections
    final List<Color> sectionColors = [
      Colors.green[400]!,
      Colors.yellow[400]!,
      Colors.orange[400]!,
      Colors.pink[300]!,
      Colors.blue[400]!,
      Colors.teal[400]!,
      Colors.red[400]!,
      Colors.purple[400]!,
      Colors.amber[400]!,
    ];

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: PieChartPainter(
              chartData: chartData,
              total: total,
              colors: sectionColors,
            ),
            child: const Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          children: _generateLegendItems(sectionColors, total),
        ),
      ],
    );
  }

  List<Widget> _generateLegendItems(List<Color> colors, double total) {
    return List.generate(
      chartData.length,
          (index) {
        final data = chartData[index];
        final color = colors[index % colors.length];
        final percentage = total > 0 ? (data.amount / total * 100) : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${data.category}: ${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom PieChart painter that doesn't rely on fl_chart
class PieChartPainter extends CustomPainter {
  final List<ChartData> chartData;
  final double total;
  final List<Color> colors;

  PieChartPainter({
    required this.chartData,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Start from the top (-pi/2)
    double startAngle = -math.pi / 2;

    for (int i = 0; i < chartData.length; i++) {
      final data = chartData[i];
      final color = colors[i % colors.length];

      // Calculate sweep angle based on value
      final sweepAngle = total > 0
          ? (data.amount / total) * 2 * math.pi
          : 0.0;

      // Create the paint for this section
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;

      // Draw the arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Calculate text position
      if (sweepAngle > 0.3) {  // Only add text if segment is large enough
        final middleAngle = startAngle + (sweepAngle / 2);
        final labelRadius = radius * 0.7;  // 70% out from center
        final x = center.dx + labelRadius * math.cos(middleAngle);
        final y = center.dy + labelRadius * math.sin(middleAngle);

        // Create text painter
        final percentage = (data.amount / total * 100).toStringAsFixed(0) + '%';
        final textPainter = TextPainter(
          text: TextSpan(
            text: percentage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Position text in middle of arc segment
        final textOffset = Offset(
          x - textPainter.width / 2,
          y - textPainter.height / 2,
        );

        // Draw text
        textPainter.paint(canvas, textOffset);
      }

      // Move to next starting angle
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) {
    return oldDelegate.chartData != chartData ||
        oldDelegate.total != total ||
        oldDelegate.colors != colors;
  }
}