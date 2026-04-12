import path from 'path';
import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import { initDb } from './db/database';
import { authMiddleware } from './middleware/auth';
import recipesRouter from './routes/recipes';
import chatRouter from './routes/chat';
import authRouter from './routes/auth';
import { setupSwagger } from './services/swagger';

const app = express();
const PORT = process.env.PORT ?? 3000;

app.use(cors({ origin: true, credentials: true }));
app.use(cookieParser());
app.use(express.json({ limit: '10mb' }));

initDb();

setupSwagger(app);

app.use('/api/auth', authRouter);
app.use('/api/recipes', authMiddleware, recipesRouter);
app.use('/api/recipes', authMiddleware, chatRouter);

// Serve Flutter web build as static files
const frontendPath = path.join(__dirname, '..', 'public');
app.use(express.static(frontendPath));
app.get('*', (_req, res) => {
  res.sendFile(path.join(frontendPath, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`mug-gohan backend running on port ${PORT}`);
});
