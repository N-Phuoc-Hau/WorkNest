import 'package:flutter/material.dart';

enum ChartType { line, bar, pie, doughnut }

class ChartWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final ChartType chartType;

  const ChartWidget({
    super.key,
    required this.title,
    required this.data,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    switch (chartType) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.pie:
        return _buildPieChart();
      case ChartType.doughnut:
        return _buildDoughnutChart();
    }
  }

  Widget _buildLineChart() {
    if (data.isEmpty) return _buildEmptyChart();
    
    return CustomPaint(
      painter: LineChartPainter(data),
      child: Container(),
    );
  }

  Widget _buildBarChart() {
    if (data.isEmpty) return _buildEmptyChart();
    
    return CustomPaint(
      painter: BarChartPainter(data),
      child: Container(),
    );
  }

  Widget _buildPieChart() {
    if (data.isEmpty) return _buildEmptyChart();
    
    return CustomPaint(
      painter: PieChartPainter(data),
      child: Container(),
    );
  }

  Widget _buildDoughnutChart() {
    if (data.isEmpty) return _buildEmptyChart();
    
    return CustomPaint(
      painter: DoughnutChartPainter(data),
      child: Container(),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Không có dữ liệu',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painters for different chart types
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = data.map((d) => d['value'] as double).reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i]['value'] as double) / maxValue) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((d) => d['value'] as double).reduce((a, b) => a > b ? a : b);
    final barWidth = size.width / data.length * 0.8;
    final spacing = size.width / data.length * 0.2;

    for (int i = 0; i < data.length; i++) {
      final x = i * (barWidth + spacing);
      final height = ((data[i]['value'] as double) / maxValue) * size.height;
      final y = size.height - height;

      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(x, y, barWidth, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 * 0.8 : size.height / 2 * 0.8;
    
    final total = data.map((d) => d['value'] as double).reduce((a, b) => a + b);
    double startAngle = 0;

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i]['value'] as double) / total * 2 * 3.14159;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DoughnutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  DoughnutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width < size.height ? size.width / 2 * 0.8 : size.height / 2 * 0.8;
    final innerRadius = outerRadius * 0.6;
    
    final total = data.map((d) => d['value'] as double).reduce((a, b) => a + b);
    double startAngle = 0;

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i]['value'] as double) / total * 2 * 3.14159;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle,
          sweepAngle,
        )
        ..addArc(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle + sweepAngle,
          -sweepAngle,
        )
        ..close();

      canvas.drawPath(path, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 