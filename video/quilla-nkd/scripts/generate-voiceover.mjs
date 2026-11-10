// Genera la voz en off por escena con ElevenLabs.
// Uso: ELEVENLABS_API_KEY=... node scripts/generate-voiceover.mjs
import {writeFileSync} from 'node:fs';

const VOICE_ID = 'TX3LPaxmHKxFdv7VOQHJ'; // Liam – voz predeterminada (plan gratuito)
const SCENES = [
  ['01-gancho', '¿Tu NKD merece algo común?'],
  ['02-corte', 'Cortada con láser, milímetro a milímetro, en acero inoxidable que nunca se oxida.'],
  ['03-revelacion', 'Llegó la nueva Quilla NKD ciento veinticinco Tornasol.'],
  ['04-detalles', 'Un acabado tornasol que no pasa desapercibido. Protege tu motor de golpes y piedras... con estilo.'],
  ['05-cierre', 'Moto Elite Colombia. Envíos a todo el país y pago contra entrega. ¡Pídela ya!'],
];

for (const [id, text] of SCENES) {
  const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`, {
    method: 'POST',
    headers: {'xi-api-key': process.env.ELEVENLABS_API_KEY, 'Content-Type': 'application/json', Accept: 'audio/mpeg'},
    body: JSON.stringify({text, model_id: 'eleven_multilingual_v2', language_code: 'es',
      voice_settings: {stability: 0.45, similarity_boost: 0.8, style: 0.45, use_speaker_boost: true}}),
  });
  if (!res.ok) { console.error(id, res.status, await res.text()); process.exit(1); }
  writeFileSync(`public/voiceover/${id}.mp3`, Buffer.from(await res.arrayBuffer()));
  console.log('ok', id);
}
