import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';
import '../shared/image_placeholder.dart';
import 'dashed_border_painter.dart';
import 'difficulty_chip.dart';
import 'editable_chip_field.dart';
import 'inline_ingredient_tile.dart';
import 'inline_step_tile.dart';
import 'inline_tag_input.dart';
import 'inline_text_field.dart';
import '../detail/portion_stepper.dart';

class RecipeEditContent extends StatelessWidget {
  const RecipeEditContent({
    super.key,
    required this.recipe,
    required this.descCtrl,
    required this.prepTimeCtrl,
    required this.cookTimeCtrl,
    required this.cuisineCtrl,
    required this.categoryCtrl,
    required this.notesCtrl,
    required this.difficulty,
    required this.editPortions,
    required this.editTags,
    required this.editIngredients,
    required this.editSteps,
    required this.onDifficultyChanged,
    required this.onPortionsChanged,
    required this.onTagAdded,
    required this.onTagRemoved,
    required this.onIngredientChanged,
    required this.onIngredientAdded,
    required this.onIngredientDeleted,
    required this.onStepChanged,
    required this.onStepAdded,
    required this.onStepDeleted,
    required this.onFieldChanged,
    required this.onPickImage,
  });

  final Recipe recipe;
  final TextEditingController descCtrl;
  final TextEditingController prepTimeCtrl;
  final TextEditingController cookTimeCtrl;
  final TextEditingController cuisineCtrl;
  final TextEditingController categoryCtrl;
  final TextEditingController notesCtrl;
  final String difficulty;
  final int editPortions;
  final List<String> editTags;
  final List<Ingredient> editIngredients;
  final List<RecipeStep> editSteps;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<int> onPortionsChanged;
  final ValueChanged<String> onTagAdded;
  final ValueChanged<String> onTagRemoved;
  final void Function(int index, Ingredient updated) onIngredientChanged;
  final VoidCallback onIngredientAdded;
  final ValueChanged<int> onIngredientDeleted;
  final void Function(int index, RecipeStep updated) onStepChanged;
  final VoidCallback onStepAdded;
  final ValueChanged<int> onStepDeleted;
  final VoidCallback onFieldChanged;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _buildImageSection(context),
        const SizedBox(height: 16),
        _buildMeta(context),
        const SizedBox(height: 12),
        _buildTagsSection(context),
        const SizedBox(height: 24),
        _buildIngredientsSection(context),
        const SizedBox(height: 24),
        _buildStepsSection(context),
        const SizedBox(height: 24),
        _buildNotesSection(context),
      ]),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final imageUrl = recipe.imageUrl;
    return GestureDetector(
      onTap: onPickImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) =>
                        const ImagePlaceholder())
              else
                const ImagePlaceholder(),
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

  Widget _buildMeta(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InlineTextField(
          controller: descCtrl,
          style: Theme.of(context).textTheme.bodyLarge,
          hint: 'Beschreibung hinzufügen...',
          maxLines: null,
          onChanged: onFieldChanged,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DifficultyChip(
              value: difficulty,
              onChanged: onDifficultyChanged,
            ),
            EditableChipField(
              icon: Icons.av_timer_outlined,
              controller: prepTimeCtrl,
              hint: 'Vorb.',
              onChanged: onFieldChanged,
            ),
            EditableChipField(
              icon: Icons.local_fire_department_outlined,
              controller: cookTimeCtrl,
              hint: 'Koch',
              onChanged: onFieldChanged,
            ),
            EditableChipField(
              icon: Icons.public_outlined,
              controller: cuisineCtrl,
              hint: 'Küche',
              onChanged: onFieldChanged,
            ),
            EditableChipField(
              icon: Icons.restaurant_menu_outlined,
              controller: categoryCtrl,
              hint: 'Kategorie',
              onChanged: onFieldChanged,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Portionen:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 8),
            PortionStepper(
              portions: editPortions,
              onChanged: onPortionsChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags',
            style: Theme.of(context)
                .textTheme
                .titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...editTags.map((tag) => Chip(
                  label: Text(tag),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                  onDeleted: () => onTagRemoved(tag),
                )),
            InlineTagInput(onAdd: onTagAdded),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zutaten',
            style: Theme.of(context)
                .textTheme
                .titleMedium),
        const SizedBox(height: 8),
        ...editIngredients.asMap().entries.map((e) => InlineIngredientTile(
              key: ValueKey('ing-${e.key}'),
              ingredient: e.value,
              onChanged: (updated) => onIngredientChanged(e.key, updated),
              onDelete: () => onIngredientDeleted(e.key),
            )),
        TextButton.icon(
          onPressed: onIngredientAdded,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Zutat hinzufügen'),
        ),
      ],
    );
  }

  Widget _buildStepsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zubereitung',
            style: Theme.of(context)
                .textTheme
                .titleMedium),
        const SizedBox(height: 8),
        ...editSteps.asMap().entries.map((e) => InlineStepTile(
              key: ValueKey('step-${e.key}'),
              step: e.value,
              index: e.key,
              onChanged: (updated) => onStepChanged(e.key, updated),
              onDelete: () => onStepDeleted(e.key),
            )),
        TextButton.icon(
          onPressed: onStepAdded,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Schritt hinzufügen'),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notizen',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: notesCtrl,
                maxLines: null,
                onChanged: (_) => onFieldChanged(),
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
}
