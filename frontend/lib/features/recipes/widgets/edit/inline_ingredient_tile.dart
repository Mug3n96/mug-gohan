import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';
import 'inline_text_field.dart';

class InlineIngredientTile extends StatefulWidget {
  const InlineIngredientTile({
    super.key,
    required this.ingredient,
    required this.onChanged,
    required this.onDelete,
  });

  final Ingredient ingredient;
  final ValueChanged<Ingredient> onChanged;
  final VoidCallback onDelete;

  @override
  State<InlineIngredientTile> createState() => _InlineIngredientTileState();
}

class _InlineIngredientTileState extends State<InlineIngredientTile> {
  late TextEditingController _name;
  late TextEditingController _amount;
  late TextEditingController _group;
  late FocusNode _groupFocus;
  String _unit = 'g';
  bool _groupFocused = false;
  static const _units = ['g', 'ml', 'stk', 'EL', 'TL', 'Prise'];

  @override
  void initState() {
    super.initState();
    final i = widget.ingredient;
    _name = TextEditingController(text: i.name);
    _amount = TextEditingController(
        text: i.amount == 0 ? '' : i.amount.toString());
    _group = TextEditingController(text: i.group ?? '');
    _unit = i.unit.isEmpty ? 'g' : i.unit;
    _groupFocus = FocusNode()
      ..addListener(
          () => setState(() => _groupFocused = _groupFocus.hasFocus));
  }

  @override
  void didUpdateWidget(InlineIngredientTile old) {
    super.didUpdateWidget(old);
    final i = widget.ingredient;
    if (_name.text != i.name) _name.text = i.name;
    final a = i.amount == 0 ? '' : i.amount.toString();
    if (_amount.text != a) _amount.text = a;
    final g = i.group ?? '';
    if (_group.text != g) _group.text = g;
    if (_unit != i.unit && i.unit.isNotEmpty) setState(() => _unit = i.unit);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _group.dispose();
    _groupFocus.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(Ingredient(
        name: _name.text.trim(),
        amount: num.tryParse(_amount.text) ?? 0,
        unit: _unit,
        group: _group.text.trim().isEmpty ? null : _group.text.trim(),
      ));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                child: InlineTextField(
                  controller: _amount,
                  onChanged: _notify,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                  hint: '0',
                ),
              ),
              const SizedBox(width: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _unit,
                  isDense: true,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  items: _units
                      .map((u) =>
                          DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _unit = v!);
                    _notify();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InlineTextField(
                  controller: _name,
                  onChanged: _notify,
                  style: const TextStyle(fontSize: 15),
                  hint: 'Zutat',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: widget.onDelete,
                color: AppTheme.textSecondary.withAlpha(140),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          if (_groupFocused || _group.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: SizedBox(
                width: 180,
                child: InlineTextField(
                  controller: _group,
                  focusNode: _groupFocus,
                  onChanged: _notify,
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  hint: 'Gruppe (z.B. Teig, Sauce)',
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                setState(() => _groupFocused = true);
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _groupFocus.requestFocus());
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 30, top: 3, bottom: 2),
                child: Text(
                  '+ Gruppe',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary.withAlpha(100)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
