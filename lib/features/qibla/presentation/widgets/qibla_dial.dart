import 'dart:math' as math;

import 'package:flutter/material.dart';

/// قرص البوصلة: الوردية تدور عكس اتجاه الجهاز، والقبلة تبقى في موضعها
/// الحقيقي، فيظهر سهم القبلة في الاتجاه الذي يجب أن يوجه إليه المستخدم جهازه.
class QiblaDial extends StatelessWidget {
  const QiblaDial({
    super.key,
    required this.headingDegrees,
    required this.qiblaDegrees,
    this.size = 260,
  });

  /// اتجاه أعلى الجهاز (0 = شمال). `null` يعني لا توجد بوصلة.
  final double? headingDegrees;

  /// اتجاه القبلة من موقع المستخدم.
  final double qiblaDegrees;

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final heading = headingDegrees ?? 0;

    return Semantics(
      label: 'بوصلة القبلة',
      value: 'اتجاه القبلة ${qiblaDegrees.round()} درجة',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _QiblaDialPainter(
            headingDegrees: heading,
            qiblaDegrees: qiblaDegrees,
            surface: colors.surface,
            outline: colors.outlineVariant,
            tick: colors.onSurfaceVariant,
            north: colors.error,
            qibla: colors.primary,
            device: colors.secondary,
          ),
        ),
      ),
    );
  }
}

class _QiblaDialPainter extends CustomPainter {
  _QiblaDialPainter({
    required this.headingDegrees,
    required this.qiblaDegrees,
    required this.surface,
    required this.outline,
    required this.tick,
    required this.north,
    required this.qibla,
    required this.device,
  });

  final double headingDegrees;
  final double qiblaDegrees;
  final Color surface;
  final Color outline;
  final Color tick;
  final Color north;
  final Color qibla;
  final Color device;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 12;

    canvas.drawCircle(center, radius, Paint()..color = surface);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawTicks(canvas, center, radius);
    _drawCardinals(canvas, center, radius);
    _drawNeedle(
      canvas,
      center,
      radius * 0.52,
      (360 - headingDegrees),
      north,
      strokeWidth: 3,
    );
    _drawNeedle(
      canvas,
      center,
      radius * 0.8,
      (qiblaDegrees - headingDegrees),
      qibla,
      strokeWidth: 6,
    );
    _drawDeviceMarker(canvas, center, radius);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..color = tick.withValues(alpha: 0.55);
    for (var index = 0; index < 24; index++) {
      final bearing = index * 15.0;
      final isCardinal = index % 6 == 0;
      final angle = _radians(bearing - headingDegrees);
      final inner = radius * (isCardinal ? 0.86 : 0.91);
      final outer = radius * 0.96;
      paint.strokeWidth = isCardinal ? 2.5 : 1.2;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        paint,
      );
    }
  }

  void _drawCardinals(Canvas canvas, Offset center, double radius) {
    final labels = {
      0.0: 'ش',
      90.0: 'ق',
      180.0: 'ج',
      270.0: 'غ',
    };

    labels.forEach((bearing, label) {
      final angle = _radians(bearing - headingDegrees);
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.72);
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: tick,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();

      painter.paint(
        canvas,
        position - Offset(painter.width / 2, painter.height / 2),
      );
    });
  }

  /// يرسم سهماً من المركز باتجاه زاوية البوصلة المطلوبة (0 = أعلى الشاشة).
  void _drawNeedle(
    Canvas canvas,
    Offset center,
    double length,
    double bearing,
    Color color, {
    required double strokeWidth,
  }) {
    final angle = _radians(bearing);
    final tip = center + Offset(math.cos(angle), math.sin(angle)) * length;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, tip, paint);

    // رأس السهم.
    final headAngle = 14 * math.pi / 180;
    final headLength = math.max(10.0, length * 0.18);
    final left = tip -
        Offset(
          math.cos(angle - headAngle),
          math.sin(angle - headAngle),
        ) *
            headLength;
    final right = tip -
        Offset(
          math.cos(angle + headAngle),
          math.sin(angle + headAngle),
        ) *
            headLength;

    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  /// مثلث ثابت في أعلى القرص يمثّل اتجاه نظر المستخدم.
  void _drawDeviceMarker(Canvas canvas, Offset center, double radius) {
    final tip = center + Offset(0, -radius - 2);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 7, tip.dy - 10)
      ..lineTo(tip.dx + 7, tip.dy - 10)
      ..close();
    canvas.drawPath(path, Paint()..color = device);
  }

  double _radians(double compassDegrees) =>
      (compassDegrees - 90) * math.pi / 180;

  @override
  bool shouldRepaint(_QiblaDialPainter oldDelegate) {
    return oldDelegate.headingDegrees != headingDegrees ||
        oldDelegate.qiblaDegrees != qiblaDegrees ||
        oldDelegate.surface != surface ||
        oldDelegate.north != north;
  }
}
