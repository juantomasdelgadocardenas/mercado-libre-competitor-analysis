import {loadFont as loadAnton} from '@remotion/google-fonts/Anton';
import {loadFont as loadMontserrat} from '@remotion/google-fonts/Montserrat';

// Colores tomados de motoelitecolombia.com
export const GOLD = '#C6A664';
export const BLACK = '#0B0B0B';
export const WHITE = '#FFFFFF';
// Tonos del acabado tornasol del producto
export const IRIDESCENT = 'linear-gradient(100deg, #7B2FF7 0%, #3B5BFF 40%, #19C2C9 75%, #C6A664 100%)';

export const {fontFamily: TITLE_FONT} = loadAnton('normal', {weights: ['400'], subsets: ['latin']});
export const {fontFamily: BODY_FONT} = loadMontserrat('normal', {
  weights: ['600', '800'],
  subsets: ['latin'],
});
