//Extract the registry of fonts into a method
import font from '@ohos.font';
import fonts from './fonts';

export const registerAllFonts = () => {
  for (const key in fonts) {
    const fontDetails = fonts[key];
    font.registerFont({
      familyName: fontDetails.familyName,
      familySrc: fontDetails.familySrc,
    });
  }
};
