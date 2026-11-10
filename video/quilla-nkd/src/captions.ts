import gancho from '../public/captions/01-gancho.json';
import corte from '../public/captions/02-corte.json';
import revelacion from '../public/captions/03-revelacion.json';
import detalles from '../public/captions/04-detalles.json';
import cierre from '../public/captions/05-cierre.json';

export type Caption = {
  text: string;
  startMs: number;
  endMs: number;
  timestampMs: number | null;
  confidence: number | null;
};

// Tiempos por palabra obtenidos transcribiendo la voz en off con ElevenLabs.
export const CAPTIONS = {
  gancho: gancho as Caption[],
  corte: corte as Caption[],
  revelacion: revelacion as Caption[],
  detalles: detalles as Caption[],
  cierre: cierre as Caption[],
};
