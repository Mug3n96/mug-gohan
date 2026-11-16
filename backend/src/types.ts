import { recipeImagePath } from './services/images';

export interface Ingredient {
  name: string;
  amount: number;
  unit: 'g' | 'ml' | 'stk' | 'EL' | 'TL' | 'Prise';
  group?: string;
}

export interface Step {
  order: number;
  description: string;
  duration_min?: number | null;
  tip?: string;
}

export interface Recipe {
  id: string;
  title: string;
  description: string;
  portions: number;
  prep_time: string;
  cook_time: string;
  difficulty: 'einfach' | 'mittel' | 'schwer';
  cuisine: string;
  category: string;
  tags: string[];
  ingredients: Ingredient[];
  steps: Step[];
  notes: string;
  image_url: string | null;
  status: 'draft' | 'complete';
  created_at: string;
  updated_at: string;
}

export interface ChatMessage {
  id: string;
  recipe_id: string;
  role: 'user' | 'assistant';
  content: string;
  proposal: Recipe | null;
  proposal_status: 'accepted' | 'rejected' | null;
  created_at: string;
  image_data: string | null;
  image_mime: string | null;
  video_id: string | null;
}

/** Cached YouTube video: oEmbed title + one-time Gemini analysis. */
export interface VideoRow {
  id: string;
  title: string | null;
  author: string | null;
  analysis: string | null;
  analysis_model: string | null;
  analyzed_at: string | null;
  created_at: string;
}

export interface ChatVideo {
  id: string;
  url: string;
  title: string | null;
  thumbnail_url: string;
  analyzed: boolean;
}

/**
 * Recipe columns without the image data itself (Base64, can be large).
 * The image is served separately, see routes/recipes.ts GET /:id/image.
 */
export const RECIPE_COLUMNS =
  'id, title, description, portions, prep_time, cook_time, difficulty, cuisine, category, ' +
  'tags, ingredients, steps, notes, status, created_at, updated_at, image_version';

export type RecipeRow = Omit<Recipe, 'tags' | 'ingredients' | 'steps' | 'image_url'> & {
  tags: string;
  ingredients: string;
  steps: string;
  /** Content hash of the stored image, null without image. */
  image_version: string | null;
};

export type ChatMessageRow = Omit<ChatMessage, 'proposal'> & {
  proposal: string | null;
};

/**
 * Recipe rows store tags/ingredients/steps as JSON strings. `image_url` in the
 * API is the (cacheable) image endpoint, not the stored data URL.
 */
export function parseRecipe(row: RecipeRow): Recipe {
  const { image_version, tags, ingredients, steps, ...rest } = row;
  return {
    ...rest,
    tags: JSON.parse(tags),
    ingredients: JSON.parse(ingredients),
    steps: JSON.parse(steps),
    image_url: image_version ? recipeImagePath(row.id, image_version) : null,
  };
}
