import { Router, Request, Response } from 'express';

const router = Router();
const SESSION_COOKIE = 'mug_session';

/**
 * @openapi
 * /api/auth/login:
 *   post:
 *     summary: Login with API key
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               key:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid API key
 */
router.post('/login', (req: Request, res: Response) => {
  const { key } = req.body;

  if (!key || key !== process.env.API_KEY) {
    res.status(401).json({ error: 'Invalid API key' });
    return;
  }

  res.cookie(SESSION_COOKIE, key, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
  });

  res.json({ ok: true });
});

router.post('/logout', (_req: Request, res: Response) => {
  res.clearCookie(SESSION_COOKIE);
  res.json({ ok: true });
});

export default router;
