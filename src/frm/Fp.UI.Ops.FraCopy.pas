unit Fp.UI.Ops.FraCopy;

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

  TFraCopy = class(TFraBase)
    Label1: TLabel;
    bedtDestDirectory: TButtonedEdit;
    cboOnFileExists: TComboBox;
    lblOnFileExists: TLabel;
    procedure bedtDestDirectoryRightButtonClick(Sender: TObject);
    procedure bedtDestDirectoryExit(Sender: TObject);
    procedure cboOnFileExistsSelect(Sender: TObject);
    private
    protected
      procedure SetOperation(const Value: TFpOperation); override;
      function GetMinHeight: Integer; override;
    public
      procedure Reset; override;
  end;

implementation

{$R *.dfm}

{ TFraCopy }

procedure TFraCopy.bedtDestDirectoryExit(Sender: TObject);
begin
  if Assigned(FOperation) then
    TFpOperationCopy(FOperation).DestinationFolder := bedtDestDirectory.Text;
end;

procedure TFraCopy.bedtDestDirectoryRightButtonClick(Sender: TObject);
var
  folder: String;
begin
  if not BrowseForFolder(Language.Strings('selDestDirectory'), folder, Self.Handle) then exit;
  bedtDestDirectory.Text := folder;
end;

procedure TFraCopy.cboOnFileExistsSelect(Sender: TObject);
begin
  if Assigned(FOperation) and (cboOnFileExists.ItemIndex >= 0) then
    TFpOperationCopy(FOperation).ConflictDecision := TFpCopyDecision(cboOnFileExists.ItemIndex);
end;

function TFraCopy.GetMinHeight: Integer;
begin
  Result := 93;
end;

procedure TFraCopy.Reset;
begin
  FOperation := nil;
  bedtDestDirectory.Clear;
  cboOnFileExists.ItemIndex := Ord(cdOverwrite);
end;

procedure TFraCopy.SetOperation(const Value: TFpOperation);
begin
  inherited;
  if not(Value is TFpOperationCopy) then begin
    Self.Reset;
    exit;
  end;
  bedtDestDirectory.Text := TFpOperationCopy(Value).DestinationFolder;
  cboOnFileExists.ItemIndex := Ord(TFpOperationCopy(Value).ConflictDecision);
end;

end.
