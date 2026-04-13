import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'chat_sheet.dart';
import 'recipe_detail_provider.dart';
import 'recipe_model.dart';

// ─── Save status ───────────────────────────────────────────────────────────────

enum _SaveStatus { idle, saving, saved }

// ─── Screen ──────────────────────────────��─────────────────────────────────────

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(id));

    return recipeAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Fehler: $e')),
      ),
      data: (recipe) => _RecipeView(recipe: recipe, id: id),
    );
  }
}

// ─── Main stateful view ────────────────────────────────────────────────────────

class _RecipeView extends ConsumerStatefulWidget {
  const _RecipeView({required this.recipe, required this.id});
  final Recipe recipe;
  final String id;

  @override
  ConsumerState<_RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends ConsumerState<_RecipeView> {
  // ── Mode ───────────��───────────────���──────────────────────────────────────
  bool _editMode = false;

  // ── View-mode portion scaler ──────────────────────���───────────────────────
  late int _portions;

  // ── Edit-mode controllers ─────────────────────────────────────────────────
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _prepTimeCtrl;
  late TextEditingController _cookTimeCtrl;
  late TextEditingController _cuisineCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _notesCtrl;
  String _difficulty = 'einfach';
  int _editPortions = 4;
  List<String> _editTags = [];
  List<Ingredient> _editIngredients = [];
  List<RecipeStep> _editSteps = [];

  // ── Auto-save ────────────────────────────────────────────────────────���────
  _SaveStatus _saveStatus = _SaveStatus.idle;
  Timer? _debounce;
  Timer? _savedFadeTimer;

  // ── Chat panel ────────────────────────────────────────────────────────────
  bool _chatOpen = false;

  // ────────────��────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _portions = widget.recipe.portions > 0 ? widget.recipe.portions : 1;
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _prepTimeCtrl = TextEditingController();
    _cookTimeCtrl = TextEditingController();
    _cuisineCtrl = TextEditingController();
    _categoryCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void didUpdateWidget(_RecipeView old) {
    super.didUpdateWidget(old);
    if (!_editMode) {
      _portions =
          widget.recipe.portions > 0 ? widget.recipe.portions : 1;
    }
    // Sync edit controllers when a proposal was accepted (external update)
    if (_editMode && old.recipe != widget.recipe) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _savedFadeTimer?.cancel();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _prepTimeCtrl.dispose();
    _cookTimeCtrl.dispose();
    _cuisineCtrl.dispose();
    _categoryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ───────────���──────────────────────��──────────────────────────────────���───

  void _syncControllers() {
    final r = widget.recipe;
    _titleCtrl.text = r.title;
    _descCtrl.text = r.description;
    _prepTimeCtrl.text = r.prepTime;
    _cookTimeCtrl.text = r.cookTime;
    _cuisineCtrl.text = r.cuisine;
    _categoryCtrl.text = r.category;
    _notesCtrl.text = r.notes;
    _difficulty = r.difficulty;
    _editPortions = r.portions > 0 ? r.portions : 1;
    _editTags = List<String>.from(r.tags);
    _editIngredients = List<Ingredient>.from(r.ingredients);
    _editSteps = List<RecipeStep>.from(r.steps)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  void _enterEditMode() {
    _syncControllers();
    setState(() {
      _editMode = true;
      // Auto-open chat for new empty recipes
      if (widget.recipe.ingredients.isEmpty) _chatOpen = true;
    });
  }

  Future<void> _exitEditMode() async {
    await _saveNow();
    if (mounted) setState(() => _editMode = false);
  }

  void _scheduleAutoSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveNow);
    if (mounted) setState(() => _saveStatus = _SaveStatus.idle);
  }

  Future<void> _saveNow() async {
    _debounce?.cancel();
    setState(() => _saveStatus = _SaveStatus.saving);
    try {
      await ref.read(recipeDetailProvider(widget.id).notifier).save({
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'prep_time': _prepTimeCtrl.text,
        'cook_time': _cookTimeCtrl.text,
        'cuisine': _cuisineCtrl.text,
        'category': _categoryCtrl.text,
        'notes': _notesCtrl.text,
        'difficulty': _difficulty,
        'portions': _editPortions,
        'tags': _editTags,
        'ingredients': _editIngredients.map((e) => e.toJson()).toList(),
        'steps': _editSteps
            .asMap()
            .entries
            .map((e) => {...e.value.toJson(), 'order': e.key + 1})
            .toList(),
      });
      if (mounted) {
        setState(() => _saveStatus = _SaveStatus.saved);
        _savedFadeTimer?.cancel();
        _savedFadeTimer =
            Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saveStatus = _SaveStatus.idle);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _saveStatus = _SaveStatus.idle);
    }
  }

  // ──────────────────────────────────────────��──────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, _editMode ? 220 : 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _editMode ? _editSections(context) : _viewSections(context),
                  ),
                ),
              ),
            ],
          ),
          if (_editMode)
            _ChatPanel(
              open: _chatOpen,
              recipeId: widget.id,
              onClose: () => setState(() => _chatOpen = false),
            ),
        ],
      ),
      floatingActionButton: _editMode
          ? null
          : FloatingActionButton(
              onPressed: _enterEditMode,
              tooltip: 'Bearbeiten',
              child: const Icon(Icons.edit_outlined),
            ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    final recipe = widget.recipe;

    return SliverAppBar(
      expandedHeight:
          (!_editMode && recipe.imageUrl != null) ? 240 : 0,
      pinned: true,
      title: _editMode
          ? TextField(
              controller: _titleCtrl,
              onChanged: (_) => _scheduleAutoSave(),
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                hintText: 'Rezeptname',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
          : Text(
              recipe.hasTitle ? recipe.title : 'Neues Rezept',
              style: TextStyle(
                color: recipe.hasTitle
                    ? null
                    : Theme.of(context).disabledColor,
              ),
            ),
      actions: _editMode
          ? [
              if (_saveStatus == _SaveStatus.saving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_saveStatus == _SaveStatus.saved)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.check, color: Colors.green, size: 20),
                ),
              IconButton(
                icon: Icon(
                  _chatOpen
                      ? Icons.smart_toy
                      : Icons.smart_toy_outlined,
                  color: _chatOpen ? AppTheme.primary : null,
                ),
                tooltip: 'KI-Assistent',
                onPressed: () => setState(() => _chatOpen = !_chatOpen),
              ),
              IconButton(
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Speichern & Schließen',
                onPressed: _exitEditMode,
              ),
            ]
          : null,
      flexibleSpace: !_editMode && recipe.imageUrl != null
          ? FlexibleSpaceBar(
              background:
                  Image.network(recipe.imageUrl!, fit: BoxFit.cover),
            )
          : null,
    );
  }

  // ── View sections ──────────────────────────���─────────────────────���────────

  List<Widget> _viewSections(BuildContext context) {
    final recipe = widget.recipe;
    return [
      _viewMeta(context, recipe),
      if (recipe.tags.isNotEmpty) ...[
        const SizedBox(height: 12),
        _viewTags(recipe),
      ],
      const SizedBox(height: 24),
      if (recipe.ingredients.isNotEmpty) ...[
        _viewIngredients(context, recipe),
        const SizedBox(height: 24),
      ],
      if (recipe.steps.isNotEmpty) ...[
        _viewSteps(context, recipe),
        const SizedBox(height: 24),
      ],
      if (recipe.notes.isNotEmpty) ...[
        _viewNotes(context, recipe),
        const SizedBox(height: 24),
      ],
      if (recipe.ingredients.isEmpty &&
          recipe.steps.isEmpty &&
          recipe.description.isEmpty)
        _viewEmptyHint(context),
    ];
  }

  // ── Edit sections ───────────────────���─────────────────────────────────────

  List<Widget> _editSections(BuildContext context) {
    return [
      _editMetaFields(context),
      const SizedBox(height: 20),
      _editTagsSection(context),
      const SizedBox(height: 20),
      _editIngredientsSection(context),
      const SizedBox(height: 20),
      _editStepsSection(context),
      const SizedBox(height: 20),
      _editField(
        context,
        label: 'Notizen',
        controller: _notesCtrl,
        maxLines: 4,
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VIEW WIDGETS
  // ────────────────────────────────────────────────────────────��────────────

  Widget _viewMeta(BuildContext context, Recipe recipe) {
    final chips = <_MetaItem>[
      if (recipe.difficulty.isNotEmpty)
        _MetaItem(
          icon: Icons.signal_cellular_alt_outlined,
          label: recipe.difficulty,
          color: _difficultyColor(recipe.difficulty),
        ),
      if (recipe.prepTime.isNotEmpty)
        _MetaItem(
            icon: Icons.av_timer_outlined,
            label: 'Vorbereitung: ${recipe.prepTime}'),
      if (recipe.cookTime.isNotEmpty)
        _MetaItem(
            icon: Icons.local_fire_department_outlined,
            label: 'Kochen: ${recipe.cookTime}'),
      if (recipe.cuisine.isNotEmpty)
        _MetaItem(icon: Icons.public_outlined, label: recipe.cuisine),
      if (recipe.category.isNotEmpty)
        _MetaItem(
            icon: Icons.restaurant_menu_outlined, label: recipe.category),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recipe.description.isNotEmpty) ...[
          Text(recipe.description,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
        ],
        if (chips.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((i) => _MetaChip(item: i)).toList(),
          ),
      ],
    );
  }

  Widget _viewTags(Recipe recipe) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: recipe.tags
            .map((t) => Chip(
                  label: Text(t),
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ))
            .toList(),
      );

  Widget _viewIngredients(BuildContext context, Recipe recipe) {
    final grouped = <String, List<Ingredient>>{};
    for (final ing in recipe.ingredients) {
      grouped.putIfAbsent(ing.group ?? '', () => []).add(ing);
    }
    final hasGroups = grouped.keys.any((k) => k.isNotEmpty);
    final scale =
        recipe.portions > 0 ? _portions / recipe.portions : 1.0;

    String fmt(num amount) {
      final s = amount * scale;
      return s == s.roundToDouble()
          ? s.toInt().toString()
          : s.toStringAsFixed(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Zutaten',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            _PortionStepper(
              portions: _portions,
              onChanged: (v) => setState(() => _portions = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasGroups)
          ...grouped.entries.expand((e) => [
                if (e.key.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(e.key,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                ],
                ...e.value.map((ing) =>
                    _IngredientRow(ingredient: ing, formattedAmount: fmt(ing.amount))),
              ])
        else
          ...recipe.ingredients.map((ing) =>
              _IngredientRow(ingredient: ing, formattedAmount: fmt(ing.amount))),
      ],
    );
  }

  Widget _viewSteps(BuildContext context, Recipe recipe) {
    final sorted = [...recipe.steps]..sort((a, b) => a.order.compareTo(b.order));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zubereitung',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...sorted.asMap().entries.map(
            (e) => _StepCard(step: e.value, index: e.key)),
      ],
    );
  }

  Widget _viewNotes(BuildContext context, Recipe recipe) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notizen',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withAlpha(40)),
            ),
            child: Text(recipe.notes),
          ),
        ],
      );

  Widget _viewEmptyHint(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 48, color: AppTheme.primary.withAlpha(120)),
              const SizedBox(height: 12),
              Text(
                'Noch leer — tippe auf ✏️\num mit der KI loszulegen.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  // ────────────────────────���───────────────────────────────────────────���────
  // EDIT WIDGETS
  // ────────────────────────���────────────────────────────────��───────────────

  Widget _editMetaFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _editField(context, label: 'Beschreibung', controller: _descCtrl, maxLines: 3),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _editField(context, label: 'Vorbereitung', controller: _prepTimeCtrl, hint: 'z.B. 10 Min'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _editField(context, label: 'Kochen', controller: _cookTimeCtrl, hint: 'z.B. 20 Min'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _editField(context, label: 'Küche', controller: _cuisineCtrl, hint: 'z.B. Italienisch'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _editField(context, label: 'Kategorie', controller: _categoryCtrl, hint: 'z.B. Hauptgericht'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Schwierigkeit:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'einfach', label: Text('Einfach')),
                ButtonSegment(value: 'mittel', label: Text('Mittel')),
                ButtonSegment(value: 'schwer', label: Text('Schwer')),
              ],
              selected: {_difficulty},
              onSelectionChanged: (s) {
                setState(() => _difficulty = s.first);
                _scheduleAutoSave();
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Portionen:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 8),
            _PortionStepper(
              portions: _editPortions,
              onChanged: (v) {
                setState(() => _editPortions = v);
                _scheduleAutoSave();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _editTagsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ..._editTags.map((tag) => Chip(
                  label: Text(tag),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                  onDeleted: () {
                    setState(() => _editTags.remove(tag));
                    _scheduleAutoSave();
                  },
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Hinzufügen'),
              visualDensity: VisualDensity.compact,
              onPressed: () => _showTagDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _editIngredientsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zutaten', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._editIngredients.asMap().entries.map((e) => _EditIngredientRow(
              ingredient: e.value,
              onEdit: () => _showIngredientDialog(index: e.key),
              onDelete: () {
                setState(() => _editIngredients.removeAt(e.key));
                _scheduleAutoSave();
              },
            )),
        TextButton.icon(
          onPressed: () => _showIngredientDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Zutat hinzufügen'),
        ),
      ],
    );
  }

  Widget _editStepsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zubereitung', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._editSteps.asMap().entries.map((e) => _EditStepRow(
              step: e.value,
              index: e.key,
              onEdit: () => _showStepDialog(index: e.key),
              onDelete: () {
                setState(() => _editSteps.removeAt(e.key));
                _scheduleAutoSave();
              },
            )),
        TextButton.icon(
          onPressed: () => _showStepDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Schritt hinzufügen'),
        ),
      ],
    );
  }

  Widget _editField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => _scheduleAutoSave(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  // ── Dialogs ─────────────────────────────���─────────────────────────────────

  void _showTagDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tag hinzufügen'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'z.B. vegan'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              setState(() => _editTags.add(v.trim()));
              _scheduleAutoSave();
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _editTags.add(ctrl.text.trim()));
                _scheduleAutoSave();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _showIngredientDialog({int? index}) {
    final existing = index != null ? _editIngredients[index] : null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
        text: existing != null ? existing.amount.toString() : '');
    final groupCtrl = TextEditingController(text: existing?.group ?? '');
    String unit = existing?.unit ?? 'g';
    const units = ['g', 'ml', 'stk', 'EL', 'TL', 'Prise'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(index == null ? 'Zutat hinzufügen' : 'Zutat bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), autofocus: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Menge'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: unit,
                    items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setDlg(() => unit = v!),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: groupCtrl, decoration: const InputDecoration(labelText: 'Gruppe (optional)', hintText: 'z.B. Teig')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () {
                final ing = Ingredient(
                  name: nameCtrl.text.trim(),
                  amount: num.tryParse(amountCtrl.text) ?? 0,
                  unit: unit,
                  group: groupCtrl.text.trim().isEmpty ? null : groupCtrl.text.trim(),
                );
                setState(() {
                  if (index != null) {
                    _editIngredients[index] = ing;
                  } else {
                    _editIngredients.add(ing);
                  }
                });
                _scheduleAutoSave();
                Navigator.pop(ctx);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStepDialog({int? index}) {
    final existing = index != null ? _editSteps[index] : null;
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final durCtrl = TextEditingController(
        text: existing?.durationMin?.toString() ?? '');
    final tipCtrl = TextEditingController(text: existing?.tip ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? 'Schritt hinzufügen' : 'Schritt bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durCtrl,
              decoration: const InputDecoration(labelText: 'Dauer in Min (optional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tipCtrl,
              decoration: const InputDecoration(labelText: 'Tipp (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              final step = RecipeStep(
                order: (index ?? _editSteps.length) + 1,
                description: descCtrl.text.trim(),
                durationMin: int.tryParse(durCtrl.text),
                tip: tipCtrl.text.trim().isEmpty ? null : tipCtrl.text.trim(),
              );
              setState(() {
                if (index != null) {
                  _editSteps[index] = step;
                } else {
                  _editSteps.add(step);
                }
              });
              _scheduleAutoSave();
              Navigator.pop(ctx);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────���───────────────────────────────���───────

  Color _difficultyColor(String d) {
    switch (d) {
      case 'einfach': return Colors.green;
      case 'mittel':  return Colors.orange;
      case 'schwer':  return Colors.red;
      default:        return AppTheme.textSecondary;
    }
  }
}

// ─── Reusable sub-widgets ──────────────────────────────────────────────────────

class _MetaItem {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaItem({required this.icon, required this.label, this.color});
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.item});
  final _MetaItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(item.label,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PortionStepper extends StatelessWidget {
  const _PortionStepper({required this.portions, required this.onChanged});
  final int portions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: portions > 1 ? () => onChanged(portions - 1) : null,
          visualDensity: VisualDensity.compact,
          color: AppTheme.primary,
        ),
        Text('$portions Portion${portions != 1 ? 'en' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(portions + 1),
          visualDensity: VisualDensity.compact,
          color: AppTheme.primary,
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, required this.formattedAmount});
  final Ingredient ingredient;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text('$formattedAmount ${ingredient.unit}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Expanded(child: Text(ingredient.name, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class _EditIngredientRow extends StatelessWidget {
  const _EditIngredientRow({
    required this.ingredient,
    required this.onEdit,
    required this.onDelete,
  });
  final Ingredient ingredient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onTap: onEdit,
      title: Text(ingredient.name),
      subtitle: Text('${ingredient.amount} ${ingredient.unit}'
          '${ingredient.group != null ? " · ${ingredient.group}" : ""}',
          style: const TextStyle(fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
        color: AppTheme.error,
      ),
    );
  }
}

class _EditStepRow extends StatelessWidget {
  const _EditStepRow({
    required this.step,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });
  final RecipeStep step;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onTap: onEdit,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: AppTheme.primary,
        child: Text('${index + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
      title: Text(
        step.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
        color: AppTheme.error,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.index});
  final RecipeStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step.durationMin != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text('${step.durationMin} Min',
                            style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                Text(step.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                if (step.tip != null && step.tip!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withAlpha(80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 15, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(step.tip!,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade800)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat side panel ───────────────────────────────────────────────────────────

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.open,
    required this.recipeId,
    required this.onClose,
  });

  final bool open;
  final String recipeId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth < 500 ? screenWidth : 360.0;
    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      right: open ? 0 : -(panelWidth + 8),
      top: topPad,
      bottom: 0,
      width: panelWidth,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ChatSheet(
          recipeId: recipeId,
          onProposalAccepted: () {},
          onClose: onClose,
        ),
      ),
    );
  }
}
