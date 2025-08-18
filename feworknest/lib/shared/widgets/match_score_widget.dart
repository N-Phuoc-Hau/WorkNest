import 'dart:math' as math;

import 'package:flutter/material.dart';

class MatchScoreWidget extends StatefulWidget {
  final double score;
  final double size;
  final Color? color;
  final bool showLabel;
  final String? label;
  final Duration animationDuration;

  const MatchScoreWidget({
    super.key,
    required this.score,
    this.size = 100,
    this.color,
    this.showLabel = true,
    this.label,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<MatchScoreWidget> createState() => _MatchScoreWidgetState();
}

class _MatchScoreWidgetState extends State<MatchScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MatchScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score / 100,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ));
      _animationController.reset();
      _animationController.forward();
    }
  }

  Color get scoreColor {
    if (widget.color != null) return widget.color!;
    
    if (widget.score >= 80) return Colors.green;
    if (widget.score >= 60) return Colors.orange;
    if (widget.score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  String get scoreLabel {
    if (widget.label != null) return widget.label!;
    
    if (widget.score >= 80) return 'Xuất sắc';
    if (widget.score >= 60) return 'Tốt';
    if (widget.score >= 40) return 'Trung bình';
    return 'Cần cải thiện';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: CircularProgressPainter(
                  progress: _animation.value,
                  color: scoreColor,
                  backgroundColor: Colors.grey[200]!,
                  strokeWidth: widget.size * 0.08,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Text(
                            '${(_animation.value * 100).round()}%',
                            style: TextStyle(
                              fontSize: widget.size * 0.18,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          );
                        },
                      ),
                      if (widget.showLabel && widget.size > 80) ...[
                        const SizedBox(height: 2),
                        Text(
                          scoreLabel,
                          style: TextStyle(
                            fontSize: widget.size * 0.08,
                            color: scoreColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        if (widget.showLabel && widget.size <= 80) ...[
          const SizedBox(height: 8),
          Text(
            scoreLabel,
            style: TextStyle(
              fontSize: 12,
              color: scoreColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final startAngle = -math.pi / 2; // Start from top
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}

// Linear progress bar variant
class LinearMatchScoreWidget extends StatefulWidget {
  final double score;
  final double height;
  final Color? color;
  final bool showLabel;
  final bool showPercentage;
  final Duration animationDuration;

  const LinearMatchScoreWidget({
    super.key,
    required this.score,
    this.height = 8,
    this.color,
    this.showLabel = false,
    this.showPercentage = true,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<LinearMatchScoreWidget> createState() => _LinearMatchScoreWidgetState();
}

class _LinearMatchScoreWidgetState extends State<LinearMatchScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get scoreColor {
    if (widget.color != null) return widget.color!;
    
    if (widget.score >= 80) return Colors.green;
    if (widget.score >= 60) return Colors.orange;
    if (widget.score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  String get scoreLabel {
    if (widget.score >= 80) return 'Xuất sắc';
    if (widget.score >= 60) return 'Tốt';
    if (widget.score >= 40) return 'Trung bình';
    return 'Cần cải thiện';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel || widget.showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.showLabel)
                Text(
                  scoreLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scoreColor,
                  ),
                ),
              if (widget.showPercentage)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Text(
                      '${(_animation.value * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: scoreColor,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Mini score indicator for list items
class MiniMatchScoreWidget extends StatelessWidget {
  final double score;
  final double size;

  const MiniMatchScoreWidget({
    super.key,
    required this.score,
    this.size = 24,
  });

  Color get scoreColor {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scoreColor.withOpacity(0.1),
        border: Border.all(color: scoreColor, width: 2),
      ),
      child: Center(
        child: Text(
          '${score.round()}',
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: scoreColor,
          ),
        ),
      ),
    );
  }
}
