import { describe, expect, it } from 'vitest';
import { findYouTubeId } from '../services/youtube';
import { videoContext } from '../services/videos';
import { VideoRow } from '../types';

describe('findYouTubeId', () => {
  it.each([
    ['https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'dQw4w9WgXcQ'],
    ['schau mal https://youtube.com/watch?feature=share&v=dQw4w9WgXcQ&t=42s', 'dQw4w9WgXcQ'],
    ['https://m.youtube.com/watch?v=dQw4w9WgXcQ', 'dQw4w9WgXcQ'],
    ['https://youtu.be/dQw4w9WgXcQ?si=abc', 'dQw4w9WgXcQ'],
    ['https://www.youtube.com/shorts/a1B2c3D4e5_', 'a1B2c3D4e5_'],
    ['youtube.com/live/a1B2c3D4e5-', 'a1B2c3D4e5-'],
  ])('finds the id in %s', (text, id) => {
    expect(findYouTubeId(text)).toBe(id);
  });

  it.each([
    'Mach die Nudeln auf 500g',
    'https://www.youtube.com/@somechannel',
    'https://vimeo.com/123456789',
    'https://youtu.be/tooShort',
    'https://youtu.be/dQw4w9WgXcQextra',
  ])('ignores %s', text => {
    expect(findYouTubeId(text)).toBeNull();
  });
});

describe('videoContext', () => {
  const base: VideoRow = {
    id: 'dQw4w9WgXcQ', title: 'Pasta', author: 'Chef', analysis: null,
    analysis_model: null, analyzed_at: null, created_at: '',
  };

  it('embeds the cached analysis', () => {
    const ctx = videoContext({ ...base, analysis: 'TITLE: Pasta' });
    expect(ctx).toContain('[VIDEO ANALYSIS of YouTube video "Pasta"]');
    expect(ctx).toContain('TITLE: Pasta');
  });

  it('explains a missing analysis', () => {
    expect(videoContext(base, 'limit reached')).toContain('not analyzed — limit reached');
  });

  it('is empty without a video', () => {
    expect(videoContext(undefined)).toBe('');
  });
});
