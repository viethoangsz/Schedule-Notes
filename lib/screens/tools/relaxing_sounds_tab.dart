import 'dart:async';
import 'package:flutter/material.dart';

class RelaxingSoundsTab extends StatefulWidget {
  const RelaxingSoundsTab({super.key});

  @override
  State<RelaxingSoundsTab> createState() => _RelaxingSoundsTabState();
}

class _RelaxingSoundsTabState extends State<RelaxingSoundsTab> with TickerProviderStateMixin {
  final Map<String, double> _volumes = {};
  final Map<String, bool> _playing = {};
  late AnimationController _waveCtrl;

  static const sounds = [
    _Sound('rain', '🌧️', 'Mưa rào', 'Tiếng mưa nhẹ nhàng', Colors.blue),
    _Sound('ocean', '🌊', 'Sóng biển', 'Tiếng sóng vỗ bờ', Color(0xFF0097A7)),
    _Sound('forest', '🌿', 'Rừng cây', 'Chim hót, gió thổi', Colors.green),
    _Sound('thunder', '⛈️', 'Sấm chớp', 'Mưa giông xa xa', Color(0xFF5C6BC0)),
    _Sound('fire', '🔥', 'Lửa trại', 'Lửa crackling ấm áp', Color(0xFFE64A19)),
    _Sound('wind', '🍃', 'Gió núi', 'Gió thổi qua lá cây', Color(0xFF558B2F)),
    _Sound('cafe', '☕', 'Quán cà phê', 'Tiếng ồn ào nhẹ', Color(0xFF795548)),
    _Sound('whitenoise', '📻', 'White Noise', 'Tiếng ồn trắng thư giãn', Colors.grey),
  ];

  bool get _anyPlaying => _playing.values.any((p) => p);

  @override
  void initState() {
    super.initState();
    for (final s in sounds) {
      _volumes[s.id] = 0.7;
      _playing[s.id] = false;
    }
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() => _playing[id] = !(_playing[id] ?? false));
  }

  void _stopAll() {
    setState(() {
      for (final k in _playing.keys) {
        _playing[k] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (_anyPlaying)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(4, (i) {
                      final h = 6.0 + (_waveCtrl.value * 12 * ((i % 2 == 0) ? 1 : -1)).abs();
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3,
                        height: h,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đang phát ${_playing.values.where((p) => p).length} âm thanh',
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _stopAll,
                  child: Text('Dừng tất cả', style: TextStyle(color: cs.primary)),
                ),
              ],
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Lưu ý: âm thanh là mô phỏng — để nghe thực, cần kết hợp với nhạc nền từ điện thoại.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: sounds.length,
            itemBuilder: (_, i) {
              final s = sounds[i];
              final playing = _playing[s.id] ?? false;
              final vol = _volumes[s.id] ?? 0.7;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: playing ? s.color.withOpacity(0.15) : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: playing ? s.color : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: playing
                      ? [BoxShadow(color: s.color.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _toggle(s.id),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.emoji, style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text(s.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: playing ? s.color : cs.onSurface,
                              )),
                          Text(s.desc,
                              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          if (playing) ...[
                            Row(
                              children: [
                                Icon(Icons.volume_down, size: 14, color: s.color),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                      activeTrackColor: s.color,
                                      inactiveTrackColor: s.color.withOpacity(0.2),
                                      thumbColor: s.color,
                                    ),
                                    child: Slider(
                                      value: vol,
                                      onChanged: (v) => setState(() => _volumes[s.id] = v),
                                    ),
                                  ),
                                ),
                                Icon(Icons.volume_up, size: 14, color: s.color),
                              ],
                            ),
                          ] else
                            Icon(Icons.play_circle_outline, color: cs.onSurfaceVariant, size: 28),
                        ],
                      ),
                    ),
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

class _Sound {
  final String id, emoji, name, desc;
  final Color color;
  const _Sound(this.id, this.emoji, this.name, this.desc, this.color);
}
