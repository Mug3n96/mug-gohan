import fs from 'fs';
import path from 'path';

/**
 * Single source of truth for app configuration.
 *
 * Reads config.json (mounted read-only via docker compose) and merges it with
 * the built-in defaults below. Used by:
 *   - routes/config.ts  → serves theme/strings/features to the frontend
 *   - services/ollama.ts → builds the assistant persona into the system prompt
 *
 * Defaults live ONLY here, so config.json can be partial / missing.
 */

const CONFIG_PATH = path.join(process.cwd(), 'config.json');

export interface AppConfig {
  theme: {
    seedColor: string;
    accentColor: string;
  };
  strings: {
    appTitle: string;
    loginTitle: string;
    loginSubtitle: string;
    remyGreeting: string;
    remySubtitle: string;
    remyFooter: string;
    listEmptyTitle: string;
    listEmptySubtitle: string;
    listCreateButton: string;
    recipeEmptyHint: string;
  };
  assistant: {
    name: string;
    persona: string;
    language: string;
  };
}

const DEFAULTS: AppConfig = {
  theme: {
    seedColor: '#2D6A4F',
    accentColor: '#52B788',
  },
  strings: {
    appTitle: 'mug-gohan',
    loginTitle: 'mug-gohan',
    loginSubtitle: '無限ごはん',
    remyGreeting: 'Hey, ich bin Miso!',
    remySubtitle: 'Lass uns zusammen Rezepte entwerfen',
    remyFooter:
      'Was für ein Rezept möchtest du entwerfen? Sende mir gerne Bilder, Notizen, Fotos oder eine Sprachnachricht und wir erstellen ein tolles Rezept!',
    listEmptyTitle: 'Noch keine Rezepte',
    listEmptySubtitle: 'Erstelle dein erstes Rezept\nund lass Miso dir helfen.',
    listCreateButton: 'Rezept erstellen',
    recipeEmptyHint: 'Noch leer — tippe auf ✏️\num mit Miso loszulegen.',
  },
  assistant: {
    name: 'Miso',
    persona:
      'You are Miso, a friendly and level-headed cooking assistant for the app mug-gohan. You help users capture, structure and refine their recipes.\n\nKeep your answers short and to the point — usually a sentence or two, never rambling.\n\nWhen it fits naturally, add one small touch: a brief fun fact about the dish or an ingredient, or a note on where it comes from. Keep it to a single sentence, light and genuine — never forced, and never at the expense of being helpful.\n\nStay calm and neutral in tone — warm, but not over-the-top.',
    language:
      'LANGUAGE RULES:\n- Default language: German. Always respond in German unless the user explicitly asks otherwise.\n- If the user writes in English, respond in English.',
  },
};

/**
 * Loads and returns the merged config. Read on each call so edits to
 * config.json take effect after a container restart without a rebuild.
 * Falls back to DEFAULTS if the file is missing or invalid.
 */
/**
 * Persona / language may be written as a single string or as an array of lines
 * (joined with newlines) so config.json stays readable over multiple lines.
 */
function lines(value: unknown, fallback: string): string {
  if (Array.isArray(value)) return value.join('\n');
  if (typeof value === 'string') return value;
  return fallback;
}

export function getConfig(): AppConfig {
  try {
    const raw = fs.readFileSync(CONFIG_PATH, 'utf-8');
    const user = JSON.parse(raw) as Record<string, any>;
    const assistant = (user.assistant ?? {}) as Record<string, unknown>;
    return {
      theme: { ...DEFAULTS.theme, ...(user.theme ?? {}) },
      strings: { ...DEFAULTS.strings, ...(user.strings ?? {}) },
      assistant: {
        name: (assistant.name as string) ?? DEFAULTS.assistant.name,
        persona: lines(assistant.persona, DEFAULTS.assistant.persona),
        language: lines(assistant.language, DEFAULTS.assistant.language),
      },
    };
  } catch {
    return DEFAULTS;
  }
}
