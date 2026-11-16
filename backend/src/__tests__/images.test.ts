import { describe, expect, it } from 'vitest';
import sharp from 'sharp';
import { imageVersion, normalizeDataUrl, normalizeImage, parseDataUrl } from '../services/images';

const png = (w: number, h: number) =>
  sharp({ create: { width: w, height: h, channels: 4, background: { r: 200, g: 80, b: 40, alpha: 0.5 } } })
    .png()
    .toBuffer();

describe('normalizeImage', () => {
  it('turns a large PNG into a JPEG within the size limit', async () => {
    const out = await normalizeImage(await png(3000, 2000), 1200);
    const meta = await sharp(out).metadata();
    expect(meta.format).toBe('jpeg');
    expect([meta.width, meta.height]).toEqual([1200, 800]);
  });

  it('does not enlarge small images', async () => {
    const meta = await sharp(await normalizeImage(await png(300, 200), 1200)).metadata();
    expect([meta.width, meta.height]).toEqual([300, 200]);
  });

  it('keeps a small JPEG byte-for-byte', async () => {
    const jpeg = await sharp(await png(400, 300)).flatten().jpeg().toBuffer();
    expect(await normalizeImage(jpeg, 1200)).toBe(jpeg);
  });

  it('rejects data that is not an image', async () => {
    await expect(normalizeImage(Buffer.from('not an image'), 1200)).rejects.toThrow();
  });
});

describe('data URLs', () => {
  it('parses and normalizes', async () => {
    const url = `data:image/png;base64,${(await png(2000, 1000)).toString('base64')}`;
    expect(parseDataUrl(url)?.mime).toBe('image/png');
    const out = await normalizeDataUrl(url, 1200);
    expect(out.startsWith('data:image/jpeg;base64,')).toBe(true);
    expect(out.length).toBeLessThan(url.length);
  });

  it('leaves undecodable data URLs alone', async () => {
    const url = 'data:image/png;base64,AAAA';
    expect(await normalizeDataUrl(url, 1200)).toBe(url);
  });

  it('versions by content', () => {
    expect(imageVersion('a')).toHaveLength(12);
    expect(imageVersion('a')).not.toBe(imageVersion('b'));
  });
});
