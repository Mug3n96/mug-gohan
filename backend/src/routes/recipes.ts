import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getDb } from '../db/database';
import { Recipe, RecipeRow, RECIPE_COLUMNS, parseRecipe } from '../types';
import { imageVersion, normalizeDataUrl, parseDataUrl, RECIPE_IMAGE_MAX } from '../services/images';

const router = Router();

function getRecipeRow(id: string): RecipeRow | undefined {
  return getDb().prepare(`SELECT ${RECIPE_COLUMNS} FROM recipes WHERE id = ?`).get(id) as RecipeRow | undefined;
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
  const rows = db.prepare(`SELECT ${RECIPE_COLUMNS} FROM recipes ORDER BY updated_at DESC`).all() as RecipeRow[];
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
  const row = getRecipeRow(req.params.id);
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
router.post('/', async (req: Request, res: Response) => {
  const db = getDb();
  const id = uuidv4();
  const now = new Date().toISOString();
  const image = typeof req.body.image_url === 'string' && req.body.image_url.startsWith('data:')
    ? await normalizeDataUrl(req.body.image_url, RECIPE_IMAGE_MAX)
    : null;

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
    image_url: image,
    status: 'draft',
    created_at: now,
    updated_at: now,
  };

  db.prepare(`
    INSERT INTO recipes (id, title, description, portions, prep_time, cook_time, difficulty, cuisine, category, tags, ingredients, steps, notes, image_url, image_version, status, created_at, updated_at)
    VALUES (@id, @title, @description, @portions, @prep_time, @cook_time, @difficulty, @cuisine, @category, @tags, @ingredients, @steps, @notes, @image_url, @image_version, @status, @created_at, @updated_at)
  `).run({
    ...recipe,
    tags: JSON.stringify(recipe.tags),
    ingredients: JSON.stringify(recipe.ingredients),
    steps: JSON.stringify(recipe.steps),
    image_version: image ? imageVersion(image) : null,
  });

  res.status(201).json(parseRecipe(getRecipeRow(id)!));
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
  const existing = getRecipeRow(req.params.id);
  if (!existing) { res.status(404).json({ error: 'Recipe not found' }); return; }

  // image_url is ignored here on purpose: the image only changes via PUT
  // /:id/image, so a full-recipe save or an AI proposal cannot drop it.
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

  res.json(parseRecipe(getRecipeRow(existing.id)!));
});

router.put('/:id/image', async (req: Request, res: Response) => {
  const db = getDb();
  if (!getRecipeRow(req.params.id)) { res.status(404).json({ error: 'Recipe not found' }); return; }

  const raw: unknown = req.body.image;
  if (raw != null && (typeof raw !== 'string' || !parseDataUrl(raw))) {
    res.status(400).json({ error: 'image must be a data URL or null' });
    return;
  }
  const image = raw ? await normalizeDataUrl(raw, RECIPE_IMAGE_MAX) : null;
  db.prepare('UPDATE recipes SET image_url=@image_url, image_version=@image_version, updated_at=@updated_at WHERE id=@id').run({
    image_url: image,
    image_version: image ? imageVersion(image) : null,
    updated_at: new Date().toISOString(),
    id: req.params.id,
  });

  res.json(parseRecipe(getRecipeRow(req.params.id)!));
});

/**
 * @openapi
 * /api/recipes/{id}/image:
 *   get:
 *     summary: Recipe image as a file (cacheable; the URL carries a version)
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
 *         description: Image
 *       404:
 *         description: No image
 */
router.get('/:id/image', (req: Request, res: Response) => {
  const row = getDb().prepare('SELECT image_url FROM recipes WHERE id = ?').get(req.params.id) as
    { image_url: string | null } | undefined;
  const image = row?.image_url ? parseDataUrl(row.image_url) : null;
  if (!image) { res.status(404).end(); return; }
  // The URL changes with the image (?v=<hash>), so it can be cached forever.
  res.set('Cache-Control', 'private, max-age=31536000, immutable');
  res.type(image.mime).send(image.data);
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
