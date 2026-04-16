import fs from 'fs';
import path from 'path';
import { Router, Request, Response } from 'express';

const router = Router();

const CONFIG_PATH = path.join(process.cwd(), 'config.json');

const DEFAULTS = {
  theme: {
    seedColor: '#2D6A4F',
    accentColor: '#52B788',
  },
  strings: {
    appTitle: 'mug-gohan',
    loginTitle: 'mug-gohan',
    loginSubtitle: '無限ごはん',
    remyGreeting: 'Hey, ich bin Ramy!',
    remySubtitle: 'Lass uns zusammen Rezepte entwerfen',
    listEmptyTitle: 'Noch keine Rezepte',
    listEmptySubtitle: 'Erstelle dein erstes Rezept\nund lass Remy dir helfen.',
    listCreateButton: 'Rezept erstellen',
    recipeEmptyHint: 'Noch leer — tippe auf ✏️\num mit Remy loszulegen.',
  },
};

/**
 * @openapi
 * /api/config:
 *   get:
 *     summary: Get app configuration (theme + strings)
 *     description: Returns merged config from data/config.json and built-in defaults. No auth required.
 *     tags: [Config]
 *     responses:
 *       200:
 *         description: App config
 */
router.get('/', (_req: Request, res: Response) => {
  try {
    if (fs.existsSync(CONFIG_PATH)) {
      const raw = fs.readFileSync(CONFIG_PATH, 'utf-8');
      const user = JSON.parse(raw) as Partial<typeof DEFAULTS>;
      res.json({
        theme: { ...DEFAULTS.theme, ...(user.theme ?? {}) },
        strings: { ...DEFAULTS.strings, ...(user.strings ?? {}) },
      });
      return;
    }
  } catch {
    // fall through to defaults
  }
  res.json(DEFAULTS);
});

export default router;
