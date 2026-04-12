import { describe, it, expect } from 'vitest';
import { parseLlmResponse } from '../services/parser';

describe('parseLlmResponse', () => {
  it('returns text only when no proposal block present', () => {
    const result = parseLlmResponse('Wie viele Portionen soll das Rezept ergeben?');
    expect(result.text).toBe('Wie viele Portionen soll das Rezept ergeben?');
    expect(result.proposal).toBeNull();
  });

  it('parses text and proposal correctly', () => {
    const raw = `Ich habe das Rezept aktualisiert.
---PROPOSAL---
{"title":"Spaghetti Carbonara","portions":4}
---END---`;
    const result = parseLlmResponse(raw);
    expect(result.text).toBe('Ich habe das Rezept aktualisiert.');
    expect(result.proposal).toEqual({ title: 'Spaghetti Carbonara', portions: 4 });
  });

  it('falls back to full text if JSON is invalid', () => {
    const raw = `Some text
---PROPOSAL---
{ invalid json }
---END---`;
    const result = parseLlmResponse(raw);
    expect(result.text).toBe(raw.trim());
    expect(result.proposal).toBeNull();
  });

  it('handles missing END marker gracefully', () => {
    const raw = `Some text
---PROPOSAL---
{"title":"Test"}`;
    const result = parseLlmResponse(raw);
    expect(result.text).toBe(raw.trim());
    expect(result.proposal).toBeNull();
  });
});
