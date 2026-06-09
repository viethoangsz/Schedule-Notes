import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'unit_converter_tab.dart';
import 'date_calculator_tab.dart';
import 'base64_qr_tab.dart';
import 'pomodoro_tab.dart';
import 'relaxing_sounds_tab.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const _tools = [
    _ToolItem(
      id: 'calculator',
      icon: Icons.calculate_outlined,
      emoji: '🧮',
      name: 'Máy tính',
      desc: 'Tính toán cơ bản',
      gradient: [Color(0xFF6B4EFF), Color(0xFF9C7BFF)],
    ),
    _ToolItem(
      id: 'stopwatch',
      icon: Icons.timer_outlined,
      emoji: '⏱️',
      name: 'Đồng hồ bấm giờ',
      desc: 'Đo thời gian, ghi lap',
      gradient: [Color(0xFF00897B), Color(0xFF26A69A)],
    ),
    _ToolItem(
      id: 'countdown',
      icon: Icons.hourglass_empty_outlined,
      emoji: '⏳',
      name: 'Đếm ngược',
      desc: 'Hẹn giờ đếm lùi',
      gradient: [Color(0xFFE64A19), Color(0xFFFF7043)],
    ),
    _ToolItem(
      id: 'converter',
      icon: Icons.straighten,
      emoji: '📏',
      name: 'Đổi đơn vị',
      desc: 'Km, kg, °C, m²...',
      gradient: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    ),
    _ToolItem(
      id: 'date',
      icon: Icons.date_range_outlined,
      emoji: '📅',
      name: 'Tính ngày',
      desc: 'Khoảng cách ngày tháng',
      gradient: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    ),
    _ToolItem(
      id: 'base64',
      icon: Icons.code,
      emoji: '🔢',
      name: 'Mã hóa Base64',
      desc: 'Encode / Decode',
      gradient: [Color(0xFF00695C), Color(0xFF26A69A)],
    ),
    _ToolItem(
      id: 'pomodoro',
      icon: Icons.local_pizza_outlined,
      emoji: '🍅',
      name: 'Pomodoro',
      desc: 'Tập trung 25 phút',
      gradient: [Color(0xFFC62828), Color(0xFFEF5350)],
    ),
    _ToolItem(
      id: 'relax',
      icon: Icons.headphones_outlined,
      emoji: '🎵',
      name: 'Âm thanh thư giãn',
      desc: 'Mưa, sóng biển...',
      gradient: [Color(0xFF1A237E), Color(0xFF5C6BC0)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Bộ công cụ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: cs.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withOpacity(isDark ? 0.2 : 0.08),
                      cs.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ToolCard(tool: _tools[i]),
                childCount: _tools.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  final String id, emoji, name, desc;
  final IconData icon;
  final List<Color> gradient;
  const _ToolItem({
    required this.id,
    required this.icon,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.gradient,
  });
}

class _ToolCard extends StatelessWidget {
  final _ToolItem tool;
  const _ToolCard({super.key, required this.tool});

  void _open(BuildContext context) {
    Widget page;
    switch (tool.id) {
      case 'calculator':
        page = const _FullToolPage(title: 'Máy tính', child: _CalculatorTab());
        break;
      case 'stopwatch':
        page = const _FullToolPage(title: 'Đồng hồ bấm giờ', child: _StopwatchTab());
        break;
      case 'countdown':
        page = const _FullToolPage(title: 'Đếm ngược', child: _TimerTab());
        break;
      case 'converter':
        page = const _FullToolPage(title: 'Đổi đơn vị', child: UnitConverterTab());
        break;
      case 'date':
        page = const _FullToolPage(title: 'Tính ngày', child: DateCalculatorTab());
        break;
      case 'base64':
        page = const _FullToolPage(title: 'Mã hóa Base64', child: Base64QrTab());
        break;
      case 'pomodoro':
        page = const _FullToolPage(title: 'Pomodoro Timer', child: PomodoroTab());
        break;
      default:
        page = const _FullToolPage(title: 'Âm thanh thư giãn', child: RelaxingSoundsTab());
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tool.gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: tool.gradient[0].withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tool.emoji, style: const TextStyle(fontSize: 30)),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  tool.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  tool.desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullToolPage extends StatelessWidget {
  final String title;
  final Widget child;
  const _FullToolPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
      ),
      body: child,
    );
  }
}

// ─── Calculator ──────────────────────────────────────────────────────────────
class _CalculatorTab extends StatefulWidget {
  const _CalculatorTab();
  @override
  State<_CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<_CalculatorTab> {
  String _display = '0';
  String _expression = '';
  double _operand1 = 0;
  String _operator = '';
  bool _newInput = true;

  void _onButton(String label) {
    setState(() {
      if (label == 'C') {
        _display = '0'; _expression = ''; _operand1 = 0; _operator = ''; _newInput = true;
      } else if (label == '⌫') {
        if (_display.length > 1) _display = _display.substring(0, _display.length - 1);
        else { _display = '0'; _newInput = true; }
      } else if (label == '+/-') {
        if (_display != '0') _display = _display.startsWith('-') ? _display.substring(1) : '-$_display';
      } else if (label == '%') {
        _display = _fmt((double.tryParse(_display) ?? 0) / 100); _newInput = true;
      } else if (['+', '-', '×', '÷'].contains(label)) {
        _operand1 = double.tryParse(_display) ?? 0;
        _operator = label; _expression = '${_fmt(_operand1)} $label'; _newInput = true;
      } else if (label == '=') {
        if (_operator.isNotEmpty) {
          final op2 = double.tryParse(_display) ?? 0;
          double r;
          switch (_operator) {
            case '+': r = _operand1 + op2; break;
            case '-': r = _operand1 - op2; break;
            case '×': r = _operand1 * op2; break;
            case '÷': r = op2 == 0 ? 0 : _operand1 / op2; break;
            default: r = op2;
          }
          _expression = '${_fmt(_operand1)} $_operator ${_fmt(op2)} =';
          _display = _fmt(r); _operator = ''; _newInput = true;
        }
      } else if (label == '.') {
        if (_newInput) { _display = '0.'; _newInput = false; }
        else if (!_display.contains('.')) _display += '.';
      } else {
        if (_newInput || _display == '0') { _display = label; _newInput = false; }
        else if (_display.length < 12) _display += label;
      }
    });
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final buttons = [
      ['C', '+/-', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['⌫', '0', '.', '='],
    ];
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_expression.isNotEmpty)
                  Text(_expression, style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant), textAlign: TextAlign.right),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(_display, style: TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: cs.onSurface)),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10,
            ),
            itemCount: 20,
            itemBuilder: (_, i) {
              final label = buttons[i ~/ 4][i % 4];
              final isOp = ['+', '-', '×', '÷', '='].contains(label);
              final isMath = ['C', '+/-', '%'].contains(label);
              Color bg, fg;
              if (label == '=') { bg = cs.primary; fg = cs.onPrimary; }
              else if (isOp) { bg = cs.primaryContainer; fg = cs.onPrimaryContainer; }
              else if (isMath) { bg = cs.secondaryContainer; fg = cs.onSecondaryContainer; }
              else { bg = cs.surfaceContainerHighest; fg = cs.onSurface; }
              return Material(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _onButton(label),
                  child: Center(child: Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: fg))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Stopwatch ────────────────────────────────────────────────────────────────
class _StopwatchTab extends StatefulWidget {
  const _StopwatchTab();
  @override
  State<_StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<_StopwatchTab> {
  final Stopwatch _sw = Stopwatch();
  Timer? _timer;
  final List<String> _laps = [];

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _startStop() {
    if (_sw.isRunning) { _sw.stop(); _timer?.cancel(); }
    else {
      _sw.start();
      _timer = Timer.periodic(const Duration(milliseconds: 30), (_) { if (mounted) setState(() {}); });
    }
    setState(() {});
  }

  void _reset() { _sw.reset(); _sw.stop(); _timer?.cancel(); setState(() => _laps.clear()); }
  void _lap() { if (_sw.isRunning) setState(() => _laps.insert(0, _elapsed(_sw.elapsed))); }

  String _elapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final running = _sw.isRunning;
    return Column(
      children: [
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220, height: 220,
              child: CircularProgressIndicator(
                value: (_sw.elapsed.inMilliseconds % 60000) / 60000,
                strokeWidth: 8, backgroundColor: cs.surfaceContainerHighest, color: cs.primary,
              ),
            ),
            Text(_elapsed(_sw.elapsed), style: TextStyle(fontSize: 38, fontWeight: FontWeight.w300, color: cs.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: running ? _lap : _reset,
              icon: Icon(running ? Icons.flag_outlined : Icons.refresh),
              label: Text(running ? 'Lap' : 'Reset'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
            ),
            const SizedBox(width: 20),
            FloatingActionButton.large(
              heroTag: 'stopwatch_fab',
              onPressed: _startStop,
              backgroundColor: running ? cs.errorContainer : cs.primaryContainer,
              child: Icon(running ? Icons.pause : Icons.play_arrow,
                  color: running ? cs.onErrorContainer : cs.onPrimaryContainer, size: 36),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_laps.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _laps.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lap ${_laps.length - i}', style: TextStyle(color: cs.onSurfaceVariant)),
                    Text(_laps[i], style: const TextStyle(fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Timer ────────────────────────────────────────────────────────────────────
class _TimerTab extends StatefulWidget {
  const _TimerTab();
  @override
  State<_TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<_TimerTab> {
  Timer? _timer;
  int _totalSeconds = 0, _remaining = 0;
  bool _running = false, _finished = false;
  final _hCtrl = TextEditingController(text: '0');
  final _mCtrl = TextEditingController(text: '5');
  final _sCtrl = TextEditingController(text: '0');

  @override
  void dispose() { _timer?.cancel(); _hCtrl.dispose(); _mCtrl.dispose(); _sCtrl.dispose(); super.dispose(); }

  void _start() {
    if (_totalSeconds == 0) {
      _totalSeconds = (int.tryParse(_hCtrl.text) ?? 0) * 3600 +
          (int.tryParse(_mCtrl.text) ?? 0) * 60 + (int.tryParse(_sCtrl.text) ?? 0);
      _remaining = _totalSeconds;
    }
    if (_remaining == 0) return;
    setState(() { _running = true; _finished = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) setState(() => _remaining--);
      else { _timer?.cancel(); setState(() { _running = false; _finished = true; }); }
    });
  }

  void _pauseResume() {
    if (_running) { _timer?.cancel(); setState(() => _running = false); } else _start();
  }

  void _reset() {
    _timer?.cancel();
    setState(() { _running = false; _finished = false; _remaining = 0; _totalSeconds = 0; });
  }

  String _fmt(int secs) {
    final h = secs ~/ 3600; final m = (secs % 3600) ~/ 60; final s = secs % 60;
    if (h > 0) return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = _totalSeconds > 0 ? _remaining / _totalSeconds : 0.0;
    final started = _totalSeconds > 0;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 220, height: 220,
                child: CircularProgressIndicator(
                  value: started ? progress : 1.0, strokeWidth: 10,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: _finished ? cs.error : cs.primary,
                ),
              ),
              if (started)
                Text(_fmt(_remaining), style: TextStyle(fontSize: 42, fontWeight: FontWeight.w300,
                    color: _finished ? cs.error : cs.onSurface, fontFeatures: const [FontFeature.tabularFigures()]))
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TimeInput(ctrl: _hCtrl, label: 'h'),
                    const Text(' : ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300)),
                    _TimeInput(ctrl: _mCtrl, label: 'm'),
                    const Text(' : ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300)),
                    _TimeInput(ctrl: _sCtrl, label: 's'),
                  ],
                ),
            ],
          ),
          if (_finished) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('⏰ Hết giờ!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.error)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh), label: const Text('Reset'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
              ),
              const SizedBox(width: 20),
              FloatingActionButton.large(
                heroTag: 'timer_fab',
                onPressed: started ? _pauseResume : _start,
                backgroundColor: _running ? cs.errorContainer : cs.primaryContainer,
                child: Icon(_running ? Icons.pause : Icons.play_arrow,
                    color: _running ? cs.onErrorContainer : cs.onPrimaryContainer, size: 36),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TimeInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _TimeInput({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 52,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '0', suffixText: label,
          suffixStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300),
      ),
    );
  }
}
