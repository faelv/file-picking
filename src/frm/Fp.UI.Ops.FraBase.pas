unit Fp.UI.Ops.FraBase;

interface

uses
  Fp.System,
  Fp.Types.LangStorage, Fp.Types.FileActions,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

type

  TFraBase = class(TFrame, ILangStorageUser)
  private
  protected
    FOperation: TFpOperation;
    procedure SetOperation(const Value: TFpOperation); virtual;
    function GetMinHeight: Integer; virtual;
  public //ILangStorageUser
    procedure OnLoadLangStrings(Node: IXMLDOMNode);
    function GetLangStorageName: String;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property MinHeight: Integer read GetMinHeight;
    property Operation: TFpOperation read FOperation write SetOperation;
    procedure Reset; virtual;
  end;

  TFraBaseClass = class of TFraBase;

implementation

{$R *.dfm}

{ TFraBase }

constructor TFraBase.Create(AOwner: TComponent);
begin
  inherited;
  Language.Storage.AddUser(Self);
  Language.Storage.ReloadSingle(Self);
end;

destructor TFraBase.Destroy;
begin
  if not Fp.System.Finalizing then
    Language.Storage.RemoveUser(Self);

  inherited;
end;

function TFraBase.GetLangStorageName: String;
begin
  Result := LowerCase(Self.Name);
end;

function TFraBase.GetMinHeight: Integer;
begin
  Result := 1;
end;

procedure TFraBase.OnLoadLangStrings(Node: IXMLDOMNode);
begin
  Language.SetComponentStrings(Self, Node);
end;

procedure TFraBase.Reset;
begin

end;

procedure TFraBase.SetOperation(const Value: TFpOperation);
begin
  FOperation := Value;
end;

end.
