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

CRITICAL OUTPUT RULES — follow exactly, every time:
1. Always respond in the user's language.
2. If you want to change ANYTHING in the recipe, you MUST include a ---PROPOSAL--- block.
   NEVER describe changes in text only — always produce the JSON block.
3. The proposal must contain the COMPLETE updated recipe (all fields), not just the changed fields.
4. If you have NO changes to propose (e.g. answering a question), omit the block entirely.

OUTPUT FORMAT:
[Your short message to the user — confirm what you changed or ask a question]
---PROPOSAL---
{ complete recipe JSON }
---END---

EXAMPLE of a correct response when changing steps:
Ich habe Schritt 4 korrigiert und den Test-Text entfernt.
---PROPOSAL---
{"title":"Spaghetti Carbonara","description":"...","portions":4,"prep_time":"15 min","cook_time":"20 min","difficulty":"mittel","tags":["Pasta","Italienisch"],"ingredients":[...],"steps":[{"order":1,"description":"..."},{"order":2,"description":"..."},{"order":3,"description":"..."},{"order":4,"description":"Pasta in die Pfanne geben und mit der Ei-Käse-Masse vermengen. Vom Herd nehmen."},{"order":5,"description":"..."}],"notes":"...","image_url":null,"status":"complete"}
---END---

RECIPE SCHEMA:
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
