import { Request, Response, NextFunction } from 'express';

const SESSION_COOKIE = 'mug_session';
const VALID_TOKEN = process.env.API_KEY ?? '';

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const token = req.cookies?.[SESSION_COOKIE] ?? req.headers['authorization']?.replace('Bearer ', '');

  if (!token || token !== VALID_TOKEN) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  next();
}
