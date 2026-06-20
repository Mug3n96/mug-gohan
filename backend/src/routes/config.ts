import fs from 'fs';
import path from 'path';
import { Router, Request, Response } from 'express';
import { getConfig } from '../config';

const router = Router();

const exists = (file: string) =>
  fs.existsSync(path.join(process.cwd(), 'branding', file));

/**
 * @openapi
 * /api/config:
 *   get:
 *     summary: Get app configuration (theme + strings)
 *     description: Returns merged config from config.json and built-in defaults. No auth required.
 *     tags: [Config]
 *     responses:
 *       200:
 *         description: App config
 */
router.get('/', (_req: Request, res: Response) => {
  const { theme, strings, assistant } = getConfig();
  // Only the assistant's name is exposed; persona + language stay backend-only.
  const features = {
    voiceEnabled: !!process.env.WHISPER_URL,
    hasAvatar: exists('avatar.svg'),
    hasAvatarIcon: exists('avatar-icon.svg'),
  };
  res.json({ theme, strings, features, assistant: { name: assistant.name } });
});

export default router;
