/**
 * YouTube link handling: detect a video in a chat message and fetch its title
 * via the official oEmbed endpoint (no API key needed).
 */

const VIDEO_ID_RE =
  /(?:youtube\.com\/(?:watch\?(?:[^\s#]*&)?v=|shorts\/|live\/|embed\/)|youtu\.be\/)([A-Za-z0-9_-]{11})(?![A-Za-z0-9_-])/;

/** Returns the 11-character video id of the first YouTube link in `text`. */
export function findYouTubeId(text: string): string | null {
  return VIDEO_ID_RE.exec(text)?.[1] ?? null;
}

export const youTubeUrl = (id: string) => `https://www.youtube.com/watch?v=${id}`;
export const youTubeThumbnail = (id: string) => `https://i.ytimg.com/vi/${id}/hqdefault.jpg`;

export type YouTubeMeta =
  | { status: 'ok'; title: string; author: string }
  | { status: 'unavailable' } // private, deleted or invalid id
  | { status: 'unknown' }; // network problem; the video may still exist

export async function fetchYouTubeMeta(id: string): Promise<YouTubeMeta> {
  const url = `https://www.youtube.com/oembed?format=json&url=${encodeURIComponent(youTubeUrl(id))}`;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (res.status >= 400 && res.status < 500) return { status: 'unavailable' };
    if (!res.ok) return { status: 'unknown' };
    const data = (await res.json()) as { title?: string; author_name?: string };
    return { status: 'ok', title: data.title ?? '', author: data.author_name ?? '' };
  } catch {
    return { status: 'unknown' };
  }
}
