unit FP.UI.FraStatus;

interface

uses
  Fp.System,
  Fp.Utils.General,
  Fp.Resources.Definitions, Fp.Resources.ImageLists, Fp.Resources.Notifications,
  Fp.Types.LangStorage, Fp.Types.General, Fp.Types.Notifications, Fp.Types.Storage,
  Fp.Types.SequenceExecutor,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, System.DateUtils, Vcl.ComCtrls, System.IOUtils, VirtualTrees;

const

  SH_NAME   = 0;
  SH_STATUS = 1;
  SH_SOURCE = 2;
  SH_DEST   = 3;
  SH_TYPE   = 4;
  SH_PROG   = 5;

  ST_ERROR = -1;
  ST_NOPRG = -2;

type

  TStatusItem = record
    FileName: String;
    Status: String;
    Source: String;
    Destination: String;
    FileType: String;
    Progress: Integer;
    ID: Integer;
    ImageIndex: Integer;
    ActionNode: Boolean;
  end;
  PStatusItem = ^TStatusItem;

  TFraStatus = class(TFrame, ILangStorageUser, INotificationListener, IXmlStorageUser)
    pnlBottom: TPanel;
    Image1: TImage;
    lblTimeElapsed: TLabel;
    sttTimeElapsed: TStaticText;
    Image2: TImage;
    lblTimeRemaining: TLabel;
    sttTimeRemaining: TStaticText;
    tmrUpdate: TTimer;
    sttSpeed: TStaticText;
    Image3: TImage;
    lblSpeed: TLabel;
    Image4: TImage;
    lblProgress: TLabel;
    sttProgress: TStaticText;
    pbProgress: TProgressBar;
    pnlBottomInfo: TPanel;
    imgBottomInfo: TImage;
    lblBottomInfo: TLabel;
    btnReset: TButton;
    vstStatus: TVirtualStringTree;
    chkShowIgnored: TCheckBox;
    chkCleanActions: TCheckBox;
    procedure tmrUpdateTimer(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure vstStatusFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstStatusGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure vstStatusGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: Integer);
    procedure vstStatusPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas;
      Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
    procedure vstStatusBeforeCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
      Node: PVirtualNode; Column: TColumnIndex; CellPaintMode: TVTCellPaintMode;
      CellRect: TRect; var ContentRect: TRect);
    procedure chkShowIgnoredClick(Sender: TObject);
    procedure chkCleanActionsClick(Sender: TObject);
  private
    FFmtSettings: TFormatSettings;
    FTimeElapsed: TTime;
    FLangOf: String;
    FLastActNode: PVirtualNode;
    FLastOpID: Integer;
    FUpdtDelay, FTreeDelay: Integer;
    FShowSkiped, FCleanActions: Boolean;
    procedure UpdateProgress;
    procedure ShowBottomInfo(const Text: String);
  public //ILangStorageUser, INotificationListener
    procedure OnLoadLangStrings(Node: IXMLDOMNode);
    function GetLangStorageName: String;
    procedure NotificationListNotification(Msg: Integer; const Params: array of const; Sender: TObject; var StopBrodcast: Boolean);
    procedure NotificationListAdded(const NotificationList: TNotificationList);
    procedure NotificationListRemoved;
    procedure OnNodeLoad(Node: IXMLDOMNode);
    procedure OnNodeSave(Node: IXMLDOMNode);
    function GetStorageName: String;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ResetUI;
  end;

  TVSTHelper = class helper for TVirtualStringTree
    public
      function FindID(const ID: Integer): PVirtualNode;
  end;

implementation

{$R *.dfm}

{ TFraStatus }

procedure TFraStatus.btnResetClick(Sender: TObject);
begin
  Self.ResetUI;
end;

procedure TFraStatus.chkCleanActionsClick(Sender: TObject);
begin
  FCleanActions := TCheckBox(Sender).Checked;
end;

procedure TFraStatus.chkShowIgnoredClick(Sender: TObject);
begin
  FShowSkiped := TCheckBox(Sender).Checked;
end;

constructor TFraStatus.Create(AOwner: TComponent);
begin
  inherited;

  FFmtSettings := TFormatSettings.Create('');
  FLangOf := Language.Strings('outOf');
  FLastActNode := nil;
  FShowSkiped := True;
  FCleanActions := False;

  vstStatus.NodeDataSize := SizeOf(TStatusItem);

  Self.ShowBottomInfo(Language.Strings('stopped'));

  Notifications.Add(Self);

  Settings.Storage.AddUser(Self);
  Settings.Storage.ReloadSingle(Self);

  Language.Storage.AddUser(Self);
  Language.Storage.ReloadSingle(Self);

  chkShowIgnored.Checked := FShowSkiped;
  chkCleanActions.Checked := FCleanActions;
  Self.Align := alClient;
end;

destructor TFraStatus.Destroy;
begin
  inherited;
end;

function TFraStatus.GetLangStorageName: String;
begin
  Result := 'frastatus';
end;

function TFraStatus.GetStorageName: String;
begin
  Result := 'frastatus'
end;

procedure TFraStatus.NotificationListNotification(Msg: Integer;
  const Params: array of const; Sender: TObject; var StopBrodcast: Boolean);
var
  PData: PFpNotificationData;
  Data: TFpNotificationData;
  item: PStatusItem;
  node: PVirtualNode;

  {$WARN SYMBOL_PLATFORM OFF}
  function MakeItemType(const Attr: TFileAttributes): String;
  begin
    if TFileAttribute.faArchive in Attr then
      Result := Result + Language.Strings('typeNormal') + ', ';
    if TFileAttribute.faReadOnly in Attr then
      Result := Result + Language.Strings('typeReadOnly') + ', ';
    if TFileAttribute.faHidden in Attr then
      Result := Result + Language.Strings('typeHidden') + ', ';
    if TFileAttribute.faSystem in Attr then
      Result := Result + Language.Strings('typeSystem') + ', ';
    if TFileAttribute.faOffline in Attr then
      Result := Result + Language.Strings('typeOffline') + ', ';
    if TFileAttribute.faEncrypted in Attr then
      Result := Result + Language.Strings('typeEncrypted') + ', ';
    if TFileAttribute.faSymLink in Attr then
      Result := Result + Language.Strings('typeSymlink') + ', ';
    if TFileAttribute.faDirectory in Attr then
      Result := Result + Language.Strings('typeDirectory') + ', ';

    if Result <> '' then SetLength(Result, Length(Result)-2);
  end;
  {$WARN SYMBOL_PLATFORM ON}

  function MakeItemStatus(const Op: TFpExecutorOperation; const Prog: Integer = ST_NOPRG): String;
  begin
    case Op of
      eoCopy: Result := Language.Strings('copied');
      eoMove: Result := Language.Strings('moved');
      eoDelete: Result := Language.Strings('deleted');
      eoSkip: Result := Language.Strings('ignored');
      eoNone: Result := '';
    end;
    if Prog = ST_NOPRG then
      exit
    else if Prog = ST_ERROR then
      Result := Format(STATUS_TEMPLATE_ERR, [Result, Language.Strings('error')])
    else
      Result := Format(STATUS_TEMPLATE, [Result, Prog]);
  end;

  procedure AutoFitColumns(const Force: Boolean = False);
  begin
    if Force then
      FTreeDelay := 0;

    if FTreeDelay <= 0 then begin
      vstStatus.Header.AutoFitColumns(False, smaAllColumns, SH_NAME, SH_STATUS);
      FTreeDelay := STATUS_TREE_DELAY;
    end else
      FTreeDelay := FTreeDelay - 1;
  end;

begin
  if Msg = NOTF_ACTIONS_STARTED then begin
    FUpdtDelay := 0;
    FTreeDelay := 0;
    FTimeElapsed := 0;
    FLastOpID := -1;
    FLastActNode := nil;
    btnReset.Enabled := False;
    pbProgress.Style := pbstNormal;
    pbProgress.State := pbsNormal;
    pbProgress.Position := pbProgress.Min;
    tmrUpdate.Enabled := True;
  end
  else if Msg = NOTF_ACTIONS_ANALYZING then begin
    Self.ShowBottomInfo(Language.Strings('analyzing'));
    pbProgress.Style := pbstMarquee;
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_WORKING then begin
    Self.ShowBottomInfo(Language.Strings('executing'));
    pbProgress.Style := pbstNormal;
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_RESUME then begin
    pbProgress.State := pbsNormal;
    Self.ShowBottomInfo(Language.Strings('executing'));
    tmrUpdate.Enabled := True;
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_PAUSED then begin
    tmrUpdate.Enabled := False;
    Self.UpdateProgress;
    pbProgress.State := pbsPaused;
    Self.ShowBottomInfo(Language.Strings('paused'));
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_FINISHED then begin
    tmrUpdate.Enabled := False;
    Self.UpdateProgress;
    Self.ShowBottomInfo(Language.Strings('stopped'));
    pbProgress.Style := pbstNormal;
    pbProgress.State := pbsNormal;
    btnReset.Enabled := True;
    AutoFitColumns(True);
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_PROGRESS then begin
    Self.UpdateProgress;
  end
  else if Msg = NOTF_ACTIONS_PAUSING then begin
    Self.ShowBottomInfo(Language.Strings('pausing'));
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_STOPPING then begin
    Self.ShowBottomInfo(Language.Strings('stopping'));
    Application.ProcessMessages;
  end
  //----------------
  else if Msg = NOTF_ACTIONS_FILE_STARTED then begin
    PData := Params[0].VPointer;
    Data := PData^;

    if (not FShowSkiped) and (Data.Operation = eoSkip) then begin
      Application.ProcessMessages;
      exit;
    end;

    vstStatus.BeginUpdate;

    node := vstStatus.AddChild(FLastActNode);
    item := vstStatus.GetNodeData(node);

    item^.ActionNode := False;
    item^.ImageIndex := Ord(Icons16Index.i16Play);
    item^.FileName := ExtractFileName(Data.Source);
    item^.Source := ExtractFileDir(Data.Source);
    item^.Destination := ExtractFileDir(Data.Destination);
    item^.Progress := ST_NOPRG;
    item^.Status := MakeItemStatus(Data.Operation);
    item^.FileType := MakeItemType(Data.Attributes);
    item^.ID := Data.OperationID;

    vstStatus.EndUpdate;

    AutoFitColumns;
    vstStatus.ScrollIntoView(node, False);

    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_FILE_PROGRESS then begin
    PData := Params[0].VPointer;
    Data := PData^;
    node := vstStatus.FindID(Data.OperationID);
    item := vstStatus.GetNodeData(node);
    if item <> nil then begin
      vstStatus.BeginUpdate;
      item^.Progress := Data.Progress;
      item^.Status := MakeItemStatus(Data.Operation, Data.Progress);
      vstStatus.EndUpdate;

      AutoFitColumns(Data.OperationID <> FLastOpID);
      FLastOpID := Data.OperationID;
    end;
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_FILE_FINISHED then begin
    PData := Params[0].VPointer;
    Data := PData^;
    node := vstStatus.FindID(Data.OperationID);
    item := vstStatus.GetNodeData(node);
    if item <> nil then begin
      if item.Progress = ST_ERROR then exit;

      vstStatus.BeginUpdate;
      if (not FShowSkiped) and (Data.Operation = eoSkip) then
        vstStatus.DeleteNode(node, False)
      else begin
        item^.Status := MakeItemStatus(Data.Operation);
        item^.ImageIndex := Ord(Icons16Index.i16Check);
        item^.Progress := ST_NOPRG;
      end;
      vstStatus.EndUpdate;

      AutoFitColumns;
    end;
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_FILE_ERROR then begin
    PData := Params[0].VPointer;
    Data := PData^;
    node := vstStatus.FindID(Data.OperationID);
    item := vstStatus.GetNodeData(node);
    if item <> nil then begin
      vstStatus.BeginUpdate;
      item^.Progress := ST_ERROR;
      item^.Status := MakeItemStatus(Data.Operation, ST_ERROR);
      item^.ImageIndex := Ord(Icons16Index.i16Cross);
      vstStatus.EndUpdate;

      AutoFitColumns;
    end;
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_ACTION_PICKED then begin
    PData := Params[0].VPointer;
    Data := PData^;

    vstStatus.BeginUpdate;

    if FCleanActions then
      vstStatus.Clear;

    node := vstStatus.AddChild(nil);
    FLastActNode := node;
    item := vstStatus.GetNodeData(node);

    item^.ActionNode := True;
    item^.ImageIndex := Ord(Icons16Index.i16Cog);
    item^.FileName := Data.Source;
    item^.Source := '';
    item^.Destination := '';
    item^.Progress := ST_NOPRG;
    item^.Status := '';
    item^.FileType := '';
    item^.ID := -1;

    vstStatus.EndUpdate;

    AutoFitColumns;
    Application.ProcessMessages;
  end;
end;

procedure TFraStatus.NotificationListAdded(const NotificationList: TNotificationList);
begin
end;

procedure TFraStatus.NotificationListRemoved;
begin
end;

procedure TFraStatus.OnLoadLangStrings(Node: IXMLDOMNode);
begin
  Language.SetComponentStrings(Self, Node);
end;

procedure TFraStatus.OnNodeLoad(Node: IXMLDOMNode);
begin
  FShowSkiped := TXmlStorage.GetNodeAttributeDef(Node, 'showSkiped', FShowSkiped);
  FCleanActions := TXmlStorage.GetNodeAttributeDef(Node, 'cleanActions', FCleanActions);
end;

procedure TFraStatus.OnNodeSave(Node: IXMLDOMNode);
begin
  IXMLDOMElement(Node).setAttribute('showSkiped', FShowSkiped);
  IXMLDOMElement(Node).setAttribute('cleanActions', FCleanActions);
end;

procedure TFraStatus.ResetUI;
begin
  vstStatus.Clear;
  btnReset.Enabled := False;
  sttTimeElapsed.Caption := ZERO_TIME;
  sttTimeRemaining.Caption := ZERO_TIME;
  sttSpeed.Caption := ZERO_PROGRESS;
  sttProgress.Caption := ZERO_PROGRESS;
  pbProgress.Position := 0;
  pbProgress.Style := pbstNormal;
  pbProgress.State := pbsNormal;
end;

procedure TFraStatus.ShowBottomInfo(const Text: String);
begin
  lblBottomInfo.Caption := Text;
end;

procedure TFraStatus.tmrUpdateTimer(Sender: TObject);
begin
  FTimeElapsed := IncSecond(FTimeElapsed, 1);
  Self.UpdateProgress;
end;

procedure TFraStatus.UpdateProgress;
begin
  if not Assigned(Fp.System.SequenceExecutor) then exit;

  if pbProgress.State = pbsNormal then
    pbProgress.Position := Fp.System.SequenceExecutor.Progress;

  sttTimeElapsed.Caption := FormatDateTime(
    TIME_TEMPLATE, FTimeElapsed, FFmtSettings
  );

  sttProgress.Caption := Format(
    PROGRESS_TEMPLATE, [
      SequenceExecutor.CurrentFile,
      FLangOf,
      SequenceExecutor.TotalFiles,
      FormatByteSize(SequenceExecutor.CurrentBytes, FFmtSettings),
      FLangOf,
      FormatByteSize(SequenceExecutor.TotalBytes, FFmtSettings),
      pbProgress.Position
    ], FFmtSettings
  );

  if FUpdtDelay <= 0 then begin
    sttTimeRemaining.Caption := FormatDateTime(
      TIME_TEMPLATE, SequenceExecutor.RemainingTime, FFmtSettings
    );

    sttSpeed.Caption := Format(
      SPEED_TEMPLATE, [FormatByteSize(SequenceExecutor.Speed, FFmtSettings)], FFmtSettings
    );

    FUpdtDelay := STATUS_UPDT_DELAY;
  end else
    FUpdtDelay := FUpdtDelay - 1;

  Application.ProcessMessages;
end;

procedure TFraStatus.vstStatusBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  item: PStatusItem;
begin
  if CellPaintMode <> cpmPaint then exit;
  
  item := Sender.GetNodeData(Node);
  if (Column = SH_STATUS) and (item^.Progress >= 0) then begin
    TargetCanvas.Pen.Style := psClear;
    TargetCanvas.Brush.Style := bsSolid;
    TargetCanvas.Brush.Color := INLINE_PROGRESS_BRUSH;
    TargetCanvas.Rectangle(
      CellRect.Left+1, CellRect.Top+1,
      CellRect.Left + Trunc((CellRect.Right - CellRect.Left) * (item^.Progress / 100)),
      CellRect.BottomRight.Y
    );

    TargetCanvas.Pen.Style := psSolid;
    TargetCanvas.Pen.Width := 1;
    TargetCanvas.Pen.Color := INLINE_PROGRESS_PEN;
    TargetCanvas.Brush.Style := bsClear;

    TargetCanvas.RoundRect(
      CellRect.Left, CellRect.Top, CellRect.BottomRight.X, CellRect.BottomRight.Y,
      4, 4
    );
  end;
end;

procedure TFraStatus.vstStatusFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  item: PStatusItem;
begin
  item := Sender.GetNodeData(Node);
  System.Finalize(item^);
end;

procedure TFraStatus.vstStatusGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
  var ImageIndex: Integer);
var
  item: PStatusItem;
begin
  item := Sender.GetNodeData(Node);
  if (Column = SH_NAME) and (Kind <> ikOverlay) then begin
    ImageIndex := item^.ImageIndex;
    Ghosted := False;
  end;
end;

procedure TFraStatus.vstStatusGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  item: PStatusItem;
begin
  item := Sender.GetNodeData(Node);
  case Column of
    SH_NAME: CellText := item^.FileName;
    SH_STATUS: CellText := item^.Status;
    SH_SOURCE: CellText := item^.Source;
    SH_DEST: CellText := item^.Destination;
    SH_TYPE: CellText := item^.FileType;
  end;
end;

procedure TFraStatus.vstStatusPaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  item: PStatusItem;
begin
  item := Sender.GetNodeData(Node);

  if item^.ActionNode then
    TargetCanvas.Font.Style := [fsBold];

  if item^.Progress = ST_ERROR then
    TargetCanvas.Font.Color := clRed;
end;

{ TVSTHelper }

function TVSTHelper.FindID(const ID: Integer): PVirtualNode;
var
  node: PVirtualNode;
  item: PStatusItem;
begin
  Result := nil;
  node := nil;
  repeat
    if node = nil then
      node := Self.GetLast()
    else
      node := Self.GetPrevious(node);

    if node = nil then break;

    item := Self.GetNodeData(node);
    if item^.ID = ID then begin
      Result := node;
      break;
    end;
  until node = nil;
end;

end.
