import path from 'path';
import fs from 'fs';
import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import { initDb } from './db/database';
import { runMigrations } from './db/schema';
import { authMiddleware } from './middleware/auth';
import recipesRouter from './routes/recipes';
import chatRouter from './routes/chat';
import authRouter from './routes/auth';
import configRouter from './routes/config';
import { setupSwagger } from './services/swagger';

const app = express();
const PORT = process.env.PORT ?? 3000;

app.use(cors({ origin: true, credentials: true }));
app.use(cookieParser());
app.use(express.json({ limit: '50mb' }));

initDb();
runMigrations();

setupSwagger(app);

app.use('/api/config', configRouter);
app.use('/api/auth', authRouter);
app.use('/api/recipes', authMiddleware, recipesRouter);
app.use('/api/recipes', authMiddleware, chatRouter);

// Serve Flutter web build as static files
const frontendPath = path.join(__dirname, '..', 'public');

// Allow favicon to be overridden by placing a favicon.png next to docker-compose.yml
const customFavicon = path.join(process.cwd(), 'favicon.png');
app.get('/favicon.png', (_req, res) => {
  if (fs.existsSync(customFavicon)) {
    res.sendFile(customFavicon);
  } else {
    res.sendFile(path.join(frontendPath, 'favicon.png'));
  }
});

app.use(express.static(frontendPath));
app.get('*', (_req, res) => {
  res.sendFile(path.join(frontendPath, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`mug-gohan backend running on port ${PORT}`);
});
