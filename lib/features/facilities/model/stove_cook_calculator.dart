import 'package:flutter/material.dart';
import 'facility.dart'; // import your existing model + extension

class StoveCookCalculator extends StatefulWidget {
  final List<Facility> stoves;

  const StoveCookCalculator({super.key, required this.stoves});

  @override
  State<StoveCookCalculator> createState() => _StoveCookCalculatorState();
}

class _StoveCookCalculatorState extends State<StoveCookCalculator> {
  final _controller = TextEditingController();
  double? _baseSeconds;

  void _onCalculate() {
    final text = _controller.text.trim();
    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a number of seconds > 0')),
      );
      return;
    }
    setState(() => _baseSeconds = value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dish cook length (seconds)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'e.g. 120',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _onCalculate,
              child: const Text('Calculate'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_baseSeconds != null)
          Expanded(
            child: ListView(
              children: widget.stoves.map((stove) {
                final eff = stove.cookingEfficiencyPercent;
                final cook = stove.cookTimeFor(_baseSeconds!);
                final saved = _baseSeconds! - cook;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(stove.name),
                    subtitle: Text(
                      'Efficiency: +${eff.toStringAsFixed(1)}%\n'
                      'Cook time: ${cook.toStringAsFixed(1)}s '
                      '(saved ${saved.toStringAsFixed(1)}s)',
                    ),
                    trailing: Text(stove.group),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
