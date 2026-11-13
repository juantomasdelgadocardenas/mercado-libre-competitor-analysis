import React from 'react';
import {AbsoluteFill, Easing, interpolate, useCurrentFrame, useVideoConfig} from 'remotion';
import type {Caption} from './captions';
import {BODY_FONT, GOLD, TITLE_FONT, WHITE} from './brand';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

// Título grande que entra con un golpe de escala y desenfoque.
export const PunchTitle: React.FC<{
  lines: string[];
  goldLine?: number;
  top?: number;
  size?: number;
  delay?: number;
}> = ({lines, goldLine, top = 260, size = 132, delay = 0}) => {
  const frame = useCurrentFrame() - delay;
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill style={{top, alignItems: 'center', justifyContent: 'flex-start'}}>
      {lines.map((line, i) => {
        const f = frame - i * 0.18 * fps;
        return (
          <div
            key={line}
            style={{
              fontFamily: TITLE_FONT,
              fontSize: size,
              lineHeight: 1.02,
              letterSpacing: 2,
              textTransform: 'uppercase',
              textAlign: 'center',
              color: i === goldLine ? GOLD : WHITE,
              textShadow: '0 8px 40px rgba(0,0,0,0.85)',
              opacity: interpolate(f, [0, 0.2 * fps], [0, 1], clamp),
              scale: interpolate(f, [0, 0.35 * fps], [1.6, 1], {
                ...clamp,
                easing: Easing.bezier(0.16, 1, 0.3, 1),
              }),
              filter: `blur(${interpolate(f, [0, 0.25 * fps], [18, 0], clamp)}px)`,
            }}
          >
            {line}
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

// Etiqueta pequeña con barra dorada (ej. "CORTE LÁSER DE PRECISIÓN").
export const Tag: React.FC<{text: string; top: number; delay?: number}> = ({text, top, delay = 0}) => {
  const frame = useCurrentFrame() - delay;
  const {fps} = useVideoConfig();
  const p = interpolate(frame, [0, 0.4 * fps], [0, 1], {...clamp, easing: Easing.bezier(0.16, 1, 0.3, 1)});
  return (
    <AbsoluteFill style={{top, alignItems: 'center'}}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 22,
          padding: '18px 34px',
          background: 'rgba(11,11,11,0.72)',
          borderLeft: `8px solid ${GOLD}`,
          fontFamily: BODY_FONT,
          fontWeight: 800,
          fontSize: 44,
          letterSpacing: 6,
          color: WHITE,
          opacity: p,
          translate: `${interpolate(p, [0, 1], [-80, 0])}px 0`,
        }}
      >
        {text}
      </div>
    </AbsoluteFill>
  );
};

// Subtítulos palabra por palabra; la palabra activa se pinta en dorado.
const KEYWORDS = ['nkd', 'láser', 'inoxidable', 'tornasol', 'motor', 'estilo', 'elite', 'pídela'];

export const Captions: React.FC<{captions: Caption[]; offsetMs: number}> = ({captions, offsetMs}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const nowMs = (frame / fps) * 1000 - offsetMs;

  // Agrupa en páginas de máximo 4 palabras para que se lea rápido.
  const pages: Caption[][] = [];
  captions.forEach((c, i) => {
    if (i % 4 === 0) pages.push([]);
    pages[pages.length - 1].push(c);
  });
  const page = pages.find((p, i) => {
    const end = pages[i + 1] ? pages[i + 1][0].startMs : p[p.length - 1].endMs + 600;
    return nowMs >= p[0].startMs - 80 && nowMs < end;
  });
  if (!page) return null;

  return (
    <AbsoluteFill style={{justifyContent: 'flex-end', alignItems: 'center', paddingBottom: 330}}>
      <div
        style={{
          maxWidth: 940,
          textAlign: 'center',
          fontFamily: BODY_FONT,
          fontWeight: 800,
          fontSize: 70,
          lineHeight: 1.15,
          textTransform: 'uppercase',
        }}
      >
        {page.map((w) => {
          const active = nowMs >= w.startMs && nowMs < w.endMs + 120;
          const clean = w.text.trim().toLowerCase().replace(/[¿?¡!.,]/g, '');
          const key = KEYWORDS.includes(clean);
          return (
            <span
              key={w.startMs}
              style={{
                color: active || key ? GOLD : WHITE,
                display: 'inline-block',
                margin: '0 14px',
                scale: active ? 1.06 : 1,
                WebkitTextStroke: '3px rgba(0,0,0,0.9)',
                paintOrder: 'stroke fill',
                textShadow: '0 6px 24px rgba(0,0,0,0.9)',
              }}
            >
              {w.text.trim()}
            </span>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

// Viñeta y grano para un look más cinematográfico.
export const Vignette: React.FC = () => (
  <AbsoluteFill
    style={{
      background:
        'radial-gradient(ellipse at center, rgba(0,0,0,0) 45%, rgba(0,0,0,0.55) 80%, rgba(0,0,0,0.85) 100%)',
      pointerEvents: 'none',
    }}
  />
);

// Destello blanco/dorado en los cortes.
export const Flash: React.FC<{color?: string}> = ({color = WHITE}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill
      style={{
        backgroundColor: color,
        opacity: interpolate(frame, [0, 0.03 * fps, 0.35 * fps], [0, 0.9, 0], clamp),
        mixBlendMode: 'screen',
      }}
    />
  );
};
