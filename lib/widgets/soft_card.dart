import 'package:flutter/material.dart';

import '../app/theme.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.onTap,
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: ThoughtCircleColors.line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x102D2359),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

class GradientAction extends StatelessWidget {
  const GradientAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: <Color>[
                Color(0xFF6E56F7),
                Color(0xFFE85CB7),
                Color(0xFFFF9A50),
              ],
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33715AF8),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class PageGlow extends StatelessWidget {
  const PageGlow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: ThoughtCircleColors.background),
        Positioned(
          top: -130,
          right: -90,
          child: _GlowOrb(
            size: 300,
            color: ThoughtCircleColors.purple,
            opacity: 0.075,
          ),
        ),
        Positioned(
          top: 260,
          left: -130,
          child: _GlowOrb(
            size: 280,
            color: ThoughtCircleColors.orange,
            opacity: 0.06,
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: ThoughtCircleColors.muted,
              letterSpacing: 1.25,
              fontSize: 11,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class ThoughtCircleMark extends StatelessWidget {
  const ThoughtCircleMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.09;
    final gradient = const SweepGradient(
      colors: <Color>[
        ThoughtCircleColors.orange,
        ThoughtCircleColors.pink,
        ThoughtCircleColors.purple,
        ThoughtCircleColors.orange,
      ],
    ).createShader(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient;
    canvas.drawOval(rect.deflate(stroke), paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.49, size.height * 0.52),
        width: size.width * 0.67,
        height: size.height * 0.78,
      ),
      paint..strokeWidth = stroke * 0.72,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
