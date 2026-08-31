import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Unified OceanEmbed Logo matching the Problem Statement:
/// Satellite observation beams + Ocean depth gradient + Deep Learning latent embedding
class OceanEmbedLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const OceanEmbedLogo({
    super.key,
    this.size = 40,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4C81), // Deep Ocean Blue
            Color(0xFF147BEF), // Primary Satellite Blue
            Color(0xFF00C6FF), // Cyan Surface Radiance
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: showGlow
                ? const Color(0xFF147BEF).withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: showGlow ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: CustomPaint(
          size: Size(size, size),
          painter: _OceanEmbedLogoPainter(),
        ),
      ),
    );
  }
}

class _OceanEmbedLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subsurface ocean waves (Depth layering)
    final wavePaint1 = Paint()
      ..color = const Color(0xFF0A2E5C).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, h * 0.65);
    path1.cubicTo(w * 0.25, h * 0.58, w * 0.75, h * 0.72, w, h * 0.62);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, wavePaint1);

    final wavePaint2 = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055;

    final path2 = Path();
    path2.moveTo(0, h * 0.52);
    path2.cubicTo(w * 0.3, h * 0.44, w * 0.7, h * 0.58, w, h * 0.48);
    canvas.drawPath(path2, wavePaint2);

    // 2. Satellite orbital arc at top
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.4),
      width: w * 0.68,
      height: h * 0.55,
    );
    canvas.drawArc(arcRect, -math.pi * 0.85, math.pi * 0.9, false, arcPaint);

    // 3. Satellite body & solar panels
    final satPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Satellite main body (diamond/rect)
    final satCenter = Offset(w * 0.74, h * 0.24);
    canvas.drawCircle(satCenter, w * 0.09, satPaint);

    final satCorePaint = Paint()..color = const Color(0xFFFF9B22);
    canvas.drawCircle(satCenter, w * 0.045, satCorePaint);

    // 4. Deep Learning Latent Embedding constellation nodes
    final nodePaint = Paint()..color = Colors.white;
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    final n1 = Offset(w * 0.25, h * 0.32);
    final n2 = Offset(w * 0.45, h * 0.22);
    final n3 = Offset(w * 0.35, h * 0.48);

    canvas.drawLine(n1, n2, linePaint);
    canvas.drawLine(n1, n3, linePaint);
    canvas.drawLine(n2, satCenter, linePaint);

    canvas.drawCircle(n1, w * 0.04, nodePaint);
    canvas.drawCircle(n2, w * 0.035, nodePaint);
    canvas.drawCircle(n3, w * 0.035, nodePaint);

    // 5. Thermal subsurface emission dot (Problem Statement target)
    final thermalPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(Offset(w * 0.55, h * 0.80), w * 0.05, thermalPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Unified Header component used consistently across all app screens
class OceanEmbedAppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool showBackButton;
  final VoidCallback? onBack;

  const OceanEmbedAppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF132238)),
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
        ],
        const OceanEmbedLogo(size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132238),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
