import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/content_constraint.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_detail_provider.dart';
import '../providers/recipes_provider.dart';
import '../widgets/detail/recipe_chat_panel.dart';
import '../widgets/detail/recipe_view_content.dart';
import '../widgets/edit/dashed_border_painter.dart';
import '../widgets/edit/image_pick_helper.dart';
import '../widgets/edit/recipe_edit_content.dart';

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
  const _RecipeView({
    required this.recipe,
    required this.id,
    this.initialEditMode = false,
  });
  final Recipe recipe;
  final bool initialEditMode;
  final String id;

  @override
  ConsumerState<_RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends ConsumerState<_RecipeView> {
  bool _editMode = false;

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
    final isEmpty =
        r != null && !r.hasTitle && r.ingredients.isEmpty && r.steps.isEmpty;
    if (isEmpty) {
      context.pop();
    } else {
      setState(() => _editMode = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final dataUrl = await pickRecipeImage(context);
      if (dataUrl == null || !mounted) return;
      await ref
          .read(recipeDetailProvider(widget.id).notifier)
          .uploadImage(dataUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bild-Upload fehlgeschlagen: $e')));
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

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.invalidate(recipeListNotifierProvider);
      },
      child: Scaffold(
        body: ContentConstraint(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: _editMode
                      ? RecipeEditContent(
                          recipe: widget.recipe,
                          descCtrl: _descCtrl,
                          prepTimeCtrl: _prepTimeCtrl,
                          cookTimeCtrl: _cookTimeCtrl,
                          cuisineCtrl: _cuisineCtrl,
                          categoryCtrl: _categoryCtrl,
                          notesCtrl: _notesCtrl,
                          difficulty: _difficulty,
                          editPortions: _editPortions,
                          editTags: _editTags,
                          editIngredients: _editIngredients,
                          editSteps: _editSteps,
                          onDifficultyChanged: (v) {
                            setState(() => _difficulty = v);
                            _scheduleAutoSave();
                          },
                          onPortionsChanged: (v) {
                            setState(() => _editPortions = v);
                            _scheduleAutoSave();
                          },
                          onTagAdded: (tag) {
                            setState(() => _editTags.add(tag));
                            _scheduleAutoSave();
                          },
                          onTagRemoved: (tag) {
                            setState(() => _editTags.remove(tag));
                            _scheduleAutoSave();
                          },
                          onIngredientChanged: (i, updated) {
                            setState(() => _editIngredients[i] = updated);
                            _scheduleAutoSave();
                          },
                          onIngredientAdded: () {
                            setState(
                              () => _editIngredients.add(
                                const Ingredient(
                                  name: '',
                                  amount: 0,
                                  unit: 'g',
                                ),
                              ),
                            );
                          },
                          onIngredientDeleted: (i) {
                            setState(() => _editIngredients.removeAt(i));
                            _scheduleAutoSave();
                          },
                          onStepChanged: (i, updated) {
                            setState(() => _editSteps[i] = updated);
                            _scheduleAutoSave();
                          },
                          onStepAdded: () {
                            setState(
                              () => _editSteps.add(
                                RecipeStep(
                                  order: _editSteps.length + 1,
                                  description: '',
                                ),
                              ),
                            );
                          },
                          onStepDeleted: (i) {
                            setState(() => _editSteps.removeAt(i));
                            _scheduleAutoSave();
                          },
                          onFieldChanged: _scheduleAutoSave,
                          onPickImage: _pickImage,
                        )
                      : RecipeViewContent(recipe: widget.recipe),
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
            if (_editMode && !keyboardOpen) _buildBottomBar(context),
            if (_editMode)
              RecipeChatPanel(
                open: _chatOpen,
                recipeId: widget.id,
                onClose: () => setState(() => _chatOpen = false),
              ),
          ],
        ),
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
                      hintStyle: TextStyle(
                        color: Theme.of(context).disabledColor,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: DashedBorderPainter(
                        color: AppTheme.primary.withAlpha(55),
                      ),
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

  Widget _buildBottomBar(BuildContext context) {
    return Positioned(
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
                  onTap: () => setState(() => _chatOpen = !_chatOpen),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _chatOpen
                          ? AppTheme.primaryLight.withValues(alpha: 0.18)
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
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remy',
                          style: TextStyle(
                            color: _chatOpen
                                ? AppTheme.primaryLight
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
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
    );
  }
}
