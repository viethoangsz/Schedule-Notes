import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Base64QrTab extends StatefulWidget {
  const Base64QrTab({super.key});

  @override
  State<Base64QrTab> createState() => _Base64QrTabState();
}

class _Base64QrTabState extends State<Base64QrTab> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _encodeCtrl = TextEditingController();
  final _decodeCtrl = TextEditingController();
  String _encoded = '';
  String _decoded = '';
  String _decodeError = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _encodeCtrl.dispose();
    _decodeCtrl.dispose();
    super.dispose();
  }

  void _encode() {
    final text = _encodeCtrl.text;
    if (text.isEmpty) { setState(() => _encoded = ''); return; }
    setState(() => _encoded = base64.encode(utf8.encode(text)));
  }

  void _decode() {
    final text = _decodeCtrl.text.trim();
    if (text.isEmpty) { setState(() { _decoded = ''; _decodeError = ''; }); return; }
    try {
      final decoded = utf8.decode(base64.decode(text));
      setState(() { _decoded = decoded; _decodeError = ''; });
    } catch (_) {
      setState(() { _decoded = ''; _decodeError = 'Chuỗi Base64 không hợp lệ!'; });
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép!'), behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Mã hóa (Encode)'),
            Tab(text: 'Giải mã (Decode)'),
          ],
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildEncode(cs),
              _buildDecode(cs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEncode(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _encodeCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Văn bản cần mã hóa',
              alignLabelWithHint: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () { _encodeCtrl.clear(); setState(() => _encoded = ''); },
              ),
            ),
            onChanged: (_) => _encode(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _encode,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Mã hóa Base64'),
          ),
          if (_encoded.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ResultCard(
              label: 'Kết quả Base64',
              value: _encoded,
              onCopy: () => _copy(_encoded),
              color: cs,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDecode(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _decodeCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Chuỗi Base64 cần giải mã',
              alignLabelWithHint: true,
              errorText: _decodeError.isNotEmpty ? _decodeError : null,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () { _decodeCtrl.clear(); setState(() { _decoded = ''; _decodeError = ''; }); },
              ),
            ),
            onChanged: (_) => _decode(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _decode,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Giải mã Base64'),
          ),
          if (_decoded.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ResultCard(
              label: 'Văn bản gốc',
              value: _decoded,
              onCopy: () => _copy(_decoded),
              color: cs,
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label, value;
  final VoidCallback onCopy;
  final ColorScheme color;
  const _ResultCard({required this.label, required this.value, required this.onCopy, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color.onPrimaryContainer)),
              IconButton.filledTonal(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Sao chép',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: TextStyle(color: color.onPrimaryContainer, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
