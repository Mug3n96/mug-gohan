import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getDb } from '../db/database';
import { Recipe, RecipeRow } from '../types';

const router = Router();

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
 * /api/recipes:
 *   get:
 *     summary: List all recipes
 *     security:
 *       - cookieAuth: []
 *     responses:
 *       200:
 *         description: List of recipes
 */
router.get('/', (_req: Request, res: Response) => {
  const db = getDb();
  const rows = db.prepare('SELECT * FROM recipes ORDER BY updated_at DESC').all() as RecipeRow[];
  res.json(rows.map(parseRecipe));
});

/**
 * @openapi
 * /api/recipes/{id}:
 *   get:
 *     summary: Get a recipe by ID
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
 *         description: Recipe found
 *       404:
 *         description: Recipe not found
 */
router.get('/:id', (req: Request, res: Response) => {
  const db = getDb();
  const row = db.prepare('SELECT * FROM recipes WHERE id = ?').get(req.params.id) as RecipeRow | undefined;
  if (!row) { res.status(404).json({ error: 'Recipe not found' }); return; }
  res.json(parseRecipe(row));
});

/**
 * @openapi
 * /api/recipes:
 *   post:
 *     summary: Create a new recipe
 *     security:
 *       - cookieAuth: []
 *     responses:
 *       201:
 *         description: Recipe created
 */
router.post('/', (req: Request, res: Response) => {
  const db = getDb();
  const id = uuidv4();
  const now = new Date().toISOString();

  const recipe: Recipe = {
    id,
    title: req.body.title ?? '',
    description: req.body.description ?? '',
    portions: req.body.portions ?? 4,
    prep_time: req.body.prep_time ?? '',
    cook_time: req.body.cook_time ?? '',
    difficulty: req.body.difficulty ?? 'einfach',
    cuisine: req.body.cuisine ?? '',
    category: req.body.category ?? '',
    tags: req.body.tags ?? [],
    ingredients: req.body.ingredients ?? [],
    steps: req.body.steps ?? [],
    notes: req.body.notes ?? '',
    image_url: req.body.image_url ?? null,
    status: 'draft',
    created_at: now,
    updated_at: now,
  };

  db.prepare(`
    INSERT INTO recipes (id, title, description, portions, prep_time, cook_time, difficulty, cuisine, category, tags, ingredients, steps, notes, image_url, status, created_at, updated_at)
    VALUES (@id, @title, @description, @portions, @prep_time, @cook_time, @difficulty, @cuisine, @category, @tags, @ingredients, @steps, @notes, @image_url, @status, @created_at, @updated_at)
  `).run({
    ...recipe,
    tags: JSON.stringify(recipe.tags),
    ingredients: JSON.stringify(recipe.ingredients),
    steps: JSON.stringify(recipe.steps),
  });

  res.status(201).json(recipe);
});

/**
 * @openapi
 * /api/recipes/{id}:
 *   put:
 *     summary: Update a recipe
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
 *         description: Recipe updated
 *       404:
 *         description: Recipe not found
 */
router.put('/:id', (req: Request, res: Response) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM recipes WHERE id = ?').get(req.params.id) as RecipeRow | undefined;
  if (!existing) { res.status(404).json({ error: 'Recipe not found' }); return; }

  const updated: Recipe = {
    ...parseRecipe(existing),
    ...req.body,
    id: existing.id,
    created_at: existing.created_at,
    updated_at: new Date().toISOString(),
  };

  db.prepare(`
    UPDATE recipes SET title=@title, description=@description, portions=@portions, prep_time=@prep_time,
    cook_time=@cook_time, difficulty=@difficulty, cuisine=@cuisine, category=@category,
    tags=@tags, ingredients=@ingredients, steps=@steps,
    notes=@notes, status=@status, updated_at=@updated_at WHERE id=@id
  `).run({
    ...updated,
    tags: JSON.stringify(updated.tags),
    ingredients: JSON.stringify(updated.ingredients),
    steps: JSON.stringify(updated.steps),
  });

  res.json(updated);
});

router.put('/:id/image', (req: Request, res: Response) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM recipes WHERE id = ?').get(req.params.id) as RecipeRow | undefined;
  if (!existing) { res.status(404).json({ error: 'Recipe not found' }); return; }

  const imageUrl: string | null = req.body.image ?? null;
  db.prepare('UPDATE recipes SET image_url=@image_url, updated_at=@updated_at WHERE id=@id').run({
    image_url: imageUrl,
    updated_at: new Date().toISOString(),
    id: req.params.id,
  });

  const updated = db.prepare('SELECT * FROM recipes WHERE id = ?').get(req.params.id) as RecipeRow;
  res.json(parseRecipe(updated));
});

/**
 * @openapi
 * /api/recipes/{id}:
 *   delete:
 *     summary: Delete a recipe
 *     security:
 *       - cookieAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Recipe deleted
 *       404:
 *         description: Recipe not found
 */
router.delete('/:id', (req: Request, res: Response) => {
  const db = getDb();
  const result = db.prepare('DELETE FROM recipes WHERE id = ?').run(req.params.id);
  if (result.changes === 0) { res.status(404).json({ error: 'Recipe not found' }); return; }
  res.status(204).send();
});

export default router;
