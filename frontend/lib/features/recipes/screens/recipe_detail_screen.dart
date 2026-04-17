import 'dart:async';

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/config_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/content_constraint.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_detail_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat/chat_sheet.dart';
import '../widgets/detail/detail_meta_chip.dart';
import '../widgets/detail/ingredient_row.dart';
import '../widgets/detail/portion_stepper.dart';
import '../widgets/detail/step_card.dart';
import '../widgets/edit/dashed_border_painter.dart';
import '../widgets/edit/difficulty_chip.dart';
import '../widgets/edit/editable_chip_field.dart';
import '../widgets/edit/inline_ingredient_tile.dart';
import '../widgets/edit/inline_step_tile.dart';
import '../widgets/edit/inline_tag_input.dart';
import '../widgets/edit/inline_text_field.dart';

// ─── Save status ───────────────────────────────────────────────────────────────

enum _SaveStatus { idle, saving, saved }

// ─── Screen ────────────────────────────────────────────────────────────────────

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
      data: (recipe) => _RecipeView(
        recipe: recipe,
        id: id,
        initialEditMode: !recipe.hasTitle,
      ),
    );
  }
}

// ─── Main stateful view ────────────────────────────────────────────────────────

class _RecipeView extends ConsumerStatefulWidget {
  const _RecipeView({required this.recipe, required this.id, this.initialEditMode = false});
  final Recipe recipe;
  final bool initialEditMode;
  final String id;

  @override
  ConsumerState<_RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends ConsumerState<_RecipeView> {
  bool _editMode = false;
  late int _portions;

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

  _SaveStatus _saveStatus = _SaveStatus.idle;
  Timer? _debounce;
  Timer? _savedFadeTimer;

  bool _chatOpen = false;

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
    if (widget.initialEditMode) {
      _syncControllers();
      _editMode = true;
      _chatOpen = true;
    }
  }

  @override
  void didUpdateWidget(_RecipeView old) {
    super.didUpdateWidget(old);
    if (!_editMode) {
      _portions = widget.recipe.portions > 0 ? widget.recipe.portions : 1;
    }
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
      if (widget.recipe.ingredients.isEmpty) _chatOpen = true;
    });
  }

  Future<void> _exitEditMode() async {
    await _saveNow();
    if (!mounted) return;
    final r = ref.read(recipeDetailProvider(widget.id)).valueOrNull;
    final isEmpty = r != null &&
        !r.hasTitle &&
        r.ingredients.isEmpty &&
        r.steps.isEmpty;
    if (isEmpty) {
      context.pop();
    } else {
      setState(() => _editMode = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      Uint8List? bytes;
      String mime = 'image/jpeg';

      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final f = result.files.first;
        bytes = f.bytes;
        if (f.extension != null) mime = 'image/${f.extension!.toLowerCase()}';
      } else {
        final source = await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galerie'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
        if (source == null || !mounted) return;
        final file = await ImagePicker().pickImage(
            source: source, imageQuality: 80, maxWidth: 1200);
        if (file == null) return;
        bytes = await file.readAsBytes();
        mime = file.mimeType ?? 'image/jpeg';
      }

      if (bytes == null || !mounted) return;
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      await ref.read(recipeDetailProvider(widget.id).notifier).uploadImage(dataUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bild-Upload fehlgeschlagen: $e')),
      );
    }
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
        _savedFadeTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saveStatus = _SaveStatus.idle);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _saveStatus = _SaveStatus.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
                      _editMode
                          ? _editSections(context)
                          : _viewSections(context),
                    ),
                  ),
                ),
              ],
            ),
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
            if (_editMode && !keyboardOpen)
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
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () =>
                                setState(() => _chatOpen = !_chatOpen),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: _chatOpen
                                    ? AppTheme.primaryLight
                                        .withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/remy_icon.svg',
                                    height: 20,
                                    colorFilter: ColorFilter.mode(
                                      _chatOpen
                                          ? AppTheme.primaryLight
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remy',
                                    style: TextStyle(
                                      color: _chatOpen
                                          ? AppTheme.primaryLight
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(50),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: _exitEditMode,
                            splashColor: Colors.white24,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded,
                                      size: 18, color: Colors.white),
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

  Widget _buildAppBar(BuildContext context) {
    final recipe = widget.recipe;

    return SliverAppBar(
      expandedHeight: (!_editMode && recipe.imageUrl != null) ? 240 : 0,
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
                      hintStyle:
                          TextStyle(color: Theme.of(context).disabledColor),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: DashedBorderPainter(
                          color: AppTheme.primary.withAlpha(55)),
                    ),
                  ),
                ),
              ],
            )
          : Text(
              recipe.hasTitle ? recipe.title : 'Neues Rezept',
              style: TextStyle(
                color: recipe.hasTitle ? null : Theme.of(context).disabledColor,
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
              background: Image.network(recipe.imageUrl!, fit: BoxFit.cover),
            )
          : null,
    );
  }

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

  List<Widget> _editSections(BuildContext context) {
    return [
      _editImageSection(context),
      const SizedBox(height: 16),
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

  Widget _viewMeta(BuildContext context, Recipe recipe) {
    final chips = <DetailMetaItem>[
      if (recipe.difficulty.isNotEmpty)
        DetailMetaItem(
          icon: Icons.signal_cellular_alt_outlined,
          label: recipe.difficulty,
          color: _difficultyColor(recipe.difficulty),
        ),
      if (recipe.prepTime.isNotEmpty)
        DetailMetaItem(
            icon: Icons.av_timer_outlined,
            label: 'Vorbereitung: ${recipe.prepTime}'),
      if (recipe.cookTime.isNotEmpty)
        DetailMetaItem(
            icon: Icons.local_fire_department_outlined,
            label: 'Kochen: ${recipe.cookTime}'),
      if (recipe.cuisine.isNotEmpty)
        DetailMetaItem(icon: Icons.public_outlined, label: recipe.cuisine),
      if (recipe.category.isNotEmpty)
        DetailMetaItem(
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
            children: chips.map((i) => DetailMetaChip(item: i)).toList(),
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
    final scale = recipe.portions > 0 ? _portions / recipe.portions : 1.0;

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
            PortionStepper(
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                ],
                ...e.value.map((ing) => IngredientRow(
                    ingredient: ing, formattedAmount: fmt(ing.amount))),
              ])
        else
          ...recipe.ingredients.map((ing) =>
              IngredientRow(ingredient: ing, formattedAmount: fmt(ing.amount))),
      ],
    );
  }

  Widget _viewSteps(BuildContext context, Recipe recipe) {
    final sorted = [...recipe.steps]
      ..sort((a, b) => a.order.compareTo(b.order));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zubereitung',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...sorted.asMap().entries.map((e) => StepCard(step: e.value, index: e.key)),
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

  Widget _viewEmptyHint(BuildContext context) {
    final strings = ref.watch(appConfigProvider).strings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48, color: AppTheme.primary.withAlpha(120)),
            const SizedBox(height: 12),
            Text(
              strings.recipeEmptyHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _editImageSection(BuildContext context) {
    final imageUrl = widget.recipe.imageUrl;
    return GestureDetector(
      onTap: _pickImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => _imagePlaceholder(context))
              else
                _imagePlaceholder(context),
              Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      imageUrl != null
                          ? Icons.edit_outlined
                          : Icons.add_photo_alternate_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      imageUrl != null ? 'Bild ändern' : 'Bild hinzufügen',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withAlpha(50),
              AppTheme.primaryLight.withAlpha(30),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(Icons.restaurant, size: 48, color: AppTheme.primary.withAlpha(80)),
      );

  Widget _editMeta(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InlineTextField(
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
            DifficultyChip(
              value: _difficulty,
              onChanged: (v) {
                setState(() => _difficulty = v);
                _scheduleAutoSave();
              },
            ),
            EditableChipField(
              icon: Icons.av_timer_outlined,
              controller: _prepTimeCtrl,
              hint: 'Vorb.',
              onChanged: _scheduleAutoSave,
            ),
            EditableChipField(
              icon: Icons.local_fire_department_outlined,
              controller: _cookTimeCtrl,
              hint: 'Koch',
              onChanged: _scheduleAutoSave,
            ),
            EditableChipField(
              icon: Icons.public_outlined,
              controller: _cuisineCtrl,
              hint: 'Küche',
              onChanged: _scheduleAutoSave,
            ),
            EditableChipField(
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
            PortionStepper(
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
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
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
                  painter: DashedBorderPainter(
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
        Text('Tags',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
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
            InlineTagInput(
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
        Text('Zutaten',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._editIngredients.asMap().entries.map((e) => InlineIngredientTile(
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
            setState(() => _editIngredients
                .add(const Ingredient(name: '', amount: 0, unit: 'g')));
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
        Text('Zubereitung',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._editSteps.asMap().entries.map((e) => InlineStepTile(
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
            setState(() => _editSteps.add(
                RecipeStep(order: _editSteps.length + 1, description: '')));
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Schritt hinzufügen'),
        ),
      ],
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'einfach':
        return Colors.green;
      case 'mittel':
        return Colors.orange;
      case 'schwer':
        return Colors.red;
      default:
        return AppTheme.textSecondary;
    }
  }
}

// ─── Chat side panel ───────────────────────────────────────────────────────────

class _ChatPanel extends ConsumerWidget {
  const _ChatPanel({
    required this.open,
    required this.recipeId,
    required this.onClose,
  });

  final bool open;
  final String recipeId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = MediaQuery.of(context).size;
    final isMobile = screen.width < 600;

    if (isMobile) {
      final hasMessages = ref
          .watch(chatNotifierProvider(recipeId))
          .valueOrNull
          ?.isNotEmpty ?? false;
      final panelHeight = hasMessages
          ? (screen.height * 0.5).clamp(200.0, 480.0)
          : (screen.height * 0.75).clamp(300.0, 680.0);
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 320),
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
