import 'package:flutter/material.dart';

/// RGB colors match the existing vehicle color API and saved fleet records.
class VehicleColorPicker extends StatelessWidget {
  const VehicleColorPicker(
      {super.key,
      required this.value,
      required this.onChanged,
      this.enabled = true});
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  static const presets = [
    '#111418',
    '#2563EB',
    '#16A34A',
    '#DC2626',
    '#D97706',
    '#7C3AED'
  ];

  static Color _color(String hex) => Color(0xFF000000 |
      (int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0x111418));
  static String _hex(Color color) =>
      '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Future<void> _custom(BuildContext context) async {
    final selected = await showDialog<String>(
        context: context, builder: (_) => _CustomColorDialog(value: value));
    if (selected != null && context.mounted) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final custom = !presets.contains(value.toUpperCase());
    return Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final preset in presets)
            Semantics(
              label: 'Vehicle color $preset',
              selected: value.toUpperCase() == preset,
              button: true,
              child: InkWell(
                  onTap: enabled ? () => onChanged(preset) : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: _color(preset),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: value.toUpperCase() == preset
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              width: value.toUpperCase() == preset ? 3 : 1)),
                      child: value.toUpperCase() == preset
                          ? Icon(Icons.check,
                              color: ThemeData.estimateBrightnessForColor(
                                          _color(preset)) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                          : null)),
            ),
          OutlinedButton.icon(
              onPressed: enabled ? () => _custom(context) : null,
              icon: custom
                  ? Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          color: _color(value),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey)))
                  : const Icon(Icons.palette_outlined),
              label: Text(
                  custom ? 'Custom: ${value.toUpperCase()}' : 'Custom color')),
        ]);
  }
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({required this.value});
  final String value;
  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late HSVColor _hsv;
  late TextEditingController _input;
  bool _valid = true;
  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(VehicleColorPicker._color(widget.value));
    _input =
        TextEditingController(text: VehicleColorPicker._hex(_hsv.toColor()));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _change(HSVColor next) => setState(() {
        _hsv = next;
        _input.text = VehicleColorPicker._hex(next.toColor());
        _valid = true;
      });
  Widget _slider(String label, double current, double max,
          ValueChanged<double> changed) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Slider(value: current, max: max, label: label, onChanged: changed)
        ],
      );
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Custom vehicle color'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: _hsv.toColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey))),
          const SizedBox(height: 16),
          _slider('Hue', _hsv.hue, 360, (v) => _change(_hsv.withHue(v))),
          _slider('Saturation', _hsv.saturation, 1,
              (v) => _change(_hsv.withSaturation(v))),
          _slider(
              'Brightness', _hsv.value, 1, (v) => _change(_hsv.withValue(v))),
          TextField(
              controller: _input,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                  labelText: 'Color code (optional)',
                  hintText: '#C0C0C0',
                  errorText: _valid
                      ? null
                      : 'Enter six hexadecimal digits, e.g. #C0C0C0.'),
              onChanged: (text) => setState(() {
                    final normalized = text.trim().replaceFirst('#', '');
                    _valid = RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(normalized);
                    if (_valid) {
                      _hsv = HSVColor.fromColor(
                          VehicleColorPicker._color(normalized));
                    }
                  })),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _valid
                  ? () => Navigator.pop(
                      context, VehicleColorPicker._hex(_hsv.toColor()))
                  : null,
              child: const Text('Use color')),
        ],
      );
}
