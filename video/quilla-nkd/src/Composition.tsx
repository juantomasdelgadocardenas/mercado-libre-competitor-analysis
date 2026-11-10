import {Composition} from 'remotion';
import {Anuncio, TOTAL_SECONDS} from './Anuncio';

const FPS = 30;

export const MyComposition = () => {
  return (
    <Composition
      id="QuillaNKD"
      component={Anuncio}
      durationInFrames={Math.round(TOTAL_SECONDS * FPS)}
      fps={FPS}
      width={1080}
      height={1920}
    />
  );
};
