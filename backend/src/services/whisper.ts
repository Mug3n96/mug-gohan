const WHISPER_URL = process.env.WHISPER_URL?.replace(/\/$/, '');

export const isWhisperEnabled = (): boolean => !!WHISPER_URL;

export async function transcribeAudio(
  buffer: Buffer,
  mimeType: string,
  originalName: string,
): Promise<string> {
  if (!WHISPER_URL) throw new Error('Whisper not configured');

  const formData = new FormData();
  const blob = new Blob([buffer], { type: mimeType });
  formData.append('audio_file', blob, originalName);

  const res = await fetch(`${WHISPER_URL}/asr?task=transcribe`, {
    method: 'POST',
    body: formData,
  });

  if (!res.ok) {
    const msg = await res.text().catch(() => res.statusText);
    throw new Error(`Whisper responded ${res.status}: ${msg}`);
  }

  return (await res.text()).trim();
}
