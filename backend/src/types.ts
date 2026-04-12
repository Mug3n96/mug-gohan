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
  created_at: string;
}

export type RecipeRow = Omit<Recipe, 'tags' | 'ingredients' | 'steps'> & {
  tags: string;
  ingredients: string;
  steps: string;
};

export type ChatMessageRow = Omit<ChatMessage, 'proposal'> & {
  proposal: string | null;
};
