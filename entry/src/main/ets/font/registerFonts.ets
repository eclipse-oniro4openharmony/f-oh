//Extract the registry of fonts into a method
import font from '@ohos.font';
import { fonts, Font } from './fonts';

export const registerAllFonts = () => {

  Object.keys(fonts).forEach((key)=>{
    const fontDetails: Font = Object(fonts)[key];
    // 注册字体
    font.registerFont({
      familyName: fontDetails.familyName,
      familySrc: fontDetails.familySrc,
    });
  })
};
