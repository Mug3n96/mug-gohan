import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/config_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';
import '../shared/difficulty_utils.dart';
import 'detail_meta_chip.dart';
import 'ingredient_row.dart';
import 'portion_stepper.dart';
import 'step_card.dart';

class RecipeViewContent extends ConsumerStatefulWidget {
  const RecipeViewContent({super.key, required this.recipe});
  final Recipe recipe;

  @override
  ConsumerState<RecipeViewContent> createState() => _RecipeViewContentState();
}

class _RecipeViewContentState extends ConsumerState<RecipeViewContent> {
  late int _portions;

  @override
  void initState() {
    super.initState();
    _portions = widget.recipe.portions > 0 ? widget.recipe.portions : 1;
  }

  @override
  void didUpdateWidget(RecipeViewContent old) {
    super.didUpdateWidget(old);
    _portions = widget.recipe.portions > 0 ? widget.recipe.portions : 1;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoCol = constraints.maxWidth >= 680 &&
              recipe.ingredients.isNotEmpty &&
              recipe.steps.isNotEmpty;

          final children = <Widget>[
            _buildMeta(context, recipe),
            if (recipe.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTags(recipe),
            ],
            const SizedBox(height: 24),
          ];

          if (twoCol) {
            children.add(IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280,
                    child: _buildIngredients(context, recipe),
                  ),
                  const SizedBox(width: 32),
                  Expanded(child: _buildSteps(context, recipe)),
                ],
              ),
            ));
            children.add(const SizedBox(height: 24));
          } else {
            if (recipe.ingredients.isNotEmpty) {
              children.add(_buildIngredients(context, recipe));
              children.add(const SizedBox(height: 24));
            }
            if (recipe.steps.isNotEmpty) {
              children.add(_buildSteps(context, recipe));
              children.add(const SizedBox(height: 24));
            }
          }

          if (recipe.notes.isNotEmpty) {
            children.add(_buildNotes(context, recipe));
            children.add(const SizedBox(height: 24));
          }

          if (recipe.ingredients.isEmpty &&
              recipe.steps.isEmpty &&
              recipe.description.isEmpty) {
            children.add(_buildEmptyHint(context));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
        },
      ),
    );
  }

  Widget _buildMeta(BuildContext context, Recipe recipe) {
    final chips = <DetailMetaItem>[
      if (recipe.difficulty.isNotEmpty)
        DetailMetaItem(
          icon: Icons.signal_cellular_alt_outlined,
          label: recipe.difficulty,
          color: difficultyColor(recipe.difficulty),
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

  Widget _buildTags(Recipe recipe) => Wrap(
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

  Widget _buildIngredients(BuildContext context, Recipe recipe) {
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

  Widget _buildSteps(BuildContext context, Recipe recipe) {
    final sorted = [...recipe.steps]
      ..sort((a, b) => a.order.compareTo(b.order));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zubereitung',
            style: Theme.of(context)
                .textTheme
                .titleLarge),
        const SizedBox(height: 12),
        ...sorted
            .asMap()
            .entries
            .map((e) => StepCard(step: e.value, index: e.key)),
      ],
    );
  }

  Widget _buildNotes(BuildContext context, Recipe recipe) => Column(
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

  Widget _buildEmptyHint(BuildContext context) {
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
}
