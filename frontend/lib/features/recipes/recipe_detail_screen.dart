import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'recipe_detail_provider.dart';
import 'recipe_model.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(id));

    return recipeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Fehler: $e')),
      ),
      data: (recipe) => _RecipeView(recipe: recipe, id: id),
    );
  }
}

class _RecipeView extends ConsumerStatefulWidget {
  const _RecipeView({required this.recipe, required this.id});

  final Recipe recipe;
  final String id;

  @override
  ConsumerState<_RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends ConsumerState<_RecipeView> {
  late int _portions;

  @override
  void initState() {
    super.initState();
    _portions = widget.recipe.portions > 0 ? widget.recipe.portions : 1;
  }

  @override
  void didUpdateWidget(_RecipeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe.portions != widget.recipe.portions) {
      _portions = widget.recipe.portions > 0 ? widget.recipe.portions : 1;
    }
  }

  double get _scale =>
      widget.recipe.portions > 0 ? _portions / widget.recipe.portions : 1.0;

  String _formatAmount(num amount) {
    final scaled = amount * _scale;
    if (scaled == scaled.roundToDouble()) return scaled.toInt().toString();
    return scaled.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, recipe),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMeta(context, recipe),
                if (recipe.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildTags(recipe),
                ],
                const SizedBox(height: 24),
                if (recipe.ingredients.isNotEmpty) ...[
                  _buildIngredientsSection(context, recipe),
                  const SizedBox(height: 24),
                ],
                if (recipe.steps.isNotEmpty) ...[
                  _buildStepsSection(context, recipe, theme),
                  const SizedBox(height: 24),
                ],
                if (recipe.notes.isNotEmpty) ...[
                  _buildNotesSection(context, recipe),
                  const SizedBox(height: 24),
                ],
                if (recipe.ingredients.isEmpty &&
                    recipe.steps.isEmpty &&
                    recipe.description.isEmpty)
                  _buildEmptyHint(context),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // F8: edit mode — coming soon
        },
        tooltip: 'Bearbeiten',
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Recipe recipe) {
    return SliverAppBar(
      expandedHeight: recipe.imageUrl != null ? 240 : 0,
      pinned: true,
      title: Text(
        recipe.hasTitle ? recipe.title : 'Neues Rezept',
        style: TextStyle(
          color: recipe.hasTitle ? null : Theme.of(context).disabledColor,
        ),
      ),
      flexibleSpace: recipe.imageUrl != null
          ? FlexibleSpaceBar(
              background: Image.network(
                recipe.imageUrl!,
                fit: BoxFit.cover,
              ),
            )
          : null,
    );
  }

  Widget _buildMeta(BuildContext context, Recipe recipe) {
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
            children: chips.map((item) => _MetaChip(item: item)).toList(),
          ),
      ],
    );
  }

  Widget _buildTags(Recipe recipe) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: recipe.tags
          .map((tag) => Chip(
                label: Text(tag),
                labelStyle: const TextStyle(fontSize: 12),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ))
          .toList(),
    );
  }

  Widget _buildIngredientsSection(BuildContext context, Recipe recipe) {
    final grouped = <String, List<Ingredient>>{};
    for (final ing in recipe.ingredients) {
      final group = ing.group ?? '';
      grouped.putIfAbsent(group, () => []).add(ing);
    }
    final hasGroups = grouped.keys.any((k) => k.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Zutaten',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            _PortionStepper(
              portions: _portions,
              onChanged: (v) => setState(() => _portions = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasGroups)
          ...grouped.entries.expand((entry) => [
                if (entry.key.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                ],
                ...entry.value.map((ing) => _IngredientRow(
                      ingredient: ing,
                      formattedAmount: _formatAmount(ing.amount),
                    )),
              ])
        else
          ...recipe.ingredients.map((ing) => _IngredientRow(
                ingredient: ing,
                formattedAmount: _formatAmount(ing.amount),
              )),
      ],
    );
  }

  Widget _buildStepsSection(
      BuildContext context, Recipe recipe, ThemeData theme) {
    final sorted = [...recipe.steps]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zubereitung',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...sorted
            .asMap()
            .entries
            .map((entry) => _StepCard(step: entry.value, index: entry.key)),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notizen',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
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
  }

  Widget _buildEmptyHint(BuildContext context) {
    return Center(
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

// --- Sub-widgets ---

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
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500)),
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
        Text(
          '$portions Portion${portions != 1 ? 'en' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
  const _IngredientRow(
      {required this.ingredient, required this.formattedAmount});
  final Ingredient ingredient;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$formattedAmount ${ingredient.unit}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(ingredient.name,
                style: const TextStyle(fontSize: 15)),
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
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
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
                        const Icon(Icons.timer_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${step.durationMin} Min',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                Text(step.description,
                    style:
                        const TextStyle(fontSize: 15, height: 1.5)),
                if (step.tip != null && step.tip!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.amber.withAlpha(80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 15, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            step.tip!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade800),
                          ),
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
