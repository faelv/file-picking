unit Fp.UI.FrmAbout;

interface

uses

  Fp.System,
  Fp.Resources.Definitions,
  Fp.Types.LangStorage,
  Fp.Utils.Shell,
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage;

type

  TFrmAbout = class(TForm, ILangStorageUser)
    Panel1: TPanel;
    btnOk: TButton;
    lblAppTitle: TLabel;
    lblVersion: TLabel;
    lblAppDescr: TLabel;
    Image1: TImage;
    LinkLabel1: TLinkLabel;
    lblDev: TLinkLabel;
    procedure FormCreate(Sender: TObject);
    procedure LinkLabel1LinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
  private
    { Private declarations }
  public //ILangStorageUser
    procedure OnLoadLangStrings(Node: IXMLDOMNode);
    function GetLangStorageName: String;
  public
    { Public declarations }
  end;

var
  FrmAbout: TFrmAbout;

implementation

{$R *.dfm}

{ TFrmAbout }

procedure TFrmAbout.FormCreate(Sender: TObject);
begin
  lblAppTitle.Caption := APP_TITLE;
  lblVersion.Caption := APP_VERSION;
  lblDev.Caption := APP_DEVELOPER;

  Language.Storage.AddUser(Self);
  Language.Storage.ReloadSingle(Self);
end;

function TFrmAbout.GetLangStorageName: String;
begin
  Result := 'frmabout';
end;

procedure TFrmAbout.LinkLabel1LinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  OpenURL(Link);
end;

procedure TFrmAbout.OnLoadLangStrings(Node: IXMLDOMNode);
begin
  Language.SetComponentStrings(Self, Node);
  lblAppDescr.Caption := Language.Strings('APP_DESCR');
end;

end.
