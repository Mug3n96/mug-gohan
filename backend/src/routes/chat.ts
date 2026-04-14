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
  const { message, imageData, imageMime } = req.body;

  // Valid if either text or image is provided
  if (!message?.trim() && !imageData) {
    res.status(400).json({ error: 'Message or image is required' });
    return;
  }

  const recipeRow = db.prepare('SELECT * FROM recipes WHERE id = ?').get(req.params.id) as RecipeRow | undefined;
  if (!recipeRow) { res.status(404).json({ error: 'Recipe not found' }); return; }

  const recipe = parseRecipe(recipeRow);

  // Save user message
  const userMsgId = uuidv4();
  const now = new Date().toISOString();
  const userContent = message?.trim() ?? '';
  db.prepare('INSERT INTO chat_messages (id, recipe_id, role, content, proposal, image_data, image_mime, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
    .run(userMsgId, recipe.id, 'user', userContent, null, imageData ?? null, imageMime ?? null, now);

  // Build message history for Ollama, including images on user messages
  const history = db
    .prepare('SELECT * FROM chat_messages WHERE recipe_id = ? ORDER BY created_at ASC')
    .all(recipe.id) as ChatMessageRow[];

  const ollamaMessages: OllamaMessage[] = [
    { role: 'system', content: buildSystemPrompt(recipe) },
    ...history.map(m => ({
      role: m.role as 'user' | 'assistant',
      content: m.content,
      ...(m.role === 'user' && m.image_data ? { images: [m.image_data] } : {}),
    })),
  ];

  try {
    const raw = await chatWithOllama(ollamaMessages);
    console.log('=== LLM RAW RESPONSE ===\n', raw, '\n========================');
    const { text, proposal } = parseLlmResponse(raw);
    console.log('Parsed proposal:', proposal ? 'YES' : 'null');

    // Auto-reject any previous unresolved proposals
    if (proposal) {
      db.prepare(`
        UPDATE chat_messages
        SET proposal_status = 'rejected'
        WHERE recipe_id = ? AND proposal IS NOT NULL AND proposal_status IS NULL
      `).run(recipe.id);
    }

    // Save assistant message
    const assistantMsgId = uuidv4();
    db.prepare('INSERT INTO chat_messages (id, recipe_id, role, content, proposal, created_at) VALUES (?, ?, ?, ?, ?, ?)')
      .run(assistantMsgId, recipe.id, 'assistant', text, proposal ? JSON.stringify(proposal) : null, new Date().toISOString());

    res.json({ id: assistantMsgId, text, proposal });
  } catch (err) {
    const error = err as Error;
    res.status(502).json({ error: `Ollama unreachable: ${error.message}` });
  }
});

/**
 * @openapi
 * /api/recipes/{id}/chat:
 *   delete:
 *     summary: Clear chat history for a recipe
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
 *         description: Cleared
 */
router.delete('/:id/chat', (req: Request, res: Response) => {
  const db = getDb();
  db.prepare('DELETE FROM chat_messages WHERE recipe_id = ?').run(req.params.id);
  res.json({ ok: true });
});

/**
 * @openapi
 * /api/recipes/{id}/chat/{msgId}:
 *   patch:
 *     summary: Update proposal status of a chat message
 *     security:
 *       - cookieAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: msgId
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
 *               proposal_status:
 *                 type: string
 *                 enum: [accepted, rejected]
 *     responses:
 *       200:
 *         description: Updated
 *       400:
 *         description: Invalid status
 *       404:
 *         description: Message not found
 */
router.patch('/:id/chat/:msgId', (req: Request, res: Response) => {
  const { proposal_status } = req.body;
  if (proposal_status !== 'accepted' && proposal_status !== 'rejected') {
    res.status(400).json({ error: 'proposal_status must be accepted or rejected' });
    return;
  }
  const db = getDb();
  const result = db
    .prepare('UPDATE chat_messages SET proposal_status = ? WHERE id = ? AND recipe_id = ?')
    .run(proposal_status, req.params.msgId, req.params.id);
  if (result.changes === 0) {
    res.status(404).json({ error: 'Message not found' });
    return;
  }
  res.json({ ok: true });
});

export default router;
