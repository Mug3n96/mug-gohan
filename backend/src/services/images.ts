import crypto from 'crypto';
import sharp from 'sharp';

/**
 * Images stay Base64 in SQLite (simple backups), but are normalized to a
 * reasonably sized JPEG on the way in and served as plain image files with
 * long-lived browser caching on the way out.
 */

export const RECIPE_IMAGE_MAX = 1200; // px, longest side
export const CHAT_IMAGE_MAX = 1600; // a bit larger: the LLM reads text in photos

const KEEP_AS_IS_BYTES = 400 * 1024;

export function parseDataUrl(dataUrl: string): { mime: string; data: Buffer } | null {
  const match = /^data:([\w.+-]+\/[\w.+-]+);base64,(.*)$/s.exec(dataUrl);
  if (!match) return null;
  return { mime: match[1], data: Buffer.from(match[2], 'base64') };
}

/**
 * Returns a JPEG no larger than maxSize px on its longest side (EXIF rotation
 * applied, transparency flattened onto white). Small JPEGs are kept untouched.
 * Throws if the input is not a decodable image.
 */
export async function normalizeImage(input: Buffer, maxSize: number): Promise<Buffer> {
  const meta = await sharp(input, { failOn: 'none' }).metadata();
  const fits = (meta.width ?? Infinity) <= maxSize && (meta.height ?? Infinity) <= maxSize;
  const upright = !meta.orientation || meta.orientation === 1;
  if (meta.format === 'jpeg' && fits && upright && input.length <= KEEP_AS_IS_BYTES) return input;

  return sharp(input, { failOn: 'none' })
    .rotate()
    .resize({ width: maxSize, height: maxSize, fit: 'inside', withoutEnlargement: true })
    .flatten({ background: '#ffffff' })
    .jpeg({ quality: 82, mozjpeg: true })
    .toBuffer();
}

/** Normalizes a data URL; returns the original if it cannot be decoded. */
export async function normalizeDataUrl(dataUrl: string, maxSize: number): Promise<string> {
  const parsed = parseDataUrl(dataUrl);
  if (!parsed || !parsed.mime.startsWith('image/')) return dataUrl;
  try {
    const jpeg = await normalizeImage(parsed.data, maxSize);
    return `data:image/jpeg;base64,${jpeg.toString('base64')}`;
  } catch (err) {
    console.warn('Image could not be normalized, storing as is:', (err as Error).message);
    return dataUrl;
  }
}

/** Short content hash used as cache-busting version in image URLs. */
export function imageVersion(data: string): string {
  return crypto.createHash('sha1').update(data).digest('hex').slice(0, 12);
}

export const recipeImagePath = (recipeId: string, version: string) =>
  `/api/recipes/${recipeId}/image?v=${version}`;

export const chatImagePath = (recipeId: string, messageId: string) =>
  `/api/recipes/${recipeId}/chat/${messageId}/image`;
