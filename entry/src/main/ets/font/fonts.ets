
// 定义 Font 接口
export interface Font {
  familyName: string;
  familySrc: string;
}

// 定义 Fonts 对象的接口
// 定义具体的 Fonts 对象类型
interface Fonts {
  semi_bold: Font;
  bold: Font;
  medium: Font;
  light: Font;
  regular: Font;
  extraBold: Font;
  italic: Font;
}

//define fonts as lists of objects
export const fonts: Fonts = {
  semi_bold: {
    familyName: 'SemiBold',
    familySrc: '/font/PlusJakartaSans-semiBold.ttf',
  },
  bold: {
    familyName: 'Bold',
    familySrc: '/font/PlusJakartaSans-Bold.ttf',
  },
  medium:{
    familyName: 'Medium',
    familySrc: '/font/PlusJakartaSans-Medium.ttf',
  },
  light: {
    familyName: 'Light',
    familySrc: '/font/PlusJakartaSans-Light.ttf',
  },
  regular: {
    familyName: 'Regular',
    familySrc: '/font/PlusJakartaSans-Regular.ttf',
  },
  extraBold: {
    familyName: 'ExtraBold',
    familySrc: '/font/PlusJakartaSans-ExtraBold.ttf',
  },
  italic:{
    familyName: 'Italic',
    familySrc: '/font/PlusJakartaSans-Italic.ttf',
  }
};

// export default fonts;
