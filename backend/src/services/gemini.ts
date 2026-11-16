/**
 * Optional video analysis via the Gemini API. Gemini watches and listens to a
 * public YouTube video and writes the recipe down as plain text. The result is
 * cached (see services/videos.ts), so each video is analyzed only once.
 */

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
export const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-3.1-flash-lite';

export const isGeminiEnabled = (): boolean => !!GEMINI_API_KEY;

export class GeminiError extends Error {
  constructor(public readonly status: number, body: string) {
    super(`Gemini error ${status}: ${body.slice(0, 300)}`);
  }
}

const ANALYSIS_PROMPT = `You extract cooking recipes from videos. Watch AND listen to the whole video.
Answer in plain text with exactly this structure and nothing else:

TITLE: <name of the dish>
SERVINGS: <number, or "unknown">
INGREDIENTS:
- <amount> <unit> <ingredient>
STEPS:
1. <step, including times and temperatures>
TIPS: <useful tips from the video, or "none">
ON-SCREEN TEXT: <recipe-relevant text shown in the video, verbatim, or "none">
UNCERTAIN: <what was unclear, only estimated or missing, or "nothing">

Rules:
- Never invent amounts. If an amount is neither said nor shown, write "amount unknown".
- If you estimate an amount from what you see, add "(estimated)".
- Keep the units used in the video.
- Write in the language of the video.
- If the video contains no recipe, answer only: NO RECIPE: <one sentence about what the video shows>`;

export async function analyzeVideo(videoUrl: string): Promise<string> {
  if (!GEMINI_API_KEY) throw new Error('Gemini not configured');

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
      body: JSON.stringify({
        contents: [{ parts: [{ file_data: { file_uri: videoUrl } }, { text: ANALYSIS_PROMPT }] }],
      }),
      signal: AbortSignal.timeout(150_000),
    },
  );

  if (!res.ok) throw new GeminiError(res.status, await res.text());

  const data = (await res.json()) as {
    candidates?: { content?: { parts?: { text?: string; thought?: boolean }[] } }[];
  };
  const text = (data.candidates?.[0]?.content?.parts ?? [])
    .filter(p => p.text && !p.thought)
    .map(p => p.text)
    .join('')
    .trim();
  if (!text) throw new GeminiError(200, 'empty response');
  return text;
}
