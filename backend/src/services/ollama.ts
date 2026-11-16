import { Recipe } from '../types';
import { getConfig } from '../config';

const OLLAMA_HOST = process.env.OLLAMA_HOST ?? 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL ?? 'gemma4:e2b';
const OLLAMA_API_KEY = process.env.OLLAMA_API_KEY;

export interface OllamaMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
  images?: string[];  // raw base64, only on user messages
}

export class OllamaError extends Error {
  constructor(public readonly status: number, body: string) {
    super(`Ollama error ${status}: ${body}`);
  }
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
    throw new OllamaError(response.status, await response.text());
  }

  const data = await response.json() as { message: { content: string } };
  return data.message.content;
}

export function buildSystemPrompt(recipe: Recipe): string {
  // Persona + language come from config.json (user-editable). The technical
  // rules below stay hardcoded — changing them would break response parsing.
  const { persona, language } = getConfig().assistant;

  return `${persona}

${language}

HONESTY RULES — highest priority:
- NEVER invent, guess, or hallucinate data. If you are unsure about an ingredient amount, cooking time, step, or any other detail — say so and ask the user.
- If an image is blurry, partial, or does not clearly show a recipe, state exactly what you can and cannot see, and ask the user to fill in the missing parts.
- Only include information in a proposal that you are confident about. Leave fields empty/null if unknown rather than making something up.
- If you are missing critical information, ask the user ONE specific question instead of guessing.

CRITICAL OUTPUT RULES — follow exactly, every time:
1. Always respond in the user's language (see LANGUAGE RULES above).
2. If you want to change ANYTHING in the recipe, you MUST include a ---PROPOSAL--- block.
   NEVER describe changes in text only — always produce the JSON block.
3. The proposal must contain the COMPLETE updated recipe (all fields), not just the changed fields.
4. If you have NO changes to propose (e.g. answering a question or asking for clarification), omit the block entirely.
5. When information is missing: ask ONE specific question, do not guess.

VIDEO LINKS:
- A user message may end with a [VIDEO ANALYSIS] block: an automatic transcript of a YouTube video the user linked. You cannot watch videos yourself; this text is your source. Take amounts exactly from it and mention what it lists as UNCERTAIN.
- If a message says a YouTube video was "not analyzed", tell the user briefly why and ask them to paste the recipe text or describe it.

OUTPUT FORMAT:
[Your short message to the user — confirm what you changed, or ask a specific question]
---PROPOSAL---
{ complete recipe JSON }
---END---

EXAMPLE — image is unclear:
Das Bild ist leider zu unscharf — ich sehe einen Kuchen, aber die Zutatenliste ist nicht lesbar. Welche Zutaten sind drin?

EXAMPLE — some info missing:
Titel und Schritte habe ich übernommen. Für wie viele Portionen soll das Rezept reichen?
---PROPOSAL---
{"title":"Apfelkuchen","description":"","portions":0,"prep_time":"","cook_time":"","difficulty":"mittel","cuisine":"","category":"Dessert","tags":[],"ingredients":[],"steps":[{"order":1,"description":"...","duration_min":10,"tip":""}],"notes":"","image_url":null,"status":"draft"}
---END---

RECIPE SCHEMA:
{
  "title": string,
  "description": string,
  "portions": number,
  "prep_time": string,
  "cook_time": string,
  "difficulty": "einfach" | "mittel" | "schwer",
  "cuisine": string (e.g. "Italienisch", "Japanisch" — empty if unknown),
  "category": string (e.g. "Hauptgericht", "Dessert" — empty if unknown),
  "tags": string[],
  "ingredients": [{ "name": string, "amount": number, "unit": "g"|"ml"|"stk"|"EL"|"TL"|"Prise", "group"?: string }],
  "steps": [{ "order": number, "description": string, "duration_min": number (estimate minutes, required), "tip": string (useful cooking tip, required) }],
  "notes": string,
  "image_url": string | null,
  "status": "draft" | "complete"
}

CURRENT RECIPE:
${JSON.stringify((({ image_url, ...rest }) => rest)(recipe), null, 2)}`;
}
