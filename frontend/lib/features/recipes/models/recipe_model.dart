class Ingredient {
  final String name;
  final num amount;
  final String unit;
  final String? group;

  const Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.group,
  });

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        name: j['name'] as String,
        amount: j['amount'] as num,
        unit: j['unit'] as String,
        group: j['group'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'unit': unit,
        if (group != null) 'group': group,
      };
}

class RecipeStep {
  final int order;
  final String description;
  final int? durationMin;
  final String? tip;

  const RecipeStep({
    required this.order,
    required this.description,
    this.durationMin,
    this.tip,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> j) => RecipeStep(
        order: (j['order'] as num).toInt(),
        description: j['description'] as String,
        durationMin: (j['duration_min'] as num?)?.toInt(),
        tip: j['tip'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'order': order,
        'description': description,
        'duration_min': durationMin,
        'tip': tip,
      };
}

class Recipe {
  final String id;
  final String title;
  final String description;
  final int portions;
  final String prepTime;
  final String cookTime;
  final String difficulty;
  final String cuisine;
  final String category;
  final List<String> tags;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final String notes;
  final String? imageUrl;
  final String status;
  final String createdAt;
  final String updatedAt;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.portions,
    required this.prepTime,
    required this.cookTime,
    required this.difficulty,
    required this.cuisine,
    required this.category,
    required this.tags,
    required this.ingredients,
    required this.steps,
    required this.notes,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        portions: (j['portions'] as num?)?.toInt() ?? 0,
        prepTime: j['prep_time'] as String? ?? '',
        cookTime: j['cook_time'] as String? ?? '',
        difficulty: j['difficulty'] as String? ?? 'einfach',
        cuisine: j['cuisine'] as String? ?? '',
        category: j['category'] as String? ?? '',
        tags: j['tags'] != null ? List<String>.from(j['tags'] as List) : [],
        ingredients: j['ingredients'] != null
            ? (j['ingredients'] as List)
                .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        steps: j['steps'] != null
            ? (j['steps'] as List)
                .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        notes: j['notes'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
        status: j['status'] as String? ?? 'draft',
        createdAt: j['created_at'] as String? ?? '',
        updatedAt: j['updated_at'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'portions': portions,
        'prep_time': prepTime,
        'cook_time': cookTime,
        'difficulty': difficulty,
        'cuisine': cuisine,
        'category': category,
        'tags': tags,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps.map((e) => e.toJson()).toList(),
        'notes': notes,
        'image_url': imageUrl,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  bool get isDraft => status == 'draft';
  bool get hasTitle => title.isNotEmpty;
}
