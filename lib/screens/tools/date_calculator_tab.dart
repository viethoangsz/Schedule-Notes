import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateCalculatorTab extends StatefulWidget {
  const DateCalculatorTab({super.key});

  @override
  State<DateCalculatorTab> createState() => _DateCalculatorTabState();
}

class _DateCalculatorTabState extends State<DateCalculatorTab> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now().add(const Duration(days: 30));
  final _fmt = DateFormat('dd/MM/yyyy');

  int get _diffDays => _to.difference(_from).inDays.abs();
  int get _diffWeeks => (_diffDays / 7).floor();
  int get _diffMonths {
    final a = _from.isBefore(_to) ? _from : _to;
    final b = _from.isBefore(_to) ? _to : _from;
    return (b.year - a.year) * 12 + b.month - a.month;
  }
  int get _diffYears => (_diffDays / 365.25).floor();

  Future<void> _pickDate(bool isFrom) async {
    final init = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _from = picked;
        else _to = picked;
      });
    }
  }

  String _weekdayName(DateTime d) {
    const names = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    return names[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isForward = !_to.isBefore(_from);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chọn khoảng thời gian',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _DateTile(
                    label: 'Ngày bắt đầu',
                    date: _from,
                    weekday: _weekdayName(_from),
                    fmt: _fmt,
                    icon: Icons.calendar_today,
                    onTap: () => _pickDate(true),
                    color: cs.primary,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Icon(Icons.swap_vert, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  _DateTile(
                    label: 'Ngày kết thúc',
                    date: _to,
                    weekday: _weekdayName(_to),
                    fmt: _fmt,
                    icon: Icons.event,
                    onTap: () => _pickDate(false),
                    color: cs.tertiary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    isForward ? '📅 Còn lại' : '📅 Đã qua',
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatBox(value: '$_diffDays', label: 'Ngày', color: cs.onPrimaryContainer),
                      _StatBox(value: '$_diffWeeks', label: 'Tuần', color: cs.onPrimaryContainer),
                      _StatBox(value: '$_diffMonths', label: 'Tháng', color: cs.onPrimaryContainer),
                      _StatBox(value: '$_diffYears', label: 'Năm', color: cs.onPrimaryContainer),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_diffDays * 24} giờ  •  ${_diffDays * 24 * 60} phút',
                    style: TextStyle(color: cs.onPrimaryContainer.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thêm / bớt ngày từ hôm nay',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _QuickAdd(onResult: (d) => setState(() => _to = d)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label, weekday;
  final DateTime date;
  final DateFormat fmt;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _DateTile({required this.label, required this.date, required this.weekday,
      required this.fmt, required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  Text('$weekday, ${fmt.format(date)}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
      ],
    );
  }
}

class _QuickAdd extends StatefulWidget {
  final ValueChanged<DateTime> onResult;
  const _QuickAdd({required this.onResult});

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final _ctrl = TextEditingController(text: '30');
  String _unit = 'Ngày';
  bool _add = true;
  DateTime? _result;

  void _calc() {
    final n = int.tryParse(_ctrl.text) ?? 0;
    final now = DateTime.now();
    DateTime r;
    switch (_unit) {
      case 'Tuần': r = now.add(Duration(days: n * 7 * (_add ? 1 : -1))); break;
      case 'Tháng': r = DateTime(now.year, now.month + n * (_add ? 1 : -1), now.day); break;
      case 'Năm': r = DateTime(now.year + n * (_add ? 1 : -1), now.month, now.day); break;
      default: r = now.add(Duration(days: n * (_add ? 1 : -1)));
    }
    setState(() => _result = r);
    widget.onResult(r);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd/MM/yyyy');
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('+')),
                ButtonSegment(value: false, label: Text('-')),
              ],
              selected: {_add},
              onSelectionChanged: (s) => setState(() => _add = s.first),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 8)),
                onChanged: (_) => _calc(),
              ),
            ),
            DropdownButton<String>(
              value: _unit,
              items: ['Ngày', 'Tuần', 'Tháng', 'Năm']
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) { setState(() => _unit = v!); _calc(); },
            ),
            FilledButton.tonal(onPressed: _calc, child: const Text('Tính')),
          ],
        ),
        if (_result != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.event_available, color: cs.onSecondaryContainer, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(fmt.format(_result!),
                      style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSecondaryContainer)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
