unit Fp.UI.FraProps;

interface

uses
  Fp.System,
  Fp.Types.LangStorage, Fp.Types.FileActions,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls;

type

  TFraProps = class(TFrame, ILangStorageUser)
    Image1: TImage;
    lblName: TLabel;
    edtName: TEdit;
    Image2: TImage;
    lblDescr: TLabel;
    memDescr: TMemo;
    procedure edtNameExit(Sender: TObject);
    procedure memDescrExit(Sender: TObject);
  private
    FSequence: TFpSequence;
    procedure ReadSequenceProperties;
    procedure SetSequence(const Value: TFpSequence);
    procedure ResetUI;
  public //ILangStorageUser
    procedure OnLoadLangStrings(Node: IXMLDOMNode);
    function GetLangStorageName: String;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Sequence: TFpSequence read FSequence write SetSequence;
  end;

implementation

{$R *.dfm}

{ TFraProps }

constructor TFraProps.Create(AOwner: TComponent);
begin
  inherited;

  Language.Storage.AddUser(Self);
  Language.Storage.ReloadSingle(Self);

  Self.Align := alClient;
end;

destructor TFraProps.Destroy;
begin
  inherited;
end;

procedure TFraProps.edtNameExit(Sender: TObject);
begin
  if Assigned(FSequence) then
    FSequence.Name := edtName.Text;
end;

function TFraProps.GetLangStorageName: String;
begin
  Result := 'fraprops'
end;

procedure TFraProps.memDescrExit(Sender: TObject);
begin
  if Assigned(FSequence) then
    FSequence.Description := memDescr.Lines.Text;
end;

procedure TFraProps.OnLoadLangStrings(Node: IXMLDOMNode);
begin
  Language.SetComponentStrings(Self, Node);
end;

procedure TFraProps.ReadSequenceProperties;
begin
  if not Assigned(FSequence) then exit;

  edtName.Text := FSequence.Name;
  memDescr.Lines.Text := FSequence.Description;
end;

procedure TFraProps.ResetUI;
begin
  edtName.Clear;
  memDescr.Lines.Clear;
end;

procedure TFraProps.SetSequence(const Value: TFpSequence);
begin
  FSequence := Value;
  Self.ResetUI;
  Self.ReadSequenceProperties;
end;

end.
