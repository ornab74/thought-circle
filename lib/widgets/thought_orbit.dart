import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app/theme.dart';
import '../models/thought.dart';

/// Stage 1 of the orbital cognition interface.
///
/// This widget intentionally keeps the existing [Thought] model unchanged while
/// introducing the interaction foundation used by later stages:
///
/// * continuously animated orbital rings
/// * direct drag-to-spin interaction
/// * inertial rotation with damping
/// * thought moons positioned on independently moving rings
/// * glass-like central focus sphere
/// * reduced-motion and accessibility support
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

class _ThoughtOrbitState extends State<ThoughtOrbit>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final Ticker _inertiaTicker;

  String? _selectedId;
  double _manualRotation = 0;
  double _angularVelocity = 0;
  Duration? _lastInertiaTick;
  Offset? _lastDragPosition;
  double? _lastDragAngle;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _inertiaTicker = createTicker(_tickInertia);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _inertiaTicker.dispose();
    super.dispose();
  }

  void _tickInertia(Duration elapsed) {
    final previous = _lastInertiaTick;
    _lastInertiaTick = elapsed;
    if (previous == null) return;

    final dt = (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) return;

    setState(() {
      _manualRotation += _angularVelocity * dt;
      _angularVelocity *= math.pow(0.055, dt).toDouble();
    });

    if (_angularVelocity.abs() < 0.012) {
      _angularVelocity = 0;
      _lastInertiaTick = null;
      _inertiaTicker.stop();
    }
  }

  void _startDrag(DragStartDetails details, Offset center) {
    _inertiaTicker.stop();
    _angularVelocity = 0;
    _lastInertiaTick = null;
    _lastDragPosition = details.localPosition;
    _lastDragAngle = _angleFrom(center, details.localPosition);
  }

  void _updateDrag(DragUpdateDetails details, Offset center) {
    final previousAngle = _lastDragAngle;
    final currentAngle = _angleFrom(center, details.localPosition);
    if (previousAngle == null) return;

    final delta = _normalizedAngle(currentAngle - previousAngle);
    setState(() => _manualRotation += delta);

    final distance = (details.localPosition - center).distance.clamp(80.0, 260.0);
    final tangent = Offset(
      -math.sin(currentAngle),
      math.cos(currentAngle),
    );
    _angularVelocity = details.delta.dot(tangent) / distance * 60;
    _lastDragAngle = currentAngle;
    _lastDragPosition = details.localPosition;
  }

  void _endDrag(DragEndDetails details, bool reduceMotion) {
    _lastDragPosition = null;
    _lastDragAngle = null;
    if (reduceMotion || _angularVelocity.abs() < 0.025) {
      _angularVelocity = 0;
      return;
    }
    _lastInertiaTick = null;
    _inertiaTicker.start();
  }

  double _angleFrom(Offset center, Offset point) {
    final relative = point - center;
    return math.atan2(relative.dy, relative.dx);
  }

  double _normalizedAngle(double angle) {
    while (angle > math.pi) angle -= math.pi * 2;
    while (angle < -math.pi) angle += math.pi * 2;
    return angle;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations || media.accessibleNavigation;
    final visible = widget.thoughts.take(12).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width < 430 ? 440.0 : 500.0;
        final center = Offset(width / 2, height * 0.51);
        final baseRadius = math.min(width * 0.31, height * 0.27);

        return SizedBox(
          height: height,
          child: AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) {
              final ambientRotation = reduceMotion
                  ? 0.0
                  : _ambientController.value * math.pi * 2;
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) => _startDrag(details, center),
                onPanUpdate: (details) => _updateDrag(details, center),
                onPanEnd: (details) => _endDrag(details, reduceMotion),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _OrbitalFieldPainter(
                            rotation: ambientRotation + _manualRotation,
                            pulse: reduceMotion
                                ? 0.5
                                : (math.sin(
                                            _ambientController.value *
                                                math.pi *
                                                2,
                                          ) +
                                          1) /
                                      2,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.02),
                      child: _GlassCore(
                        count: visible.length,
                        selected: _selectedThought(visible),
                        onSelectedTap: () {
                          final selected = _selectedThought(visible);
                          if (selected != null) widget.onThoughtTap(selected);
                        },
                      ),
                    ),
                    for (var index = 0; index < visible.length; index++)
                      _buildMoon(
                        context: context,
                        thought: visible[index],
                        index: index,
                        total: visible.length,
                        center: center,
                        baseRadius: baseRadius,
                        ambientRotation: ambientRotation,
                        reduceMotion: reduceMotion,
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 2,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 240),
                          opacity: _lastDragPosition == null ? 0.72 : 1,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.swipe_rounded,
                                size: 16,
                                color: ThoughtCircleColors.muted,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Drag the orbit to explore',
                                style: TextStyle(
                                  color: ThoughtCircleColors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Thought? _selectedThought(List<Thought> thoughts) {
    final selectedId = _selectedId;
    if (selectedId == null) return null;
    for (final thought in thoughts) {
      if (thought.id == selectedId) return thought;
    }
    return null;
  }

  Widget _buildMoon({
    required BuildContext context,
    required Thought thought,
    required int index,
    required int total,
    required Offset center,
    required double baseRadius,
    required double ambientRotation,
    required bool reduceMotion,
  }) {
    final ringIndex = index % 3;
    final ringRadius = baseRadius + (ringIndex - 1) * 23;
    final direction = ringIndex == 1 ? -1.0 : 1.0;
    final ringSpeed = <double>[0.55, 0.34, 0.22][ringIndex];
    final angle = -math.pi / 2 +
        index * math.pi * 2 / math.max(total, 1) +
        _manualRotation +
        (reduceMotion ? 0 : ambientRotation * ringSpeed * direction);
    final radialScale = 0.94 + 0.06 * math.sin(index * 1.7 + ambientRotation);
    final point = center +
        Offset(math.cos(angle), math.sin(angle) * 0.82) *
            ringRadius *
            radialScale;
    final selected = _selectedId == thought.id;
    final moonSize = selected ? 68.0 : 54.0;

    return Positioned(
      left: point.dx - moonSize / 2,
      top: point.dy - moonSize / 2,
      width: moonSize,
      height: moonSize,
      child: Semantics(
        button: true,
        selected: selected,
        label: thought.title,
        hint: selected
            ? 'Tap again to open this thought'
            : 'Tap to focus this thought',
        child: _ThoughtMoon(
          thought: thought,
          selected: selected,
          onTap: () {
            if (selected) {
              widget.onThoughtTap(thought);
              return;
            }
            setState(() => _selectedId = thought.id);
          },
        ),
      ),
    );
  }
}

class _ThoughtMoon extends StatelessWidget {
  const _ThoughtMoon({
    required this.thought,
    required this.selected,
    required this.onTap,
  });

  final Thought thought;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.06 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.98),
                  thought.color.withValues(alpha: selected ? 0.46 : 0.27),
                  thought.color.withValues(alpha: selected ? 0.78 : 0.56),
                ],
                stops: const <double>[0, 0.58, 1],
              ),
              border: Border.all(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.78),
                width: selected ? 2.2 : 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: thought.color.withValues(alpha: selected ? 0.42 : 0.24),
                  blurRadius: selected ? 24 : 16,
                  spreadRadius: selected ? 3 : 0,
                ),
                const BoxShadow(
                  color: Color(0x1E1B153F),
                  blurRadius: 12,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Icon(
              thought.icon,
              color: selected ? Colors.white : thought.color,
              size: selected ? 25 : 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCore extends StatelessWidget {
  const _GlassCore({
    required this.count,
    required this.selected,
    required this.onSelectedTap,
  });

  final int count;
  final Thought? selected;
  final VoidCallback onSelectedTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: selected != null,
      label: selected == null
          ? '$count active thought loops'
          : 'Focused thought: ${selected!.title}',
      child: GestureDetector(
        onTap: selected == null ? null : onSelectedTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 174,
              height: 174,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.38, -0.43),
                  radius: 1.05,
                  colors: <Color>[
                    Color(0xFFFFFFFF),
                    Color(0xEAF5E8FF),
                    Color(0xCDEBC8FF),
                    Color(0xC5FFC7B0),
                  ],
                  stops: <double>[0, 0.3, 0.7, 1],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.6,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x447357FF),
                    blurRadius: 42,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Color(0x2EFF914D),
                    blurRadius: 54,
                    offset: Offset(18, 14),
                  ),
                  BoxShadow(
                    color: Color(0x28EF5DBB),
                    blurRadius: 48,
                    offset: Offset(-17, 8),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 30,
                    top: 22,
                    child: Container(
                      width: 54,
                      height: 31,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        gradient: LinearGradient(
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.82),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: selected == null
                            ? Column(
                                key: const ValueKey<String>('count'),
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    '$count',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.copyWith(fontSize: 50, height: 0.95),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    count == 1 ? 'active loop' : 'active loops',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: ThoughtCircleColors.ink,
                                        ),
                                  ),
                                ],
                              )
                            : Column(
                                key: ValueKey<String>(selected!.id),
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    selected!.icon,
                                    size: 25,
                                    color: selected!.color,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    selected!.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: ThoughtCircleColors.ink,
                                          height: 1.22,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Tap to open',
                                    style: TextStyle(
                                      color: ThoughtCircleColors.muted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitalFieldPainter extends CustomPainter {
  const _OrbitalFieldPainter({required this.rotation, required this.pulse});

  final double rotation;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.51);
    final radius = math.min(size.width * 0.31, size.height * 0.27);

    final auraRect = Rect.fromCircle(center: center, radius: radius + 24);
    final aura = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28 + pulse * 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24)
      ..shader = SweepGradient(
        transform: GradientRotation(rotation * 0.35),
        colors: const <Color>[
          Color(0x38FF914D),
          Color(0x42EF5DBB),
          Color(0x407357FF),
          Color(0x38FF914D),
        ],
      ).createShader(auraRect);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: (radius + 20) * 2,
        height: (radius + 20) * 1.58,
      ),
      aura,
    );

    for (var index = 0; index < 3; index++) {
      final ringRadius = radius + (index - 1) * 23;
      final ringRect = Rect.fromCenter(
        center: center,
        width: ringRadius * 2,
        height: ringRadius * 1.64,
      );
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = index == 1 ? 3.8 : 1.45
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          transform: GradientRotation(rotation * (index == 1 ? -0.5 : 0.4)),
          colors: <Color>[
            ThoughtCircleColors.orange.withValues(alpha: 0.84),
            ThoughtCircleColors.pink.withValues(alpha: 0.74),
            ThoughtCircleColors.purple.withValues(alpha: 0.78),
            ThoughtCircleColors.orange.withValues(alpha: 0.84),
          ],
        ).createShader(ringRect);
      canvas.drawOval(ringRect, ring);
    }

    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ThoughtCircleColors.purple.withValues(alpha: 0.09);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: (radius + 48) * 2,
        height: (radius + 48) * 1.62,
      ),
      guide,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: (radius - 46) * 2,
        height: (radius - 46) * 1.62,
      ),
      guide,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitalFieldPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.pulse != pulse;
  }
}
