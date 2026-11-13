import locucion from '../public/captions/locucion.json';

export type Caption = {
  text: string;
  startMs: number;
  endMs: number;
  timestampMs: number | null;
  confidence: number | null;
};

// Tiempos por palabra de la locución completa (transcrita con ElevenLabs).
export const CAPTIONS = locucion as Caption[];

// Palabras dentro de un tramo de la locución, en segundos.
export const captionsBetween = (fromS: number, toS: number) =>
  CAPTIONS.filter((c) => c.startMs >= fromS * 1000 - 50 && c.startMs < toS * 1000 - 50);
