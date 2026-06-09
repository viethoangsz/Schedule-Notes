import 'package:flutter/material.dart';

class UnitConverterTab extends StatefulWidget {
  const UnitConverterTab({super.key});

  @override
  State<UnitConverterTab> createState() => _UnitConverterTabState();
}

class _UnitConverterTabState extends State<UnitConverterTab> {
  int _categoryIndex = 0;
  final _inputCtrl = TextEditingController();
  int _fromIndex = 0;
  int _toIndex = 1;
  String _result = '';

  static const categories = [
    _Category(
      name: 'Độ dài',
      icon: Icons.straighten,
      units: ['Kilomet (km)', 'Mét (m)', 'Centimét (cm)', 'Milimét (mm)', 'Dặm (mile)', 'Yard', 'Foot', 'Inch'],
      toBase: [1000.0, 1.0, 0.01, 0.001, 1609.344, 0.9144, 0.3048, 0.0254],
    ),
    _Category(
      name: 'Khối lượng',
      icon: Icons.monitor_weight_outlined,
      units: ['Tấn', 'Kilôgam (kg)', 'Gam (g)', 'Miligam (mg)', 'Pound (lb)', 'Ounce (oz)'],
      toBase: [1000.0, 1.0, 0.001, 0.000001, 0.453592, 0.0283495],
    ),
    _Category(
      name: 'Nhiệt độ',
      icon: Icons.thermostat,
      units: ['Celsius (°C)', 'Fahrenheit (°F)', 'Kelvin (K)'],
      toBase: [1.0, 1.0, 1.0],
    ),
    _Category(
      name: 'Diện tích',
      icon: Icons.crop_square,
      units: ['km²', 'm²', 'cm²', 'Hecta (ha)', 'Acre', 'ft²'],
      toBase: [1e6, 1.0, 0.0001, 10000.0, 4046.86, 0.092903],
    ),
    _Category(
      name: 'Tốc độ',
      icon: Icons.speed,
      units: ['km/h', 'm/s', 'mph', 'Knot'],
      toBase: [1.0, 3.6, 1.60934, 1.852],
    ),
    _Category(
      name: 'Dung tích',
      icon: Icons.water_drop_outlined,
      units: ['Lít (L)', 'Mililít (mL)', 'Gallon (US)', 'Gallon (UK)', 'fl oz'],
      toBase: [1.0, 0.001, 3.78541, 4.54609, 0.0295735],
    ),
  ];

  void _convert() {
    final val = double.tryParse(_inputCtrl.text.replaceAll(',', '.'));
    if (val == null) { setState(() => _result = ''); return; }
    final cat = categories[_categoryIndex];
    double result;
    if (cat.name == 'Nhiệt độ') {
      result = _convertTemp(val, _fromIndex, _toIndex);
    } else {
      final base = val * cat.toBase[_fromIndex];
      result = base / cat.toBase[_toIndex];
    }
    final fmt = result.abs() >= 1e6 || (result.abs() < 0.001 && result != 0)
        ? result.toStringAsExponential(4)
        : result % 1 == 0
            ? result.toInt().toString()
            : result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    setState(() => _result = fmt);
  }

  double _convertTemp(double val, int from, int to) {
    double celsius;
    switch (from) {
      case 0: celsius = val; break;
      case 1: celsius = (val - 32) * 5 / 9; break;
      case 2: celsius = val - 273.15; break;
      default: celsius = val;
    }
    switch (to) {
      case 0: return celsius;
      case 1: return celsius * 9 / 5 + 32;
      case 2: return celsius + 273.15;
      default: return celsius;
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = categories[_categoryIndex];
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final selected = i == _categoryIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(categories[i].icon, size: 16,
                      color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                  label: Text(categories[i].name),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _categoryIndex = i;
                    _fromIndex = 0;
                    _toIndex = 1;
                    _result = '';
                    _inputCtrl.clear();
                  }),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _UnitDropdown(
                                label: 'Từ',
                                units: cat.units,
                                value: _fromIndex,
                                onChanged: (v) => setState(() { _fromIndex = v!; _convert(); }),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: IconButton.filledTonal(
                                onPressed: () => setState(() {
                                  final tmp = _fromIndex;
                                  _fromIndex = _toIndex;
                                  _toIndex = tmp;
                                  _convert();
                                }),
                                icon: const Icon(Icons.swap_horiz),
                              ),
                            ),
                            Expanded(
                              child: _UnitDropdown(
                                label: 'Sang',
                                units: cat.units,
                                value: _toIndex,
                                onChanged: (v) => setState(() { _toIndex = v!; _convert(); }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _inputCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Giá trị',
                            prefixIcon: const Icon(Icons.input),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () { _inputCtrl.clear(); setState(() => _result = ''); },
                            ),
                          ),
                          onChanged: (_) => _convert(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_result.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: cs.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text('Kết quả', style: TextStyle(color: cs.onPrimaryContainer, fontSize: 13)),
                          const SizedBox(height: 8),
                          FittedBox(
                            child: Text(
                              '$_result ${cat.units[_toIndex].split(' ').last.replaceAll('(', '').replaceAll(')', '')}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_inputCtrl.text} ${cat.units[_fromIndex]} = $_result ${cat.units[_toIndex]}',
                            style: TextStyle(color: cs.onPrimaryContainer.withOpacity(0.7), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Category {
  final String name;
  final IconData icon;
  final List<String> units;
  final List<double> toBase;
  const _Category({required this.name, required this.icon, required this.units, required this.toBase});
}

class _UnitDropdown extends StatelessWidget {
  final String label;
  final List<String> units;
  final int value;
  final ValueChanged<int?> onChanged;
  const _UnitDropdown({required this.label, required this.units, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      isExpanded: true,
      items: units.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}
