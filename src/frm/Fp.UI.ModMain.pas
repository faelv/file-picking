unit Fp.UI.ModMain;

interface

uses
  Fp.System,
  Fp.Resources.ImageLists, Fp.Resources.Notifications, Fp.Resources.Definitions,
  Fp.Types.Actions, Fp.Types.Notifications, Fp.Types.LangStorage, Fp.Types.FileActions,
  Fp.Types.SequenceStorage, Fp.Types.SequenceExecutor,
  Fp.Utils.Dialogs, Fp.Utils.Taskbar, Fp.Utils.General,
  System.SysUtils, System.Classes,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnList, Vcl.ActnMan, Vcl.Dialogs, Vcl.AppEvnts,
  Winapi.Windows;

type

  TModMain = class(TDataModule, INotificationListener, ILangStorageUser)
    MainActionManager: TActionManager;
    ActionAbout: TAction;
    ActionOpen: TAction;
    ActionSave: TAction;
    ActionStart: TAction;
    ActionPause: TAction;
    ActionStop: TAction;
    ActionTest: TAction;
    ActionNew: TAction;
    MainOpenDialog: TOpenDialog;
    MainSaveDialog: TSaveDialog;
    ActionSaveAs: TAction;
    ApplicationEvents: TApplicationEvents;
    procedure ActionAboutExecute(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure ActionOpenExecute(Sender: TObject);
    procedure ActionSaveExecute(Sender: TObject);
    procedure ActionStartExecute(Sender: TObject);
    procedure ActionPauseExecute(Sender: TObject);
    procedure ActionStopExecute(Sender: TObject);
    procedure ActionTestExecute(Sender: TObject);
    procedure ActionNewExecute(Sender: TObject);
    procedure ActionSaveAsExecute(Sender: TObject);
    procedure ApplicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
    private
      FActionStateManager: TActionStateManager;
      FSequenceStorage: TFpSequenceStorage;

      procedure OnExecutorNotification(Data: TFpNotificationData);
      procedure PopulateActionStates;
      procedure SaveSequenceFile(const SaveAs: Boolean = False);
    public // INotificationListener, ILangStorageUser
      procedure NotificationListNotification(Msg: Integer; const Params: array of const;
        Sender: TObject; var StopBrodcast: Boolean);
      procedure NotificationListAdded(const NotificationList: TNotificationList);
      procedure NotificationListRemoved;

      procedure OnLoadLangStrings(Node: IXMLDOMNode);
      function GetLangStorageName: String;
    public
      property ActionStateManager: TActionStateManager read FActionStateManager;
  end;

var
  ModMain: TModMain;

implementation

uses

  Vcl.Forms,
  Fp.UI.FrmMain, Fp.UI.FrmAbout;

{ %CLASSGROUP 'Vcl.Controls.TControl' }

{$R *.dfm}

procedure TModMain.ActionAboutExecute(Sender: TObject);
begin
  if not FrmAbout.Showing then
    FrmAbout.ShowModal;
end;

procedure TModMain.ActionNewExecute(Sender: TObject);
begin
  Fp.System.ActionsSequence.Clear;
  FSequenceStorage.Storage.FileName := '';
end;

procedure TModMain.ActionOpenExecute(Sender: TObject);
begin
  if not MainOpenDialog.Execute(FrmMain.Handle) then exit;
  FSequenceStorage.Storage.FileName := MainOpenDialog.FileName;

  try
    if not FSequenceStorage.Storage.Load then begin
      MsgBox(
        Language.Strings('loadFileFail') + sLineBreak + FSequenceStorage.Storage.Errors.Text,
        '', mbiError
      );
    end;
  except
    on E: Exception do begin
      MsgBox(
        Language.Strings('loadFileFail') + sLineBreak + E.Message, '', mbiError);
    end;
  end;
end;

procedure TModMain.SaveSequenceFile(const SaveAs: Boolean);
var
  act: TFpAction;
  vr: TFpValidateResult;
begin
  vr := Fp.System.ActionsSequence.Validate(act);

  case vr of
    vrNoActions: MsgBox(Language.Strings('validateNoActions'), '', mbiError);
    vrNoDestDir: begin
      MsgBox(SafeFormat(Language.Strings('validateNoDestDir'), [act.Description]), '', mbiError);
      FrmMain.ActiveFrame := FrmMain.ActionFrame;
      FrmMain.ActionFrame.SequenceAction := act;
    end;
    vrNoSrcDir: begin
      MsgBox(SafeFormat(Language.Strings('validateNoSrcDir'), [act.Description]), '', mbiError);
      FrmMain.ActiveFrame := FrmMain.ActionFrame;
      FrmMain.ActionFrame.SequenceAction := act;
    end;
    vrNoFileTypes: begin
      MsgBox(SafeFormat(Language.Strings('validateNoFileTypes'), [act.Description]), '', mbiError);
      FrmMain.ActiveFrame := FrmMain.ActionFrame;
      FrmMain.ActionFrame.SequenceAction := act;
    end;
  end;

  if vr <> vrOk then exit;

  if (FSequenceStorage.Storage.FileName = '') or SaveAs then begin
    if not MainSaveDialog.Execute(FrmMain.Handle) then exit;
    FSequenceStorage.Storage.FileName := MainSaveDialog.FileName;
  end;

  try
    if not FSequenceStorage.Storage.Save then begin
      MsgBox(
        Language.Strings('saveFileFail') + sLineBreak + FSequenceStorage.Storage.Errors.Text,
          '', mbiError
      );
    end;
  except
    on E: Exception do begin
      MsgBox(Language.Strings('saveFileFail') + sLineBreak + E.Message, '', mbiError);
    end;
  end;
end;

procedure TModMain.ActionSaveAsExecute(Sender: TObject);
begin
  Self.SaveSequenceFile(True);
end;

procedure TModMain.ActionSaveExecute(Sender: TObject);
begin
  Self.SaveSequenceFile;
end;

procedure TModMain.ActionStartExecute(Sender: TObject);
var
  act: TFpAction;
  vr: TFpValidateResult;
begin
  if not Assigned(Fp.System.SequenceExecutor) then begin
    vr := Fp.System.ActionsSequence.Validate(act);

    case vr of
      vrNoActions: MsgBox(Language.Strings('validateNoActions'), '', mbiError);
      vrNoDestDir: begin
        MsgBox(SafeFormat(Language.Strings('validateNoDestDir'), [act.Description]), '', mbiError);
        FrmMain.ActiveFrame := FrmMain.ActionFrame;
        FrmMain.ActionFrame.SequenceAction := act;
      end;
      vrNoSrcDir: begin
        MsgBox(SafeFormat(Language.Strings('validateNoSrcDir'), [act.Description]), '', mbiError);
        FrmMain.ActiveFrame := FrmMain.ActionFrame;
        FrmMain.ActionFrame.SequenceAction := act;
      end;
      vrNoFileTypes: begin
        MsgBox(SafeFormat(Language.Strings('validateNoFileTypes'), [act.Description]), '', mbiError);
        FrmMain.ActiveFrame := FrmMain.ActionFrame;
        FrmMain.ActionFrame.SequenceAction := act;
      end;
    end;

    if vr <> vrOk then exit;

    Fp.System.SequenceExecutor := TFpSequenceExecutor.Create(Fp.System.ActionsSequence);
    Fp.System.SequenceExecutor.OnNotification := Self.OnExecutorNotification;
    Fp.System.SequenceExecutor.Start;
  end else begin
    Fp.System.SequenceExecutor.Restart;
  end;
end;

procedure TModMain.ActionTestExecute(Sender: TObject);
var
  act: TFpAction;
  vr: TFpValidateResult;
begin
  if not Assigned(Fp.System.SequenceExecutor) then begin
    vr := Fp.System.ActionsSequence.Validate(act);

    case vr of
      vrNoActions: MsgBox(Language.Strings('validateNoActions'), '', mbiError);
      vrNoDestDir: begin
        MsgBox(SafeFormat(Language.Strings('validateNoDestDir'), [act.Description]), '', mbiError);
        FrmMain.ActiveFrame := FrmMain.ActionFrame;
        FrmMain.ActionFrame.SequenceAction := act;
      end;
      vrNoSrcDir: begin
        MsgBox(SafeFormat(Language.Strings('validateNoSrcDir'), [act.Description]), '', mbiError);
        FrmMain.ActiveFrame := FrmMain.ActionFrame;
        FrmMain.ActionFrame.SequenceAction := act;
      end;
      vrNoFileTypes: begin
        MsgBox(SafeFormat(Language.Strings('validateNoFileTypes'), [act.Description]), '', mbiError);
        FrmMain.ActiveFrame := FrmMain.ActionFrame;
        FrmMain.ActionFrame.SequenceAction := act;
      end;
    end;

    if vr <> vrOk then exit;

    Fp.System.SequenceExecutor := TFpSequenceExecutor.Create(Fp.System.ActionsSequence, True);
    Fp.System.SequenceExecutor.OnNotification := Self.OnExecutorNotification;
    Fp.System.SequenceExecutor.Start;
  end;
end;

procedure TModMain.ActionStopExecute(Sender: TObject);
begin
  if not Assigned(Fp.System.SequenceExecutor) then exit;

  if (not Fp.System.SequenceExecutor.TestMode) then begin
    if MsgBox(
      Language.Strings('stopConfirm'), '', mbiQuestion, mbbYesNo, mbdButton2
    ) <> mbrYes then exit;
  end;

  if Assigned(Fp.System.SequenceExecutor) then
    Fp.System.SequenceExecutor.Stop;
end;

procedure TModMain.ActionPauseExecute(Sender: TObject);
begin
  if Assigned(Fp.System.SequenceExecutor) then
    Fp.System.SequenceExecutor.Pause;
end;

procedure TModMain.DataModuleCreate(Sender: TObject);
begin
  if not OS_SEVEN then
    ApplicationEvents.OnMessage := nil;

  FActionStateManager := TActionStateManager.Create;
  Notifications.Add(Self);
  Language.Storage.AddUser(Self);
  Language.Storage.ReloadSingle(Self);

  FSequenceStorage := TFpSequenceStorage.Create;
  FSequenceStorage.Sequence := Fp.System.ActionsSequence;

  MainOpenDialog.Filter := Language.Strings('xmlFiles') + '|*.' + DEF_FILE_EXT;
  MainOpenDialog.DefaultExt := DEF_FILE_EXT;

  MainSaveDialog.Filter := Language.Strings('xmlFiles') + '|*.' + DEF_FILE_EXT;
  MainSaveDialog.DefaultExt := DEF_FILE_EXT;
end;

procedure TModMain.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(FActionStateManager) then
    ActionStateManager.Free;
end;

procedure TModMain.ApplicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
begin
  if OS_SEVEN and (Msg.message = WM_TaskbarButtonCreated) then begin
    InitializeTaskbarAPI;
    //ApplicationEvents.OnMessage := nil;
  end
  else if (Msg.message = ANT_INST_MSG) and (Msg.hwnd = Application.Handle) then begin
    if FrmMain.WindowState = wsMinimized then FrmMain.WindowState := wsNormal;
    FrmMain.Show;
    SetForegroundWindow(FrmMain.Handle);
    Application.ProcessMessages;
  end;
end;

procedure TModMain.OnExecutorNotification(Data: TFpNotificationData);
begin
  case Data.Notification of
    enStarted: Notifications.Broadcast(NOTF_ACTIONS_STARTED, [], Self);
    enAnalyzing: Notifications.Broadcast(NOTF_ACTIONS_ANALYZING, [], Self);
    enWorking: Notifications.Broadcast(NOTF_ACTIONS_WORKING, [], Self);
    enPaused: Notifications.Broadcast(NOTF_ACTIONS_PAUSED, [], Self);
    enResume: Notifications.Broadcast(NOTF_ACTIONS_RESUME, [], Self);
    enProgress: Notifications.Broadcast(NOTF_ACTIONS_PROGRESS, [Data.Progress], Self);
    enStopping: Notifications.Broadcast(NOTF_ACTIONS_STOPPING, [], Self);
    enPausing: Notifications.Broadcast(NOTF_ACTIONS_PAUSING, [], Self);
    enFinished: begin
      Notifications.Broadcast(NOTF_ACTIONS_FINISHED, [], Self);
      Fp.System.SequenceExecutor := nil;
    end;

    enFileStarted: Notifications.Broadcast(NOTF_ACTIONS_FILE_STARTED, [@Data], Self);
    enFileProgress: Notifications.Broadcast(NOTF_ACTIONS_FILE_PROGRESS, [@Data], Self);
    enFileFinished: Notifications.Broadcast(NOTF_ACTIONS_FILE_FINISHED, [@Data], Self);
    enFileError: Notifications.Broadcast(NOTF_ACTIONS_FILE_ERROR, [@Data], Self);

    enActionPicked: Notifications.Broadcast(NOTF_ACTIONS_ACTION_PICKED, [@Data], Self);

    {enFolderPicked: ;
    enFileEvaluating: ;
    enFileEvaluatedFalse: ;
    enFileEvaluatedTrue: ;}
  end;
end;

procedure TModMain.NotificationListNotification(Msg: Integer;
  const Params: array of const; Sender: TObject; var StopBrodcast: Boolean);
begin
  if Msg = NOTF_APP_SYSTEM_ACTIVE then begin
    Self.PopulateActionStates;
    Self.ActionStateManager.SetAbsoluteFlags([asIdle]);
    FrmMain.ActionsSequence := Fp.System.ActionsSequence;
  end
  else if Msg = NOTF_ACTIONS_STARTED then begin
    Self.ActionStateManager.SetAbsoluteFlags([asWaiting]);
    SetTaskbarProgressState(tbpsNormal);
    SetTaskbarProgressValue(0, 100);
  end
  else if Msg = NOTF_ACTIONS_ANALYZING then begin
    Self.ActionStateManager.SetAbsoluteFlags([asAnalyzing]);
    SetTaskbarProgressState(tbpsIndeterminate);
  end
  else if Msg = NOTF_ACTIONS_WORKING then begin
    Self.ActionStateManager.SetAbsoluteFlags([asWorking]);
    SetTaskbarProgressState(tbpsNormal);
  end
  else if Msg = NOTF_ACTIONS_RESUME then begin
    Self.ActionStateManager.SetAbsoluteFlags([asWorking]);
    SetTaskbarProgressState(tbpsNormal);
  end
  else if Msg = NOTF_ACTIONS_PAUSED then begin
    Self.ActionStateManager.SetAbsoluteFlags([asPaused]);
    SetTaskbarProgressState(tbpsPaused);
  end
  else if Msg = NOTF_ACTIONS_FINISHED then begin
    Self.ActionStateManager.SetAbsoluteFlags([asIdle]);
    SetTaskbarProgressValue(0, 100);
    SetTaskbarProgressState(tbpsNone);
  end
  else if Msg = NOTF_ACTIONS_PROGRESS then begin
    SetTaskbarProgressValue(Params[0].VInteger, 100);
  end
  else if (Msg = NOTF_ACTIONS_PAUSING)
    or (Msg = NOTF_ACTIONS_STOPPING)
    or (Msg = NOTF_ACTIONS_RESUMING) then begin
    Self.ActionStateManager.SetAbsoluteFlags([asWaiting]);
  end;
end;

procedure TModMain.NotificationListAdded(const NotificationList: TNotificationList);
begin;
end;

procedure TModMain.NotificationListRemoved;
begin;
end;

function TModMain.GetLangStorageName: String;
begin
  Result := 'modmain';
end;

procedure TModMain.OnLoadLangStrings(Node: IXMLDOMNode);
begin
  Language.SetComponentStrings(Self, Node);
end;

procedure TModMain.PopulateActionStates;
begin
  with FActionStateManager do begin
    Clear;

    New(ActionAbout, [[]]);
    New(ActionOpen, [[asIdle]]);
    New(ActionSave, [[asIdle]]);
    New(ActionStart, [[asIdle], [asPaused]]);
    New(ActionPause, [[asWorking]]);
    New(ActionStop, [[asWorking], [asPaused]]);
    New(ActionTest, [[asIdle]]);
    New(ActionNew, [[asIdle]]);
    New(ActionSaveAs, [[asIdle]]);
  end;
end;

end.
