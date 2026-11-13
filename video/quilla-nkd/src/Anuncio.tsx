import React from 'react';
import {Audio, Video} from '@remotion/media';
import {
  AbsoluteFill,
  Easing,
  Img,
  Sequence,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {BLACK, BODY_FONT, GOLD, IRIDESCENT, TITLE_FONT, WHITE} from './brand';
import {captionsBetween} from './captions';
import {Captions, Flash, PunchTitle, Tag, Vignette} from './components';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const cover: React.CSSProperties = {width: '100%', height: '100%', objectFit: 'cover'};
// Los clips de corte son 3:4; se escalan a lo alto y se centran para llenar el 9:16.
const cover34: React.CSSProperties = {position: 'absolute', height: 1920, width: 1440, left: -180, top: 0};

// Tiempos de cada escena en segundos, alineados con las frases de la locución.
// La música tiene el golpe fuerte en la revelación (9,24 s).
export const SCENES = {
  gancho: {from: 0, dur: 2.78},
  corte: {from: 2.78, dur: 6.46},
  revelacion: {from: 9.24, dur: 4.32},
  detalles: {from: 13.56, dur: 7.12},
  cierre: {from: 20.68, dur: 7.28},
};
export const TOTAL_SECONDS = 27.96;
const VO_DELAY = 0.2; // la locución entra 0,2 s después del inicio del vídeo

const Voice: React.FC = () => {
  const {fps} = useVideoConfig();
  return (
    <Sequence from={Math.round(VO_DELAY * fps)} name="Locución">
      <Audio src={staticFile('voiceover/locucion.mp3')} volume={1} />
    </Sequence>
  );
};

// Zoom lento continuo (efecto "Ken Burns").
const SlowZoom: React.FC<{children: React.ReactNode; from?: number; to?: number; origin?: string}> = ({
  children,
  from = 1.05,
  to = 1.18,
  origin = '50% 50%',
}) => {
  const frame = useCurrentFrame();
  const {durationInFrames} = useVideoConfig();
  return (
    <AbsoluteFill
      style={{
        transformOrigin: origin,
        scale: interpolate(frame, [0, durationInFrames], [from, to], clamp),
      }}
    >
      {children}
    </AbsoluteFill>
  );
};

const Gancho: React.FC = () => {
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill style={{backgroundColor: BLACK}}>
      <SlowZoom from={1.35} to={1.55} origin="45% 40%">
        <Video src={staticFile('media/corte1.mp4')} trimBefore={Math.round(5.5 * fps)} muted style={{...cover34, filter: 'brightness(0.55) saturate(1.3)'}} />
      </SlowZoom>
      <Vignette />
      <PunchTitle lines={['Lo que merece', 'tu NKD']} goldLine={1} top={620} size={150} delay={3} />
    </AbsoluteFill>
  );
};

const Corte: React.FC = () => {
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill style={{backgroundColor: BLACK}}>
      <Sequence durationInFrames={Math.round(3.3 * fps)} name="Corte láser">
        <SlowZoom from={1.1} to={1.25} origin="45% 35%">
          <Video src={staticFile('media/corte1.mp4')} trimBefore={Math.round(1.5 * fps)} muted style={{...cover34, filter: 'contrast(1.1) saturate(1.2)'}} />
        </SlowZoom>
        <Tag text="CORTE LÁSER DE PRECISIÓN" top={300} delay={6} />
      </Sequence>
      <Sequence from={Math.round(3.3 * fps)} name="Lámina tornasol">
        <SlowZoom from={1.08} to={1.22}>
          <Video src={staticFile('media/corte2.mp4')} trimBefore={Math.round(0.5 * fps)} muted style={{...cover34, filter: 'contrast(1.1) saturate(1.25)'}} />
        </SlowZoom>
        <Tag text="ACERO INOXIDABLE" top={300} delay={4} />
        <Tag text="NUNCA SE OXIDA" top={400} delay={12} />
        <Flash />
      </Sequence>
      <Vignette />
    </AbsoluteFill>
  );
};

const Revelacion: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill style={{backgroundColor: BLACK}}>
      <AbsoluteFill
        style={{
          scale: interpolate(frame, [0, 0.5 * fps, 4.2 * fps], [1.35, 1.08, 1.0], {
            ...clamp,
            easing: Easing.bezier(0.16, 1, 0.3, 1),
          }),
        }}
      >
        <Video src={staticFile('media/producto.mp4')} playbackRate={0.85} muted style={{...cover, filter: 'contrast(1.08) saturate(1.25)'}} />
      </AbsoluteFill>
      <AbsoluteFill style={{background: 'linear-gradient(180deg, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.5) 25%, rgba(0,0,0,0) 42%, rgba(0,0,0,0) 65%, rgba(0,0,0,0.7) 100%)'}} />
      <PunchTitle lines={['Nueva']} top={170} size={90} delay={4} />
      <PunchTitle lines={['Quilla NKD 125']} top={265} size={150} delay={8} />
      <AbsoluteFill style={{top: 420, alignItems: 'center'}}>
        <div
          style={{
            fontFamily: TITLE_FONT,
            fontSize: 170,
            lineHeight: 1,
            letterSpacing: 8,
            backgroundImage: IRIDESCENT,
            backgroundSize: '200% 100%',
            backgroundPosition: `${interpolate(frame, [0, 4.2 * fps], [0, 100])}% 0`,
            WebkitBackgroundClip: 'text',
            backgroundClip: 'text',
            color: 'transparent',
            WebkitTextStroke: '3px rgba(255,255,255,0.9)',
            filter: 'drop-shadow(0 8px 30px rgba(0,0,0,0.9))',
            opacity: interpolate(frame, [16, 24], [0, 1], clamp),
            scale: interpolate(frame, [16, 28], [1.4, 1], {...clamp, easing: Easing.bezier(0.16, 1, 0.3, 1)}),
          }}
        >
          TORNASOL
        </div>
      </AbsoluteFill>
      <Vignette />
      <Flash color={GOLD} />
    </AbsoluteFill>
  );
};

const FOTOS = [
  {src: 'media/foto1.jpg', tag: 'ACABADO TORNASOL', origin: '50% 40%'},
  {src: 'media/foto2.jpg', tag: 'PROTEGE TU MOTOR', origin: '40% 55%'},
  {src: 'media/foto3.jpg', tag: 'DISEÑO EXCLUSIVO', origin: '75% 35%'},
];

const Detalles: React.FC = () => {
  const {fps} = useVideoConfig();
  const each = Math.round(2.37 * fps);
  return (
    <AbsoluteFill style={{backgroundColor: BLACK}}>
      {FOTOS.map((f, i) => (
        <Sequence key={f.src} from={i * each} durationInFrames={i === FOTOS.length - 1 ? undefined : each} name={f.tag}>
          <SlowZoom from={1.0} to={1.2} origin={f.origin}>
            <Img src={staticFile(f.src)} style={{...cover, filter: 'contrast(1.06) saturate(1.2)'}} />
          </SlowZoom>
          <AbsoluteFill style={{background: 'linear-gradient(180deg, rgba(0,0,0,0.6) 0%, rgba(0,0,0,0) 30%, rgba(0,0,0,0) 60%, rgba(0,0,0,0.75) 100%)'}} />
          <Tag text={f.tag} top={260} delay={3} />
          <Flash />
          <Audio src={staticFile('sfx/whoosh.wav')} volume={0.35} />
        </Sequence>
      ))}
      <Vignette />
    </AbsoluteFill>
  );
};

const Cierre: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const line = (i: number): React.CSSProperties => ({
    opacity: interpolate(frame, [(0.6 + i * 0.25) * fps, (0.9 + i * 0.25) * fps], [0, 1], clamp),
    translate: `0 ${interpolate(frame, [(0.6 + i * 0.25) * fps, (0.9 + i * 0.25) * fps], [30, 0], clamp)}px`,
  });
  return (
    <AbsoluteFill style={{backgroundColor: BLACK}}>
      <AbsoluteFill style={{opacity: 0.28, filter: 'blur(14px)', scale: 1.15}}>
        <Img src={staticFile('media/foto2.jpg')} style={cover} />
      </AbsoluteFill>
      <AbsoluteFill style={{background: 'radial-gradient(ellipse at 50% 35%, rgba(198,166,100,0.18) 0%, rgba(11,11,11,0.92) 65%)'}} />
      <AbsoluteFill style={{alignItems: 'center', top: 380}}>
        <div
          style={{
            fontFamily: TITLE_FONT,
            fontSize: 190,
            color: GOLD,
            letterSpacing: 6,
            lineHeight: 1,
            opacity: interpolate(frame, [0, 0.3 * fps], [0, 1], clamp),
            scale: interpolate(frame, [0, 0.45 * fps], [1.5, 1], {...clamp, easing: Easing.bezier(0.16, 1, 0.3, 1)}),
            textShadow: '0 0 60px rgba(198,166,100,0.45)',
          }}
        >
          MOTO ELITE
        </div>
        <div
          style={{
            fontFamily: BODY_FONT,
            fontWeight: 600,
            fontSize: 46,
            letterSpacing: interpolate(frame, [0, 0.8 * fps], [4, 24], clamp),
            color: WHITE,
            marginTop: 10,
            opacity: interpolate(frame, [0.2 * fps, 0.6 * fps], [0, 1], clamp),
          }}
        >
          COLOMBIA
        </div>
        <div style={{width: interpolate(frame, [0.3 * fps, 0.9 * fps], [0, 520], clamp), height: 4, background: GOLD, margin: '46px 0'}} />
        <div style={{fontFamily: BODY_FONT, fontWeight: 800, fontSize: 50, color: WHITE, textAlign: 'center', lineHeight: 1.5}}>
          <div style={line(0)}>
            ENVÍO <span style={{color: GOLD}}>GRATIS</span> DESDE $200.000
          </div>
          <div style={line(1)}>PAGO CONTRA ENTREGA</div>
          <div style={{...line(2), marginTop: 30, fontSize: 56, color: GOLD}}>WhatsApp 323 907 7291</div>
          <div style={{...line(3), fontWeight: 600, fontSize: 42, opacity: 0.85 * Number(line(3).opacity)}}>motoelitecolombia.com</div>
        </div>
      </AbsoluteFill>
      <Flash color={GOLD} />
    </AbsoluteFill>
  );
};

export const Anuncio: React.FC = () => {
  const {fps} = useVideoConfig();
  const s = (k: keyof typeof SCENES) => ({
    from: Math.round(SCENES[k].from * fps),
    durationInFrames: Math.round(SCENES[k].dur * fps),
  });
  const voMs = VO_DELAY * 1000;

  return (
    <AbsoluteFill style={{backgroundColor: BLACK}}>
      <Sequence {...s('gancho')} name="1. Gancho">
        <Gancho />
      </Sequence>
      <Sequence {...s('corte')} name="2. Corte láser">
        <Corte />
        <Captions captions={captionsBetween(SCENES.corte.from, SCENES.revelacion.from)} offsetMs={voMs - SCENES.corte.from * 1000} />
      </Sequence>
      <Sequence {...s('revelacion')} name="3. Revelación">
        <Revelacion />
        <Audio src={staticFile('sfx/impact.wav')} volume={0.4} />
      </Sequence>
      <Sequence {...s('detalles')} name="4. Detalles">
        <Detalles />
        <Captions captions={captionsBetween(SCENES.detalles.from, SCENES.cierre.from)} offsetMs={voMs - SCENES.detalles.from * 1000} />
      </Sequence>
      <Sequence {...s('cierre')} name="5. Cierre">
        <Cierre />
        <Audio src={staticFile('sfx/impact.wav')} volume={0.5} />
      </Sequence>

      <Voice />

      {/* Audio de fondo */}
      <Sequence name="Láser (sfx)" durationInFrames={Math.round(4 * fps)}>
        <Audio src={staticFile('sfx/laser.wav')} volume={0.4} />
      </Sequence>
      <Sequence from={Math.round(2.3 * fps)} name="Whoosh" durationInFrames={Math.round(1 * fps)}>
        <Audio src={staticFile('sfx/whoosh.wav')} volume={0.4} />
      </Sequence>
      <Audio
        src={staticFile('music/beat.wav')}
        name="Música"
        volume={(f) => interpolate(f, [0, 9.24 * fps - 1, 9.24 * fps, 13.36 * fps, 13.76 * fps, 26.76 * fps, TOTAL_SECONDS * fps], [0.3, 0.3, 0.16, 0.16, 0.24, 0.24, 0], clamp)}
      />
    </AbsoluteFill>
  );
};
