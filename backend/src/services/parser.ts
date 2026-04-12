import { Recipe } from '../types';

const PROPOSAL_START = '---PROPOSAL---';
const PROPOSAL_END = '---END---';

export interface ParsedResponse {
  text: string;
  proposal: Partial<Recipe> | null;
}

export function parseLlmResponse(raw: string): ParsedResponse {
  const startIdx = raw.indexOf(PROPOSAL_START);
  const endIdx = raw.indexOf(PROPOSAL_END);

  if (startIdx === -1 || endIdx === -1 || endIdx < startIdx) {
    return { text: raw.trim(), proposal: null };
  }

  const text = raw.slice(0, startIdx).trim();
  const jsonStr = raw.slice(startIdx + PROPOSAL_START.length, endIdx).trim();

  try {
    const proposal = JSON.parse(jsonStr) as Partial<Recipe>;
    return { text, proposal };
  } catch {
    return { text: raw.trim(), proposal: null };
  }
}
