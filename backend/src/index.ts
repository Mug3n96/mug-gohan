import path from 'path';
import fs from 'fs';
import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import { initDb } from './db/database';
import { runMigrations } from './db/schema';
import { migrateImages } from './db/imageMigration';
import { authMiddleware } from './middleware/auth';
import recipesRouter from './routes/recipes';
import chatRouter from './routes/chat';
import authRouter from './routes/auth';
import configRouter from './routes/config';
import transcribeRouter from './routes/transcribe';
import { setupSwagger } from './services/swagger';

const app = express();
const PORT = process.env.PORT ?? 3000;

app.use(cors({ origin: true, credentials: true }));
app.use(cookieParser());
app.use(express.json({ limit: '50mb' }));

initDb();
runMigrations();
migrateImages().catch(err => console.error('Image migration failed:', err));

setupSwagger(app);

app.use('/api/config', configRouter);
app.use('/api/auth', authRouter);
app.use('/api/recipes', authMiddleware, recipesRouter);
app.use('/api/recipes', authMiddleware, chatRouter);
app.use('/api/transcribe', authMiddleware, transcribeRouter);

// Serve Flutter web build as static files
const frontendPath = path.join(__dirname, '..', 'public');

// Optional per-deployment branding lives in ./branding/ (mounted read-only).
// Each file is optional; bundled defaults are used when absent.
const brandingPath = path.join(process.cwd(), 'branding');

// Favicon: ./branding/favicon.png overrides the bundled one.
app.get('/favicon.png', (_req, res) => {
  const custom = path.join(brandingPath, 'favicon.png');
  res.sendFile(fs.existsSync(custom) ? custom : path.join(frontendPath, 'favicon.png'));
});

// AI avatar: ./branding/avatar.svg + avatar-icon.svg. Served raw; the frontend
// falls back to its bundled default (advertised via /api/config features).
function sendBranding(res: express.Response, file: string): void {
  const filePath = path.join(brandingPath, file);
  if (fs.existsSync(filePath)) {
    res.type('image/svg+xml').sendFile(filePath);
  } else {
    res.status(404).end();
  }
}
app.get('/api/branding/avatar', (_req, res) => sendBranding(res, 'avatar.svg'));
app.get('/api/branding/avatar-icon', (_req, res) => sendBranding(res, 'avatar-icon.svg'));

// Cross-origin isolation lets the WebAssembly build render multi-threaded
// (smoother scrolling). `credentialless` keeps cross-origin images such as
// YouTube thumbnails working.
app.use((_req, res, next) => {
  res.set('Cross-Origin-Opener-Policy', 'same-origin');
  res.set('Cross-Origin-Embedder-Policy', 'credentialless');
  next();
});

app.use(express.static(frontendPath));
app.get('*', (_req, res) => {
  res.sendFile(path.join(frontendPath, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`mug-gohan backend running on port ${PORT}`);
});
