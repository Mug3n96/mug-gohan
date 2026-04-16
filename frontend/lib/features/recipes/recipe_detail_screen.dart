import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/content_constraint.dart';
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
      body: ContentConstraint(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _editMode ? _editSections(context) : _viewSections(context),
                    ),
                  ),
                ),
              ],
            ),
            // View mode FAB
            if (!_editMode)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: _enterEditMode,
                  tooltip: 'Bearbeiten',
                  child: const Icon(Icons.edit_outlined),
                ),
              ),
            // Edit mode: pill button group
            if (_editMode)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // KI Hilfe – ghost/tonal
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () => setState(() => _chatOpen = !_chatOpen),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: _chatOpen
                                    ? AppTheme.primaryLight.withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _chatOpen ? Icons.smart_toy : Icons.smart_toy_outlined,
                                    size: 18,
                                    color: _chatOpen
                                        ? AppTheme.primaryLight
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'KI Hilfe',
                                    style: TextStyle(
                                      color: _chatOpen
                                          ? AppTheme.primaryLight
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Übernehmen – filled mint
                        Material(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(50),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: _exitEditMode,
                            splashColor: Colors.white24,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Übernehmen',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_editMode)
              _ChatPanel(
                open: _chatOpen,
                recipeId: widget.id,
                onClose: () => setState(() => _chatOpen = false),
              ),
          ],
        ),
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
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _editMode
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Fertig',
              onPressed: _exitEditMode,
            )
          : null,
      title: _editMode
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: _titleCtrl,
                    onChanged: (_) => _scheduleAutoSave(),
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(
                      hintText: 'Rezeptname',
                      hintStyle: TextStyle(color: Theme.of(context).disabledColor),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _DashedBorderPainter(color: AppTheme.primary.withAlpha(55)),
                    ),
                  ),
                ),
              ],
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
      _editMeta(context),
      const SizedBox(height: 12),
      _editTagsSection(context),
      const SizedBox(height: 24),
      _editIngredientsSection(context),
      const SizedBox(height: 24),
      _editStepsSection(context),
      const SizedBox(height: 24),
      _editNotesSection(context),
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

  // Notion-style: same layout as view, text becomes editable in place
  Widget _editMeta(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineTextField(
          controller: _descCtrl,
          style: Theme.of(context).textTheme.bodyLarge,
          hint: 'Beschreibung hinzufügen...',
          maxLines: null,
          onChanged: _scheduleAutoSave,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DifficultyChip(
              value: _difficulty,
              onChanged: (v) {
                setState(() => _difficulty = v);
                _scheduleAutoSave();
              },
            ),
            _EditableChipField(
              icon: Icons.av_timer_outlined,
              controller: _prepTimeCtrl,
              hint: 'Vorb.',
              onChanged: _scheduleAutoSave,
            ),
            _EditableChipField(
              icon: Icons.local_fire_department_outlined,
              controller: _cookTimeCtrl,
              hint: 'Koch',
              onChanged: _scheduleAutoSave,
            ),
            _EditableChipField(
              icon: Icons.public_outlined,
              controller: _cuisineCtrl,
              hint: 'Küche',
              onChanged: _scheduleAutoSave,
            ),
            _EditableChipField(
              icon: Icons.restaurant_menu_outlined,
              controller: _categoryCtrl,
              hint: 'Kategorie',
              onChanged: _scheduleAutoSave,
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

  Widget _editNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notizen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _notesCtrl,
                maxLines: null,
                onChanged: (_) => _scheduleAutoSave(),
                decoration: InputDecoration(
                  hintText: 'Notizen hinzufügen...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(140),
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: true,
                  fillColor: AppTheme.primary.withAlpha(15),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: AppTheme.primary.withAlpha(60),
                    radius: 12,
                  ),
                ),
              ),
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
            _InlineTagInput(
              onAdd: (tag) {
                setState(() => _editTags.add(tag));
                _scheduleAutoSave();
              },
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
        ..._editIngredients.asMap().entries.map((e) => _InlineIngredientTile(
              key: ValueKey('ing-${e.key}'),
              ingredient: e.value,
              onChanged: (updated) {
                setState(() => _editIngredients[e.key] = updated);
                _scheduleAutoSave();
              },
              onDelete: () {
                setState(() => _editIngredients.removeAt(e.key));
                _scheduleAutoSave();
              },
            )),
        TextButton.icon(
          onPressed: () {
            setState(() => _editIngredients.add(const Ingredient(name: '', amount: 0, unit: 'g')));
          },
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
        ..._editSteps.asMap().entries.map((e) => _InlineStepTile(
              key: ValueKey('step-${e.key}'),
              step: e.value,
              index: e.key,
              onChanged: (updated) {
                setState(() => _editSteps[e.key] = updated);
                _scheduleAutoSave();
              },
              onDelete: () {
                setState(() => _editSteps.removeAt(e.key));
                _scheduleAutoSave();
              },
            )),
        TextButton.icon(
          onPressed: () {
            setState(() => _editSteps.add(RecipeStep(order: _editSteps.length + 1, description: '')));
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Schritt hinzufügen'),
        ),
      ],
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

// ─── Dashed border painter ────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, this.radius = 8.0});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
        Radius.circular(radius),
      ));

    const dashLen = 7.0;
    const gapLen = 4.0;
    bool draw = true;
    for (final metric in path.computeMetrics()) {
      double pos = 0;
      while (pos < metric.length) {
        final end = (pos + (draw ? dashLen : gapLen)).clamp(0.0, metric.length);
        if (draw) canvas.drawPath(metric.extractPath(pos, end), paint);
        pos = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
  @override
  bool operator ==(Object other) => other is _DashedBorderPainter && other.color == color && other.radius == radius;
  @override
  int get hashCode => Object.hash(color, radius);
}

// ─── Shake wrapper ─────────────────────────────────────────────────────────────

class _ShakeWrapper extends StatefulWidget {
  const _ShakeWrapper({required this.child});
  final Widget child;

  @override
  _ShakeWrapperState createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<_ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shake;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 2.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 2.5, end: -2.5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2.5, end: 2.5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 2.5, end: 0.0), weight: 1),
    ]).animate(_ctrl);
    _timer = Timer(const Duration(seconds: 2), _doShake);
  }

  void _doShake() {
    if (!mounted) return;
    _ctrl.forward(from: 0);
    _timer = Timer(const Duration(seconds: 9), _doShake);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shake.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─── Inline ingredient tile ────────────────────────────────────────────────────

class _InlineIngredientTile extends StatefulWidget {
  const _InlineIngredientTile({
    super.key,
    required this.ingredient,
    required this.onChanged,
    required this.onDelete,
  });
  final Ingredient ingredient;
  final ValueChanged<Ingredient> onChanged;
  final VoidCallback onDelete;

  @override
  State<_InlineIngredientTile> createState() => _InlineIngredientTileState();
}

class _InlineIngredientTileState extends State<_InlineIngredientTile> {
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
    _amount = TextEditingController(text: i.amount == 0 ? '' : i.amount.toString());
    _group = TextEditingController(text: i.group ?? '');
    _unit = i.unit.isEmpty ? 'g' : i.unit;
    _groupFocus = FocusNode()
      ..addListener(() => setState(() => _groupFocused = _groupFocus.hasFocus));
  }

  @override
  void didUpdateWidget(_InlineIngredientTile old) {
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
                width: 6, height: 6,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                child: _InlineTextField(
                  controller: _amount,
                  onChanged: _notify,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  hint: '0',
                ),
              ),
              const SizedBox(width: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _unit,
                  isDense: true,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) {
                    setState(() => _unit = v!);
                    _notify();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InlineTextField(
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
                child: _InlineTextField(
                  controller: _group,
                  focusNode: _groupFocus,
                  onChanged: _notify,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  hint: 'Gruppe (z.B. Teig, Sauce)',
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                setState(() => _groupFocused = true);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _groupFocus.requestFocus(),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 30, top: 3, bottom: 2),
                child: Text(
                  '+ Gruppe',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withAlpha(100)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Inline step tile ──────────────────────────────────────────────────────────

class _InlineStepTile extends StatefulWidget {
  const _InlineStepTile({
    super.key,
    required this.step,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });
  final RecipeStep step;
  final int index;
  final ValueChanged<RecipeStep> onChanged;
  final VoidCallback onDelete;

  @override
  State<_InlineStepTile> createState() => _InlineStepTileState();
}

class _InlineStepTileState extends State<_InlineStepTile> {
  late TextEditingController _desc;
  late TextEditingController _duration;
  late TextEditingController _tip;

  @override
  void initState() {
    super.initState();
    final s = widget.step;
    _desc = TextEditingController(text: s.description);
    _duration = TextEditingController(text: s.durationMin?.toString() ?? '');
    _tip = TextEditingController(text: s.tip ?? '');
  }

  @override
  void didUpdateWidget(_InlineStepTile old) {
    super.didUpdateWidget(old);
    final s = widget.step;
    if (_desc.text != s.description) _desc.text = s.description;
    final dur = s.durationMin?.toString() ?? '';
    if (_duration.text != dur) _duration.text = dur;
    final tip = s.tip ?? '';
    if (_tip.text != tip) _tip.text = tip;
  }

  @override
  void dispose() {
    _desc.dispose();
    _duration.dispose();
    _tip.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(RecipeStep(
        order: widget.step.order,
        description: _desc.text,
        durationMin: int.tryParse(_duration.text),
        tip: _tip.text.trim().isEmpty ? null : _tip.text.trim(),
      ));

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
              child: Text('${widget.index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 3),
                    SizedBox(
                      width: 44,
                      child: _InlineTextField(
                        controller: _duration,
                        onChanged: _notify,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
                        hint: '0',
                      ),
                    ),
                    Text(' Min', style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: widget.onDelete,
                      color: AppTheme.textSecondary.withAlpha(140),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _InlineTextField(
                  controller: _desc,
                  onChanged: _notify,
                  maxLines: null,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                  hint: 'Schritt beschreiben...',
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TextField(
                        controller: _tip,
                        onChanged: (_) => _notify(),
                        maxLines: null,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade800),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lightbulb_outline, size: 15, color: Colors.amber),
                          prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 0),
                          hintText: 'Tipp hinzufügen...',
                          hintStyle: TextStyle(
                            fontSize: theme.textTheme.bodySmall?.fontSize,
                            color: Colors.amber.withAlpha(150),
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: true,
                          fillColor: Colors.amber.withAlpha(30),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _DashedBorderPainter(
                            color: Colors.amber.withAlpha(100),
                            radius: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

// ─── Inline text field (transparent + dashed border hint) ─────────────────────

class _InlineTextField extends StatelessWidget {
  const _InlineTextField({
    required this.controller,
    required this.onChanged,
    this.style,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.focusNode,
  });
  final TextEditingController controller;
  final VoidCallback onChanged;
  final TextStyle? style;
  final String? hint;
  final int? maxLines;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: style,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withAlpha(140),
                fontStyle: FontStyle.italic,
                fontSize: style?.fontSize,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DashedBorderPainter(color: AppTheme.primary.withAlpha(55)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Editable chip field (chip-shaped container with inline text input) ────────

class _EditableChipField extends StatefulWidget {
  const _EditableChipField({
    required this.icon,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  State<_EditableChipField> createState() => _EditableChipFieldState();
}

class _EditableChipFieldState extends State<_EditableChipField> {
  final _focus = FocusNode();
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _active = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = _focus.hasFocus),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: _active
                  ? AppTheme.textSecondary.withAlpha(35)
                  : AppTheme.textSecondary.withAlpha(15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  IntrinsicWidth(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      onChanged: (_) => widget.onChanged(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary.withAlpha(150),
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: AppTheme.primary.withAlpha(60),
                  radius: 100,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Inline tag input chip ─────────────────────────────────────────────────────

class _InlineTagInput extends StatefulWidget {
  const _InlineTagInput({required this.onAdd});
  final ValueChanged<String> onAdd;

  @override
  State<_InlineTagInput> createState() => _InlineTagInputState();
}

class _InlineTagInputState extends State<_InlineTagInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _active = _focus.hasFocus));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final tag = _ctrl.text.trim();
    if (tag.isNotEmpty) {
      widget.onAdd(tag);
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = _focus.hasFocus),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: _active
                  ? AppTheme.textSecondary.withAlpha(35)
                  : AppTheme.textSecondary.withAlpha(15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: const TextStyle(fontSize: 13),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Tag hinzufügen...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary.withAlpha(150),
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: AppTheme.primary.withAlpha(60),
                  radius: 100,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Difficulty chip (cycles einfach → mittel → schwer) ───────────────────────

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const _values = ['einfach', 'mittel', 'schwer'];

  Color _color() {
    switch (value) {
      case 'einfach': return Colors.green;
      case 'mittel':  return Colors.orange;
      case 'schwer':  return Colors.red;
      default:        return AppTheme.textSecondary;
    }
  }

  void _cycle() {
    final i = _values.indexOf(value);
    onChanged(_values[(i + 1) % _values.length]);
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return GestureDetector(
      onTap: _cycle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.withAlpha(25),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: c.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_cellular_alt_outlined, size: 14, color: c),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.unfold_more, size: 13, color: c.withAlpha(180)),
          ],
        ),
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
    final screen = MediaQuery.of(context).size;
    final isMobile = screen.width < 600;

    if (isMobile) {
      final panelHeight = (screen.height * 0.5).clamp(200.0, 480.0);
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        left: 12,
        right: 12,
        bottom: open ? 8 : -(panelHeight + 16),
        height: panelHeight,
        child: ChatSheet(
          recipeId: recipeId,
          onProposalAccepted: () {},
          onClose: onClose,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      );
    }

    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      right: open ? 0 : -368,
      top: topPad,
      bottom: 0,
      width: 360,
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
