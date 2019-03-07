unit Fp.UI.FrmMain;

interface

uses
  Fp.System,
  Fp.Utils.Dialogs,
  Fp.Resources.Notifications, Fp.Resources.Definitions, Fp.Resources.ImageLists,
  Fp.Types.Notifications, Fp.Types.LangStorage, Fp.Types.Storage, Fp.Types.FileActions,
  Fp.UI.ModMain, Fp.UI.FraAction, Fp.UI.FraStatus,
  Winapi.Windows, Winapi.Messages, Winapi.msxml,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.ToolWin, Vcl.Menus, Vcl.StdCtrls, Vcl.Imaging.pngimage;

type

  TFrmMain = class(TForm, INotificationListener, ILangStorageUser, IXmlStorageUser)
    pnlLeft: TPanel;
    pnlClient: TPanel;
    lsvActions: TListView;
    tbMainCommands: TToolBar;
    ToolButton1: TToolButton;
    Splitter1: TSplitter;
    ToolButton2: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    popStart: TPopupMenu;
    ActionStart1: TMenuItem;
    ActionTest1: TMenuItem;
    tbActionCommands: TToolBar;
    tbtnActionAdd: TToolButton;
    tbtnActionDel: TToolButton;
    tbtnActionUp: TToolButton;
    tbtnActionDown: TToolButton;
    lblDescr: TLabel;
    Image2: TImage;
    popSave: TPopupMenu;
    ActionSave1: TMenuItem;
    ActionSaveAs1: TMenuItem;
    pgcClient: TPageControl;
    tabAction: TTabSheet;
    tabStatus: TTabSheet;
    lblNoAct: TLabel;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure lsvActionsDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure lsvActionsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure tbtnActionDelClick(Sender: TObject);
    procedure tbtnActionAddClick(Sender: TObject);
    procedure lsvActionsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lsvActionsItemChecked(Sender: TObject; Item: TListItem);
    procedure lsvActionsClick(Sender: TObject);
    procedure lsvActionsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure tbtnActionUpClick(Sender: TObject);
    procedure tbtnActionDownClick(Sender: TObject);

    private
      FActionFrame: TFraAction;
      FStatusFrame: TFraStatus;
      //FActiveFrame: TFrame;
      FSequence: TFpSequence;
      FSkipChange: Boolean;
      FRunning: Boolean;

      procedure LoadUI;
      procedure SetActiveFrame(const Value: TFrame);
      function GetSelectedAction: TFpAction;
      function GetActionListItem(AAction: TFpAction): TListItem;
      procedure SetActionsSequence(const Value: TFpSequence);
      procedure OnSequenceActionsChange(Sender: TFpActionList; Action: TFpAction; Kind: TFpActionListChangeKind);
      procedure MoveSelectedAction(const Up: Boolean);
      function GetActiveFrame: TFrame;
      procedure SetNoActMsg(const Value: Boolean);
    public // INotificationListener, ILangStorageUser, IXmlStorageUser
      procedure NotificationListNotification(Msg: Integer; const Params: array of const;
        Sender: TObject; var StopBrodcast: Boolean);
      procedure NotificationListAdded(const NotificationList: TNotificationList);
      procedure NotificationListRemoved;

      procedure OnLoadLangStrings(Node: IXMLDOMNode);
      function GetLangStorageName: String;

      procedure OnNodeLoad(Node: IXMLDOMNode);
      procedure OnNodeSave(Node: IXMLDOMNode);
      function GetStorageName: String;
    public
      property ActionFrame: TFraAction read FActionFrame;
      property StatusFrame: TFraStatus read FStatusFrame;
      property ActiveFrame: TFrame read GetActiveFrame write SetActiveFrame;
      property ActionsSequence: TFpSequence read FSequence write SetActionsSequence;
      procedure ResetUI;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

{BEGIN - Form Events}

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  Self.Caption := Fp.Resources.Definitions.APP_TITLE;

  FRunning := False;

  Notifications.Add(Self);

  Language.Storage.AddUser(Self);
  Language.Storage.ReloadSingle(Self);

  Settings.Storage.AddUser(Self);
  Settings.Storage.ReloadSingle(Self);

  FActionFrame := TFraAction.Create(Self);
  FActionFrame.Parent := tabAction;
  FActionFrame.Visible := False;

  FStatusFrame := TFraStatus.Create(Self);
  FStatusFrame.Parent := tabStatus;

  //Self.ResetUI;
end;

procedure TFrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Fp.System.Finalizing then
    exit;

  Fp.System.Notifications.Broadcast(NOTF_APP_TRY_TERMINATE, [], Self);

  CanClose := not FRunning;
  if CanClose then begin
    Fp.System.Finalize;
  end else begin
    MsgBox(Language.Strings('closeRunning'), '', mbiWarning);
    Fp.System.Notifications.Broadcast(NOTF_APP_NOT_TERMINATED, [], Self);
  end;
end;

procedure TFrmMain.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
begin
  Handled := ModMain.MainActionManager.IsShortCut(Msg);
end;

{END - Form Events}

{BEGIN - Interfaces}

function TFrmMain.GetLangStorageName: String;
begin
  Result := 'frmmain';
end;

function TFrmMain.GetStorageName: String;
begin
  Result := 'frmmain';
end;

procedure TFrmMain.OnLoadLangStrings(Node: IXMLDOMNode);
begin
  Language.SetComponentStrings(Self, Node);
  lblNoAct.Left := (lblNoAct.Parent.ClientWidth div 2) - (lblNoAct.Width div 2);
  lblNoAct.Top := (lblNoAct.Parent.ClientHeight div 2) - (lblNoAct.Height div 2);
end;

procedure TFrmMain.OnNodeLoad(Node: IXMLDOMNode);
begin
  with TXmlStorage do begin
    Self.SetBounds(
      GetNodeAttributeDef(Node, 'left', Self.Left),
      GetNodeAttributeDef(Node, 'top', Self.Top),
      GetNodeAttributeDef(Node, 'width', Self.Width),
      GetNodeAttributeDef(Node, 'height', Self.Height)
    );
    if Boolean(GetNodeAttributeDef(Node, 'max', False)) then
      Self.WindowState := wsMaximized;

    pnlLeft.Width := GetNodeAttributeDef(
      Node, 'actionsW', pnlLeft.Width
    );
  end;
end;

procedure TFrmMain.OnNodeSave(Node: IXMLDOMNode);
begin
  with IXMLDOMElement(Node) do begin
    if Self.WindowState = wsNormal then begin
      setAttribute('left', Self.Left);
      setAttribute('top', Self.Top);
      setAttribute('width', Self.Width);
      setAttribute('height', Self.Height);
    end;
    setAttribute('max', (Self.WindowState = wsMaximized));
    setAttribute('actionsW', pnlLeft.Width);
  end;
end;

procedure TFrmMain.OnSequenceActionsChange(Sender: TFpActionList; Action: TFpAction;
  Kind: TFpActionListChangeKind);
var
  listItem: TListItem;
begin
  case Kind of
    acAdd: begin
      listItem := lsvActions.Items.Add;
      listItem.Data := Action;
      listItem.Caption := Action.Description;
      listItem.Checked := Action.Enabled;
      listItem.ImageIndex := Ord(Icons26Index.i26Cog);
    end;

    acRemove: begin
      if Fp.System.Finalizing then exit;
      
      listItem := Self.GetActionListItem(Action);
      if Assigned(listItem) then
        listItem.Delete;
    end;

    acClear: begin
      if Fp.System.Finalizing then exit;

      Self.ResetUI;
    end;

    acChange: begin
      if FSkipChange then exit;
      
      listItem := Self.GetActionListItem(Action);
      if Assigned(listItem) then begin
        listItem.Caption := Action.Description;
        listItem.Checked := Action.Enabled;
      end;
    end;
  end;
end;

procedure TFrmMain.NotificationListNotification(Msg: Integer;
  const Params: array of const; Sender: TObject; var StopBrodcast: Boolean);
var
  btn: TToolButton;
begin
  if Msg = NOTF_ACTIONS_STARTED then begin
    FRunning := True;

    lsvActions.Selected := nil;
    lsvActions.Enabled := False;
    Self.StatusFrame.ResetUI;
    Self.ActiveFrame := Self.StatusFrame;
    Self.ActionFrame.SequenceAction := nil;
    Self.SetNoActMsg(True);
    for btn in tbActionCommands do
      btn.Enabled := False;

    Self.Caption := APP_TITLE;
    Application.ProcessMessages;
  end
  else if Msg = NOTF_ACTIONS_FINISHED then begin
    lsvActions.Selected := nil;
    lsvActions.Enabled := True;
    for btn in tbActionCommands do
      btn.Enabled := True;

    Self.Caption := APP_TITLE;
    Application.ProcessMessages;

    FRunning := False;
  end
  else if (Msg = NOTF_ACTIONS_RESUME) or (Msg = NOTF_ACTIONS_PROGRESS) then begin
    Self.Caption := Format(TITLE_TEMPLATE, [
      APP_TITLE, Fp.System.SequenceExecutor.Progress, ''
    ]);
  end
  else if Msg = NOTF_ACTIONS_ANALYZING then begin
    Self.Caption := Format(TITLE_TEMPLATE, [
      APP_TITLE, 0, ' '+Language.Strings('analyzing')
    ]);
  end
  else if Msg = NOTF_ACTIONS_WORKING then begin
    Self.Caption := Format(TITLE_TEMPLATE, [APP_TITLE, 0, '']);
  end
  else if Msg = NOTF_ACTIONS_PAUSED then begin
    Self.Caption := Format(TITLE_TEMPLATE, [
      APP_TITLE, Fp.System.SequenceExecutor.Progress, ' '+Language.Strings('paused')
    ]);
  end
  else;
end;

procedure TFrmMain.NotificationListAdded(const NotificationList: TNotificationList);
begin
end;

procedure TFrmMain.NotificationListRemoved;
begin
end;

{END - Interfaces}

{BEGIN - Methods}

function TFrmMain.GetActionListItem(AAction: TFpAction): TListItem;
var
  item: TListItem;
begin
  Result := nil;
  for item in lsvActions.Items do begin
    if TFpAction(item.Data) = AAction then begin
      Result := item;
      break;
    end;
  end;
end;

function TFrmMain.GetActiveFrame: TFrame;
begin
  if pgcClient.ActivePage = tabAction then
    Result := FActionFrame
  else
    Result := FStatusFrame;
end;

function TFrmMain.GetSelectedAction: TFpAction;
begin
  Result := nil;
  if lsvActions.Selected <> nil then
    Result := TFpAction(lsvActions.Selected.Data);
end;

procedure TFrmMain.LoadUI;
var
  action: TFpAction;
begin
  if not Assigned(FSequence) then exit;

  FSkipChange := True;
  for action in FSequence.Actions do begin
    with lsvActions.Items.Add do begin
      Data := action;
      Caption := action.Description;
      Checked := action.Enabled;
      ImageIndex := Ord(Icons26Index.i26Cog);
    end;
  end;
  FSkipChange := False;
end;

procedure TFrmMain.ResetUI;
begin
  lsvActions.Clear;
  Self.ActiveFrame := FActionFrame;
  Self.ActionFrame.SequenceAction := nil;
  Self.SetNoActMsg(True);
  Self.StatusFrame.ResetUI;
end;

procedure TFrmMain.SetActiveFrame(const Value: TFrame);
begin
  if Value = FActionFrame then
    pgcClient.ActivePage := tabAction
  else
    pgcClient.ActivePage := tabStatus;
end;

procedure TFrmMain.SetNoActMsg(const Value: Boolean);
begin
  lblNoAct.Visible := Value;
  lblNoAct.Parent.Invalidate;
  Application.ProcessMessages;
end;

procedure TFrmMain.SetActionsSequence(const Value: TFpSequence);
begin
  FSequence := Value;
  Self.ResetUI;
  Self.LoadUI;

  if Assigned(FSequence) then
    FSequence.Actions.OnChange := Self.OnSequenceActionsChange;
end;

procedure TFrmMain.MoveSelectedAction(const Up: Boolean);
var
  P: Pointer;
  S: String;
  C: Boolean;
  I, I2: Integer;
  Target: TListItem;
begin
  if (not Assigned(FSequence))
  or (lsvActions.Selected = nil) then exit;

  if (Up and (lsvActions.Selected.Index = 0))
  or ((not Up) and (lsvActions.Selected.Index = lsvActions.Items.Count-1)) then exit;

  if Up then
    Target := lsvActions.Items[lsvActions.Selected.Index-1]
  else
    Target := lsvActions.Items[lsvActions.Selected.Index+1];

  FSkipChange := True;

  P := lsvActions.Selected.Data;
  S := lsvActions.Selected.Caption;
  C := lsvActions.Selected.Checked;

  lsvActions.Selected.Data := Target.Data;
  Target.Data := P;

  lsvActions.Selected.Caption := Target.Caption;
  Target.Caption := S;

  lsvActions.Selected.Checked := Target.Checked;
  Target.Checked := C;

  I := FSequence.Actions.IndexOf(TFpAction(lsvActions.Selected.Data));
  I2 := FSequence.Actions.IndexOf(TFpAction(Target.Data));
  FSequence.Actions.Exchange(I, I2);

  lsvActions.Selected := Target;

  FSkipChange := False;
end;

{END - Methods}

{BEGIN - Control Events}

procedure TFrmMain.tbtnActionAddClick(Sender: TObject);
var
  newAction: TFpAction;
  descr: String;
  listItem: TListItem;
  exists: Boolean;
  actInc: Integer;
begin
  if not Assigned(FSequence) then exit;

  FSkipChange := True;
  newAction := FSequence.Actions.New;
  FSkipChange := False;

  actInc := 0;
  repeat
    exists := False;
    Inc(actInc);
    descr := Language.Strings('action') + ' ' + IntToStr(actInc);
    for listItem in lsvActions.Items do begin
      exists := exists or (listItem.Caption = descr);
    end;
  until not exists;

  newAction.Description := descr;

  FSkipChange := True;
  lsvActions.Selected := Self.GetActionListItem(newAction);
  FSkipChange := False;

  Self.ActiveFrame := Self.ActionFrame;
  Self.ActionFrame.SequenceAction := newAction;
  Self.SetNoActMsg(False);
end;

procedure TFrmMain.tbtnActionDelClick(Sender: TObject);
var
  selAction: TFpAction;
begin
  if not Assigned(FSequence) then exit;

  selAction := Self.GetSelectedAction;
  if not Assigned(selAction) then exit;

  FSequence.Actions.Remove(selAction);

  Self.ActionFrame.SequenceAction := nil;
  Self.SetNoActMsg(True);
end;

procedure TFrmMain.tbtnActionDownClick(Sender: TObject);
begin
  Self.MoveSelectedAction(False);
end;

procedure TFrmMain.tbtnActionUpClick(Sender: TObject);
begin
  Self.MoveSelectedAction(True);
end;

procedure TFrmMain.lsvActionsClick(Sender: TObject);
begin
  if lsvActions.Selected = nil then begin
    Self.ActionFrame.SequenceAction := nil;
    Self.SetNoActMsg(True);
  end;
end;

procedure TFrmMain.lsvActionsDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  P: Pointer;
  S: String;
  C: Boolean;
  I, I2: Integer;
begin
  if not Assigned(FSequence) then exit;

  with TListView(Sender) do begin
    if (Selected <> nil) and (DropTarget <> nil) and (Selected <> DropTarget) then begin
      FSkipChange := True;

      P := Selected.Data;
      S := Selected.Caption;
      C := Selected.Checked;

      Selected.Data := DropTarget.Data;
      DropTarget.Data := P;

      Selected.Caption := DropTarget.Caption;
      DropTarget.Caption := S;

      Selected.Checked := DropTarget.Checked;
      DropTarget.Checked := C;

      I := FSequence.Actions.IndexOf(TFpAction(Selected.Data));
      I2 := FSequence.Actions.IndexOf(TFpAction(DropTarget.Data));
      FSequence.Actions.Exchange(I, I2);

      lsvActions.Selected := DropTarget;

      FSkipChange := False;
    end;
  end;
end;

procedure TFrmMain.lsvActionsDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept := (Source = Sender);
end;

procedure TFrmMain.lsvActionsItemChecked(Sender: TObject; Item: TListItem);
var
  selAction: TFpAction;
begin
  if FSkipChange then exit;

  selAction := TFpAction(Item.Data);
  if Assigned(selAction) then begin
    FSkipChange := True;
    selAction.Enabled := Item.Checked;
    FSkipChange := False;
  end;
end;

procedure TFrmMain.lsvActionsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbRight) then
    lsvActionsClick(lsvActions);
end;

procedure TFrmMain.lsvActionsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  selAction: TFpAction;
begin
  if FSkipChange then exit;

  selAction := Self.GetSelectedAction;
  if Assigned(selAction) then begin
    FSkipChange := True;
    Self.ActiveFrame := Self.ActionFrame;
    Self.ActionFrame.SequenceAction := selAction;
    Self.SetNoActMsg(False);
    FSkipChange := False;
  end;
end;

{END - Control Events}

end.
