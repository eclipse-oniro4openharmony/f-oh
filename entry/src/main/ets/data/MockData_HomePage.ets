
export class AppInfo {
  id: number = 0;
  logo: Resource ;
  name: string | Resource ;
  desc: string | Resource ;

  constructor(id: number = 0, logo: Resource,) {
    this.id = id;
    this.logo = logo;

  }
}
export let AppInfo1: AppInfo = new AppInfo(0, $r('app.media.mock_element'));
AppInfo1.name = 'Element: Secure Messenger';
AppInfo1.desc = 'Encrypted chat for privacy and security.';

export let AppInfo2: AppInfo = new AppInfo(1, $r('app.media.mock_pdf_reader'));
AppInfo2.name = 'PDF Reader: Viewer & Editor';
AppInfo2.desc = 'Read and annotate PDF documents on the go.';

export let AppInfo3: AppInfo = new AppInfo(2, $r('app.media.mock_signal'));
AppInfo3.name = 'Signal: Private Messenger';
AppInfo3.desc = 'Privacy-focused chat app for secure communication.';

export let AppInfo4: AppInfo = new AppInfo(3, $r('app.media.mock_Wikipedia'));
AppInfo4.name = 'Wikipedia: The Free Encyclopedia';
AppInfo4.desc = 'Read and edit articles from the largest free encyclopedia.';
export let mockAppInfo: Array<AppInfo> = [AppInfo1,AppInfo2,AppInfo3,AppInfo4]