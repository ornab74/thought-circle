import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/thought.dart';

class ThoughtOrbit extends StatefulWidget {
  const ThoughtOrbit({
    super.key,
    required this.thoughts,
    required this.onThoughtTap,
  });

  final List<Thought> thoughts;
  final ValueChanged<Thought> onThoughtTap;

  @override
  State<ThoughtOrbit> createState() => _ThoughtOrbitState();
}

class _ThoughtOrbitState extends State<ThoughtOrbit> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final visible = widget.thoughts;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width < 430 ? 430.0 : 470.0;
        final cardWidth = (width * 0.31).clamp(112.0, 142.0);
        const cardHeight = 88.0;
        final anchors = _anchors(visible.length);
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(child: CustomPaint(painter: _OrbitPainter())),
              Align(
                alignment: const Alignment(0, 0.06),
                child: _OrbitCenter(count: visible.length),
              ),
              for (var index = 0; index < visible.length; index++)
                Positioned(
                  left: (anchors[index].dx * (width - cardWidth)).clamp(
                    0.0,
                    width - cardWidth,
                  ),
                  top: anchors[index].dy * (height - cardHeight),
                  width: cardWidth,
                  height: cardHeight,
                  child: _ThoughtOrbitCard(
                    thought: visible[index],
                    expanded: _expandedId == visible[index].id,
                    onTap: () {
                      setState(() {
                        _expandedId = _expandedId == visible[index].id
                            ? null
                            : visible[index].id;
                      });
                    },
                    onOpen: () => widget.onThoughtTap(visible[index]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Offset> _anchors(int count) => [
    for (var index = 0; index < count; index++)
      Offset(
        0.5 + math.cos(-math.pi / 2 + index * math.pi * 2 / count) * 0.43,
        0.5 + math.sin(-math.pi / 2 + index * math.pi * 2 / count) * 0.40,
      ),
  ];
}

class _OrbitCenter extends StatelessWidget {
  const _OrbitCenter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 132,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ThoughtCircleColors.line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1C705AF8),
            blurRadius: 38,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '$count',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 48, height: 1),
          ),
          const SizedBox(height: 5),
          Text(
            count == 1 ? 'active loop' : 'active loops',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: ThoughtCircleColors.ink),
          ),
        ],
      ),
    );
  }
}

class _ThoughtOrbitCard extends StatelessWidget {
  const _ThoughtOrbitCard({
    required this.thought,
    required this.expanded,
    required this.onTap,
    required this.onOpen,
  });

  final Thought thought;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(11, 10, 10, 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: thought.color.withValues(alpha: 0.3)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x17271955),
                blurRadius: 22,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: thought.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(thought.icon, size: 15, color: thought.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      thought.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ThoughtCircleColors.ink,
                        height: 1.16,
                        fontSize: 12,
                      ),
                    ),
                    if (expanded && thought.detail.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        thought.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 9.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (expanded)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Open thought',
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.53);
    final radius = math.min(size.width * 0.31, size.height * 0.27);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..shader = const SweepGradient(
        colors: <Color>[
          Color(0x44FF9B52),
          Color(0x44F060B6),
          Color(0x447355FF),
          Color(0x44FF9B52),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, glow);

    for (var index = 0; index < 3; index++) {
      final ringRect = Rect.fromCircle(
        center: center,
        radius: radius - 8 + index * 8,
      );
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = index == 1 ? 5.2 : 1.2
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: <Color>[
            ThoughtCircleColors.orange,
            ThoughtCircleColors.pink,
            ThoughtCircleColors.purple,
            ThoughtCircleColors.orange,
          ],
        ).createShader(ringRect);
      canvas.drawCircle(center, radius - 8 + index * 8, ring);
    }

    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ThoughtCircleColors.purple.withValues(alpha: 0.1);
    canvas.drawCircle(center, radius + 22, faint);
    canvas.drawCircle(center, radius - 25, faint);

    for (final angle in <double>[-1.55, -0.25, 0.88, 2.18, 3.18]) {
      final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        dot,
        8,
        Paint()
          ..color = ThoughtCircleColors.orange.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(dot, 4.2, Paint()..color = const Color(0xFFFFC26D));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
