import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getDb } from '../db/database';
import { ChatMessage, ChatMessageRow, Recipe, RecipeRow } from '../types';
import { chatWithOllama, buildSystemPrompt, OllamaMessage } from '../services/ollama';
import { parseLlmResponse } from '../services/parser';

const router = Router();

function parseChatMessage(row: ChatMessageRow): ChatMessage {
  return {
    ...row,
    proposal: row.proposal ? JSON.parse(row.proposal) : null,
  };
}

function parseRecipe(row: RecipeRow): Recipe {
  return {
    ...row,
    tags: JSON.parse(row.tags),
    ingredients: JSON.parse(row.ingredients),
    steps: JSON.parse(row.steps),
  };
}

/**
 * @openapi
 * /api/recipes/{id}/chat:
 *   get:
 *     summary: Get chat history for a recipe
 *     security:
 *       - cookieAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Chat history
 */
router.get('/:id/chat', (req: Request, res: Response) => {
  const db = getDb();
  const rows = db
    .prepare('SELECT * FROM chat_messages WHERE recipe_id = ? ORDER BY created_at ASC')
    .all(req.params.id) as ChatMessageRow[];
  res.json(rows.map(parseChatMessage));
});

/**
 * @openapi
 * /api/recipes/{id}/chat:
 *   post:
 *     summary: Send a message to the AI assistant
 *     security:
 *       - cookieAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               message:
 *                 type: string
 *     responses:
 *       200:
 *         description: AI response with optional proposal
 *       404:
 *         description: Recipe not found
 */
router.post('/:id/chat', async (req: Request, res: Response) => {
  const db = getDb();
  const { message } = req.body;

  if (!message?.trim()) {
    res.status(400).json({ error: 'Message is required' });
    return;
  }

  const recipeRow = db.prepare('SELECT * FROM recipes WHERE id = ?').get(req.params.id) as RecipeRow | undefined;
  if (!recipeRow) { res.status(404).json({ error: 'Recipe not found' }); return; }

  const recipe = parseRecipe(recipeRow);

  // Save user message
  const userMsgId = uuidv4();
  const now = new Date().toISOString();
  db.prepare('INSERT INTO chat_messages (id, recipe_id, role, content, proposal, created_at) VALUES (?, ?, ?, ?, ?, ?)')
    .run(userMsgId, recipe.id, 'user', message, null, now);

  // Build message history for Ollama
  const history = db
    .prepare('SELECT * FROM chat_messages WHERE recipe_id = ? ORDER BY created_at ASC')
    .all(recipe.id) as ChatMessageRow[];

  const ollamaMessages: OllamaMessage[] = [
    { role: 'system', content: buildSystemPrompt(recipe) },
    ...history.map(m => ({ role: m.role as 'user' | 'assistant', content: m.content })),
  ];

  try {
    const raw = await chatWithOllama(ollamaMessages);
    console.log('=== LLM RAW RESPONSE ===\n', raw, '\n========================');
    const { text, proposal } = parseLlmResponse(raw);
    console.log('Parsed proposal:', proposal ? 'YES' : 'null');

    // Save assistant message
    const assistantMsgId = uuidv4();
    db.prepare('INSERT INTO chat_messages (id, recipe_id, role, content, proposal, created_at) VALUES (?, ?, ?, ?, ?, ?)')
      .run(assistantMsgId, recipe.id, 'assistant', text, proposal ? JSON.stringify(proposal) : null, new Date().toISOString());

    res.json({ text, proposal });
  } catch (err) {
    const error = err as Error;
    res.status(502).json({ error: `Ollama unreachable: ${error.message}` });
  }
});

export default router;
