import { getDb } from '../db/database';
import { ChatVideo, VideoRow } from '../types';
import { analyzeVideo, GEMINI_MODEL, GeminiError, isGeminiEnabled } from './gemini';
import { fetchYouTubeMeta, youTubeThumbnail, youTubeUrl } from './youtube';

/**
 * Video analyses are cached in the `videos` table by YouTube id, so a video is
 * sent to Gemini only once — later chat messages (and other recipes linking the
 * same video) reuse the stored text.
 */

export interface ResolvedVideo {
  video: VideoRow;
  /** Why there is no analysis this time, or null if the analysis is available. */
  problem: string | null;
}

const inFlight = new Map<string, Promise<ResolvedVideo>>();

export function getVideo(id: string): VideoRow | undefined {
  return getDb().prepare('SELECT * FROM videos WHERE id = ?').get(id) as VideoRow | undefined;
}

/** Fetches title + analysis for a video, reusing the cache. Never throws. */
export function resolveVideo(id: string): Promise<ResolvedVideo> {
  // A retry after a proxy timeout must not start a second (paid) analysis.
  let pending = inFlight.get(id);
  if (!pending) {
    pending = doResolve(id).finally(() => inFlight.delete(id));
    inFlight.set(id, pending);
  }
  return pending;
}

async function doResolve(id: string): Promise<ResolvedVideo> {
  const db = getDb();
  let video = getVideo(id);

  if (!video?.title) {
    const meta = await fetchYouTubeMeta(id);
    db.prepare(`
      INSERT INTO videos (id, title, author) VALUES (?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET title = excluded.title, author = excluded.author
    `).run(id, meta.status === 'ok' ? meta.title : null, meta.status === 'ok' ? meta.author : null);
    video = getVideo(id)!;
    if (meta.status === 'unavailable') {
      return { video, problem: 'the video is private, deleted or the link is invalid' };
    }
  }

  if (video.analysis) return { video, problem: null };
  if (!isGeminiEnabled()) {
    return { video, problem: 'video analysis is not set up on this server (GEMINI_API_KEY missing)' };
  }

  try {
    const analysis = await analyzeVideo(youTubeUrl(id));
    db.prepare('UPDATE videos SET analysis = ?, analysis_model = ?, analyzed_at = ? WHERE id = ?')
      .run(analysis, GEMINI_MODEL, new Date().toISOString(), id);
    return { video: getVideo(id)!, problem: null };
  } catch (err) {
    console.error(`Video analysis failed for ${id}:`, (err as Error).message);
    return { video, problem: describeFailure(err) };
  }
}

function describeFailure(err: unknown): string {
  if (err instanceof GeminiError) {
    if (err.status === 429) return 'the daily video analysis limit is reached, try again later';
    if (err.status === 401 || err.status === 403 || err.message.includes('API key')) {
      return 'the server\'s Gemini API key is invalid';
    }
    if (err.status >= 400 && err.status < 500) return 'the video could not be opened (maybe private, age-restricted or too long)';
  }
  return 'the video analysis failed for technical reasons';
}

/** Text appended to a user message for the LLM. */
export function videoContext(video: VideoRow | undefined, problem: string | null = null): string {
  if (!video) return '';
  const name = video.title ? `"${video.title}"` : video.id;
  if (video.analysis) {
    return `\n\n[VIDEO ANALYSIS of YouTube video ${name}]\n${video.analysis}\n[/VIDEO ANALYSIS]`;
  }
  return `\n\n[YouTube video ${name}: not analyzed — ${problem ?? 'no analysis available'}]`;
}

/** Shape sent to the frontend. */
export function toChatVideo(video: VideoRow): ChatVideo {
  return {
    id: video.id,
    url: youTubeUrl(video.id),
    title: video.title,
    thumbnail_url: youTubeThumbnail(video.id),
    analyzed: !!video.analysis,
  };
}
