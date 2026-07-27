import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/reflection.dart';
import '../state/app_controller.dart';
import '../widgets/soft_card.dart';

class MoodColorsPage extends StatefulWidget {
  const MoodColorsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<MoodColorsPage> createState() => _MoodColorsPageState();
}

class _MoodColorsPageState extends State<MoodColorsPage> {
  final _note = TextEditingController();
  double _hue = 265;
  double _saturation = 0.62;
  double _energy = 0.55;
  String? _chosenLabel;
  bool _saving = false;

  Color get _color => HSVColor.fromAHSV(1, _hue, _saturation, 0.94).toColor();

  String get _label => _chosenLabel ?? _colorName(_hue, _saturation);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.controller.addMoodColor(
        colorValue: _color.toARGB32(),
        label: _label,
        energy: _energy,
        note: _note.text,
      );
      _note.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Mood color saved.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _choosePreset(_MoodPreset preset) {
    setState(() {
      _hue = preset.hue;
      _saturation = preset.saturation;
      _energy = preset.energy;
      _chosenLabel = preset.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.controller.moodColors;
    return PageGlow(
      child: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar(title: Text('Mood colors')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 36),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Color the moment.',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: ThoughtCircleColors.purple,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Colors help guide replies.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SoftCard(
                        padding: const EdgeInsets.all(20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final picker = _PickerPanel(
                              color: _color,
                              hue: _hue,
                              saturation: _saturation,
                              label: _label,
                              energy: _energy,
                              note: _note,
                              saving: _saving,
                              onColorChanged: (hue, saturation) {
                                setState(() {
                                  _hue = hue;
                                  _saturation = saturation;
                                  _chosenLabel = null;
                                });
                              },
                              onEnergyChanged: (value) {
                                setState(() => _energy = value);
                              },
                              onPreset: _choosePreset,
                              onSave: _save,
                            );
                            if (constraints.maxWidth < 680) return picker;
                            return picker.wide();
                          },
                        ),
                      ),
                      const SizedBox(height: 26),
                      const SectionLabel('Past colors'),
                      const SizedBox(height: 9),
                      if (entries.isEmpty)
                        const _EmptyHistory()
                      else ...<Widget>[
                        _HistoryCard(entries: entries),
                        const SizedBox(height: 18),
                        const SectionLabel('Recent'),
                        const SizedBox(height: 9),
                        for (final entry in entries.take(5)) ...<Widget>[
                          _MoodRow(
                            entry: entry,
                            onDelete: () =>
                                widget.controller.deleteMoodColor(entry.id),
                          ),
                          const SizedBox(height: 9),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerPanel extends StatelessWidget {
  const _PickerPanel({
    required this.color,
    required this.hue,
    required this.saturation,
    required this.label,
    required this.energy,
    required this.note,
    required this.saving,
    required this.onColorChanged,
    required this.onEnergyChanged,
    required this.onPreset,
    required this.onSave,
  });

  final Color color;
  final double hue;
  final double saturation;
  final String label;
  final double energy;
  final TextEditingController note;
  final bool saving;
  final void Function(double hue, double saturation) onColorChanged;
  final ValueChanged<double> onEnergyChanged;
  final ValueChanged<_MoodPreset> onPreset;
  final VoidCallback onSave;

  Widget wide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(flex: 5, child: _wheel()),
        const SizedBox(width: 30),
        Expanded(flex: 6, child: _controls()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[_wheel(), const SizedBox(height: 18), _controls()],
    );
  }

  Widget _wheel() {
    return Center(
      child: MoodColorWheel(
        hue: hue,
        saturation: saturation,
        color: color,
        label: label,
        onChanged: onColorChanged,
      ),
    );
  }

  Widget _controls() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${(energy * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ThoughtCircleColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final preset in _presets)
                _PresetChip(
                  preset: preset,
                  selected:
                      (preset.hue - hue).abs() < 1 &&
                      (preset.saturation - saturation).abs() < 0.01,
                  onTap: () => onPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              const Icon(
                Icons.energy_savings_leaf_outlined,
                color: ThoughtCircleColors.good,
              ),
              const SizedBox(width: 9),
              Text('Energy', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          Slider(
            value: energy,
            onChanged: onEnergyChanged,
            activeColor: color,
            divisions: 20,
          ),
          TextField(
            controller: note,
            maxLength: 140,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'A short note (optional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: color.computeLuminance() > 0.55
                  ? ThoughtCircleColors.ink
                  : Colors.white,
            ),
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            label: const Text('Save color'),
          ),
        ],
      ),
    );
  }
}

class MoodColorWheel extends StatelessWidget {
  const MoodColorWheel({
    super.key,
    required this.hue,
    required this.saturation,
    required this.color,
    required this.label,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final Color color;
  final String label;
  final void Function(double hue, double saturation) onChanged;

  void _update(Offset point, Size size) {
    final center = size.center(Offset.zero);
    final delta = point - center;
    final radius = size.shortestSide / 2;
    final nextSaturation = (delta.distance / radius).clamp(0.0, 1.0);
    final radians = math.atan2(delta.dy, delta.dx);
    final nextHue = (radians * 180 / math.pi + 360) % 360;
    onChanged(nextHue, nextSaturation);
  }

  @override
  Widget build(BuildContext context) {
    const size = 226.0;
    return Semantics(
      label: 'Mood color picker',
      value: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size + 28,
        height: size + 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 34,
              spreadRadius: 3,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: GestureDetector(
          onPanStart: (details) =>
              _update(details.localPosition, const Size.square(size)),
          onPanUpdate: (details) =>
              _update(details.localPosition, const Size.square(size)),
          onTapDown: (details) =>
              _update(details.localPosition, const Size.square(size)),
          child: CustomPaint(
            size: const Size.square(size),
            painter: _MoodWheelPainter(
              hue: hue,
              saturation: saturation,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodWheelPainter extends CustomPainter {
  const _MoodWheelPainter({
    required this.hue,
    required this.saturation,
    required this.color,
  });

  final double hue;
  final double saturation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect);
    canvas.save();
    canvas.clipPath(circle);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const SweepGradient(
          colors: <Color>[
            Color(0xFFFF4D5E),
            Color(0xFFFFC857),
            Color(0xFF62D28F),
            Color(0xFF51D5DA),
            Color(0xFF5C72F2),
            Color(0xFFB456E6),
            Color(0xFFFF4D5E),
          ],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[Colors.white, Colors.white.withValues(alpha: 0)],
          stops: const <double>[0, 1],
        ).createShader(rect),
    );
    canvas.restore();

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    final angle = hue * math.pi / 180;
    final marker =
        center +
        Offset(math.cos(angle), math.sin(angle)) * (radius * saturation);
    canvas.drawCircle(
      marker,
      12,
      Paint()
        ..color = const Color(0x44201A40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(marker, 10, Paint()..color = Colors.white);
    canvas.drawCircle(marker, 7, Paint()..color = color);
    canvas.drawCircle(
      marker,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ThoughtCircleColors.ink.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _MoodWheelPainter oldDelegate) {
    return hue != oldDelegate.hue ||
        saturation != oldDelegate.saturation ||
        color != oldDelegate.color;
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final _MoodPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = HSVColor.fromAHSV(
      1,
      preset.hue,
      preset.saturation,
      0.94,
    ).toColor();
    return Material(
      color: selected ? color.withValues(alpha: 0.11) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? color : ThoughtCircleColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(preset.label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entries});

  final List<MoodColorEntry> entries;

  @override
  Widget build(BuildContext context) {
    final graphEntries = entries
        .take(30)
        .toList(growable: false)
        .reversed
        .toList();
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _patternText(entries),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${graphEntries.length} saved',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 178,
            width: double.infinity,
            child: CustomPaint(
              painter: _MoodHistoryPainter(entries: graphEntries),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: <Widget>[
              Text(
                _shortDate(graphEntries.first.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
              const Spacer(),
              Text(
                _shortDate(graphEntries.last.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodHistoryPainter extends CustomPainter {
  const _MoodHistoryPainter({required this.entries});

  final List<MoodColorEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 12.0;
    const bottom = 16.0;
    const side = 8.0;
    final height = size.height - top - bottom;
    final width = size.width - side * 2;
    final grid = Paint()
      ..color = ThoughtCircleColors.line
      ..strokeWidth = 1;
    for (final fraction in <double>[0, 0.5, 1]) {
      final y = top + height * fraction;
      canvas.drawLine(Offset(side, y), Offset(size.width - side, y), grid);
    }

    final points = <Offset>[];
    for (var index = 0; index < entries.length; index++) {
      final x = entries.length == 1
          ? size.width / 2
          : side + width * index / (entries.length - 1);
      final y = top + height * (1 - entries[index].energy);
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final area = Path()
        ..moveTo(points.first.dx, size.height - bottom)
        ..lineTo(points.first.dx, points.first.dy);
      for (var index = 1; index < points.length; index++) {
        final previous = points[index - 1];
        final current = points[index];
        final middle = (previous.dx + current.dx) / 2;
        area.cubicTo(
          middle,
          previous.dy,
          middle,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      area
        ..lineTo(points.last.dx, size.height - bottom)
        ..close();
      final lastColor = Color(entries.last.colorValue);
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              lastColor.withValues(alpha: 0.2),
              lastColor.withValues(alpha: 0.015),
            ],
          ).createShader(Offset.zero & size),
      );

      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (var index = 1; index < points.length; index++) {
        final previous = points[index - 1];
        final current = points[index];
        final middle = (previous.dx + current.dx) / 2;
        line.cubicTo(
          middle,
          previous.dy,
          middle,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = ThoughtCircleColors.ink.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var index = 0; index < points.length; index++) {
      final color = Color(entries[index].colorValue);
      canvas.drawCircle(points[index], 6.5, Paint()..color = Colors.white);
      canvas.drawCircle(points[index], 4.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodHistoryPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({required this.entry, required this.onDelete});

  final MoodColorEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(entry.colorValue);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${(entry.energy * 100).round()}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Text(
                  entry.note.isEmpty ? _shortDate(entry.createdAt) : entry.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete color',
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: <Widget>[
          const ThoughtCircleMark(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Your colors will gather here.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodPreset {
  const _MoodPreset(this.label, this.hue, this.saturation, this.energy);

  final String label;
  final double hue;
  final double saturation;
  final double energy;
}

const _presets = <_MoodPreset>[
  _MoodPreset('Calm', 210, 0.5, 0.36),
  _MoodPreset('Bright', 38, 0.78, 0.82),
  _MoodPreset('Tender', 342, 0.43, 0.45),
  _MoodPreset('Tense', 6, 0.76, 0.88),
  _MoodPreset('Low', 252, 0.48, 0.2),
  _MoodPreset('Mixed', 285, 0.58, 0.55),
];

String _colorName(double hue, double saturation) {
  if (saturation < 0.13) return 'Soft neutral';
  if (hue < 18 || hue >= 345) return 'Coral';
  if (hue < 48) return 'Amber';
  if (hue < 78) return 'Sunlit';
  if (hue < 150) return 'Leaf';
  if (hue < 195) return 'Aqua';
  if (hue < 235) return 'Sky';
  if (hue < 270) return 'Indigo';
  if (hue < 310) return 'Violet';
  return 'Rose';
}

String _patternText(List<MoodColorEntry> entries) {
  if (entries.length == 1) return 'Your first color';
  final recent = entries.take(7).toList(growable: false);
  final shift = recent.first.energy - recent.last.energy;
  if (shift > 0.16) return 'Energy is rising';
  if (shift < -0.16) return 'Energy is easing';
  if (recent.map((entry) => entry.label).toSet().length >= 4) {
    return 'A varied stretch';
  }
  return 'A steady stretch';
}

String _shortDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  return '${months[local.month - 1]} ${local.day}';
}
