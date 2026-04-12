import { Recipe } from '../types';

const OLLAMA_HOST = process.env.OLLAMA_HOST ?? 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL ?? 'gemma4:e4b';
const OLLAMA_API_KEY = process.env.OLLAMA_API_KEY;

export interface OllamaMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export async function chatWithOllama(messages: OllamaMessage[]): Promise<string> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (OLLAMA_API_KEY) {
    headers['Authorization'] = `Bearer ${OLLAMA_API_KEY}`;
  }

  const response = await fetch(`${OLLAMA_HOST}/api/chat`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      model: OLLAMA_MODEL,
      messages,
      stream: false,
    }),
  });

  if (!response.ok) {
    throw new Error(`Ollama error: ${response.status} ${await response.text()}`);
  }

  const data = await response.json() as { message: { content: string } };
  return data.message.content;
}

export function buildSystemPrompt(recipe: Recipe): string {
  return `You are a cooking assistant for the app mug-gohan.
Your job: help users capture and improve recipes.

RULES:
- Fill in the recipe template as completely as possible based on user input
- If information is missing: ask ONE specific question
- Always respond in the user's language
- Always respond in this exact format:
  [Your message to the user]
  ---PROPOSAL---
  { JSON with recipe changes }
  ---END---
- If no changes to propose: omit the PROPOSAL block entirely
- Only include fields in the proposal that actually changed
- For ingredient scaling: recalculate ALL ingredients proportionally, warn about non-linear items (spices, baking times)

TEMPLATE SCHEMA:
{
  "title": string,
  "description": string,
  "portions": number,
  "prep_time": string,
  "cook_time": string,
  "difficulty": "einfach" | "mittel" | "schwer",
  "tags": string[],
  "ingredients": [{ "name": string, "amount": number, "unit": "g"|"ml"|"stk"|"EL"|"TL"|"Prise", "group"?: string }],
  "steps": [{ "order": number, "description": string, "duration_min"?: number, "tip"?: string }],
  "notes": string,
  "image_url": string | null,
  "status": "draft" | "complete"
}

CURRENT RECIPE:
${JSON.stringify(recipe, null, 2)}`;
}
