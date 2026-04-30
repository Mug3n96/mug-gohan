import multer from 'multer';
import { Router, Request, Response } from 'express';
import { isWhisperEnabled, transcribeAudio } from '../services/whisper';

const router = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024 },
});

/**
 * @openapi
 * /api/transcribe:
 *   post:
 *     summary: Transcribe audio via Whisper
 *     description: Requires WHISPER_URL to be configured. Accepts multipart audio file, returns transcript.
 *     tags: [Transcribe]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               audio:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Transcript text
 *       503:
 *         description: Whisper not configured
 */
router.post('/', upload.single('audio'), async (req: Request, res: Response) => {
  if (!isWhisperEnabled()) {
    res.status(503).json({ error: 'Voice transcription not configured' });
    return;
  }

  if (!req.file) {
    res.status(400).json({ error: 'No audio file provided' });
    return;
  }

  try {
    const transcript = await transcribeAudio(
      req.file.buffer,
      req.file.mimetype,
      req.file.originalname,
    );
    res.json({ transcript });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

export default router;
