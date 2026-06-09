import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum PomodoroState { work, shortBreak, longBreak }

class PomodoroTab extends StatefulWidget {
  const PomodoroTab({super.key});

  @override
  State<PomodoroTab> createState() => _PomodoroTabState();
}

class _PomodoroTabState extends State<PomodoroTab> with SingleTickerProviderStateMixin {
  PomodoroState _state = PomodoroState.work;
  int _workMin = 25;
  int _shortMin = 5;
  int _longMin = 15;
  int _cyclesBeforeLong = 4;

  int _remaining = 0;
  int _totalSec = 0;
  bool _running = false;
  int _cycleCount = 0;
  int _completedPomodoros = 0;
  Timer? _timer;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _reset(notify: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  int _durationFor(PomodoroState s) {
    switch (s) {
      case PomodoroState.work: return _workMin * 60;
      case PomodoroState.shortBreak: return _shortMin * 60;
      case PomodoroState.longBreak: return _longMin * 60;
    }
  }

  void _reset({bool notify = true}) {
    _timer?.cancel();
    _running = false;
    _totalSec = _durationFor(_state);
    _remaining = _totalSec;
    if (notify) setState(() {});
  }

  void _startPause() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      if (_remaining == 0) _reset();
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining > 0) {
          setState(() => _remaining--);
        } else {
          _timer?.cancel();
          setState(() { _running = false; });
          _onComplete();
        }
      });
    }
  }

  void _onComplete() {
    if (_state == PomodoroState.work) {
      _cycleCount++;
      _completedPomodoros++;
      final goLong = _cycleCount % _cyclesBeforeLong == 0;
      _state = goLong ? PomodoroState.longBreak : PomodoroState.shortBreak;
    } else {
      _state = PomodoroState.work;
    }
    _reset();
  }

  void _switchState(PomodoroState s) {
    _state = s;
    _reset();
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Color _stateColor(ColorScheme cs) {
    switch (_state) {
      case PomodoroState.work: return cs.primary;
      case PomodoroState.shortBreak: return Colors.green;
      case PomodoroState.longBreak: return Colors.blue;
    }
  }

  String _stateLabel() {
    switch (_state) {
      case PomodoroState.work: return '🍅 Tập trung';
      case PomodoroState.shortBreak: return '☕ Nghỉ ngắn';
      case PomodoroState.longBreak: return '🌴 Nghỉ dài';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _stateColor(cs);
    final progress = _totalSec > 0 ? _remaining / _totalSec : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ModeChip('Tập trung', PomodoroState.work, _state, cs.primary, () => _switchState(PomodoroState.work)),
              const SizedBox(width: 8),
              _ModeChip('Nghỉ ngắn', PomodoroState.shortBreak, _state, Colors.green, () => _switchState(PomodoroState.shortBreak)),
              const SizedBox(width: 8),
              _ModeChip('Nghỉ dài', PomodoroState.longBreak, _state, Colors.blue, () => _switchState(PomodoroState.longBreak)),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _CirclePainter(progress: progress, color: color,
                      bg: cs.surfaceContainerHighest),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_stateLabel(), style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(_remaining),
                    style: TextStyle(fontSize: 52, fontWeight: FontWeight.w200, color: color,
                        letterSpacing: 2),
                  ),
                  if (_running)
                    AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (_, __) => Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.3 + _animCtrl.value * 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
              ),
              const SizedBox(width: 20),
              FloatingActionButton.large(
                heroTag: 'pomodoro_fab',
                onPressed: _startPause,
                backgroundColor: _running ? cs.errorContainer : color.withOpacity(0.2),
                child: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: _running ? cs.onErrorContainer : color,
                  size: 40,
                ),
              ),
              const SizedBox(width: 20),
              OutlinedButton.icon(
                onPressed: _onComplete,
                icon: const Icon(Icons.skip_next),
                label: const Text('Bỏ qua'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoBox('🍅', '$_completedPomodoros', 'Pomodoro'),
                  _InfoBox('🔄', '${_cycleCount % _cyclesBeforeLong}/$_cyclesBeforeLong', 'Chu kỳ'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Cài đặt thời gian'),
            leading: const Icon(Icons.settings_outlined),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TimeSetting('Tập trung (phút)', _workMin, 1, 60, (v) => setState(() { _workMin = v; _reset(); })),
                    _TimeSetting('Nghỉ ngắn (phút)', _shortMin, 1, 30, (v) => setState(() { _shortMin = v; _reset(); })),
                    _TimeSetting('Nghỉ dài (phút)', _longMin, 1, 60, (v) => setState(() { _longMin = v; _reset(); })),
                    _TimeSetting('Chu kỳ trước nghỉ dài', _cyclesBeforeLong, 2, 8, (v) => setState(() => _cyclesBeforeLong = v)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final PomodoroState state, current;
  final Color color;
  final VoidCallback onTap;
  const _ModeChip(this.label, this.state, this.current, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = state == current;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? color : null)),
      selected: selected,
      selectedColor: color.withOpacity(0.15),
      onSelected: (_) => onTap(),
      side: BorderSide(color: selected ? color : Colors.transparent),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String emoji, value, label;
  const _InfoBox(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _TimeSetting extends StatelessWidget {
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const _TimeSetting(this.label, this.value, this.min, this.max, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 36,
            child: Text('$value', textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color, bg;
  const _CirclePainter({required this.progress, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 12;
    final bgPaint = Paint()..color = bg..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    final fgPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.progress != progress || old.color != color;
}
