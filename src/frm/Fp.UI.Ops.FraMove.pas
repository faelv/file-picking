unit Fp.UI.Ops.FraMove;

interface

uses
  Fp.System,
  Fp.Utils.Shell,
  Fp.Resources.ImageLists,
  Fp.UI.Ops.FraBase,
  Fp.Types.FileActions,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type

  TFraMove = class(TFraBase)
    Label1: TLabel;
    bedtDestDirectory: TButtonedEdit;
    cboOnFileExists: TComboBox;
    lblOnFileExists: TLabel;
    procedure bedtDestDirectoryRightButtonClick(Sender: TObject);
    procedure cboOnFileExistsSelect(Sender: TObject);
    procedure bedtDestDirectoryExit(Sender: TObject);
    private
    protected
      procedure SetOperation(const Value: TFpOperation); override;
      function GetMinHeight: Integer; override;
    public
      procedure Reset; override;
  end;

implementation

{$R *.dfm}

{ TFraMove }

procedure TFraMove.bedtDestDirectoryExit(Sender: TObject);
begin
  if Assigned(FOperation) then
    TFpOperationMove(FOperation).DestinationFolder := bedtDestDirectory.Text;
end;

procedure TFraMove.bedtDestDirectoryRightButtonClick(Sender: TObject);
var
  folder: String;
begin
  if not BrowseForFolder(Language.Strings('selDestDirectory'), folder, Self.Handle) then exit;
  bedtDestDirectory.Text := folder;
end;

procedure TFraMove.cboOnFileExistsSelect(Sender: TObject);
begin
  if Assigned(FOperation) and (cboOnFileExists.ItemIndex >= 0) then
    TFpOperationMove(FOperation).ConflictDecision := TFpMoveDecision(cboOnFileExists.ItemIndex);
end;

function TFraMove.GetMinHeight: Integer;
begin
  Result := 93;
end;

procedure TFraMove.Reset;
begin
  FOperation := nil;
  bedtDestDirectory.Clear;
  cboOnFileExists.ItemIndex := Ord(mdOverwrite);
end;

procedure TFraMove.SetOperation(const Value: TFpOperation);
begin
  inherited;
  if not(Value is TFpOperationMove) then begin
    Self.Reset;
    exit;
  end;
  bedtDestDirectory.Text := TFpOperationMove(Value).DestinationFolder;
  cboOnFileExists.ItemIndex := Ord(TFpOperationMove(Value).ConflictDecision);
end;

end.
