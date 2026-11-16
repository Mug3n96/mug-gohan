import { getDb } from './database';
import { CHAT_IMAGE_MAX, imageVersion, normalizeDataUrl, normalizeImage, RECIPE_IMAGE_MAX } from '../services/images';

/**
 * One-time cleanup for images stored before images were normalized on upload:
 * shrinks them to JPEG and gives recipe images their cache version. Runs in the
 * background at startup; rows that are already fine are skipped, so later
 * starts do (almost) nothing.
 */
export async function migrateImages(): Promise<void> {
  const db = getDb();
  let changed = 0;

  const recipes = db
    .prepare(`SELECT id, image_url FROM recipes WHERE image_url IS NOT NULL AND image_version IS NULL`)
    .all() as { id: string; image_url: string }[];
  for (const r of recipes) {
    if (!r.image_url.startsWith('data:')) continue;
    const image = await normalizeDataUrl(r.image_url, RECIPE_IMAGE_MAX);
    db.prepare('UPDATE recipes SET image_url = ?, image_version = ? WHERE id = ?')
      .run(image, imageVersion(image), r.id);
    changed++;
  }

  const chatImages = db
    .prepare(`
      SELECT id, image_data FROM chat_messages
      WHERE image_data IS NOT NULL AND image_mime LIKE 'image/%'
        AND (image_mime != 'image/jpeg' OR length(image_data) > 800000)
    `)
    .all() as { id: string; image_data: string }[];
  for (const m of chatImages) {
    try {
      const jpeg = (await normalizeImage(Buffer.from(m.image_data, 'base64'), CHAT_IMAGE_MAX)).toString('base64');
      if (jpeg.length >= m.image_data.length) continue;
      db.prepare(`UPDATE chat_messages SET image_data = ?, image_mime = 'image/jpeg' WHERE id = ?`).run(jpeg, m.id);
      changed++;
    } catch (err) {
      console.warn(`Chat image ${m.id} could not be normalized:`, (err as Error).message);
    }
  }

  if (changed > 0) {
    db.exec('VACUUM'); // give the freed space back to the file system
    console.log(`Image migration: ${changed} image(s) optimized`);
  }
}
