unit Fp.System;

interface

uses

  Fp.Resources.Definitions, Fp.Resources.Strings, Fp.Resources.Notifications,
  Fp.Types.General, Fp.Types.Settings, Fp.Types.Notifications, Fp.Types.LangStorage,
  Fp.Types.FileActions, Fp.Types.SequenceExecutor,
  Fp.Utils.Dialogs, Fp.Utils.Versioning, Fp.Utils.Shell, Fp.Utils.General,
  Winapi.Windows, Winapi.ShlObj, Winapi.ActiveX,
  System.SysUtils,
  Vcl.Forms;

var

  APP_PATH: String;
  APP_DATA: String;
  APP_VERSION: String;
  OS_SUPPORTED: Boolean;
  OS_VISTA: Boolean;
  OS_SEVEN: Boolean;
  LOCALE_CODE: Cardinal;
  ANT_INST_MSG: Cardinal;

  CommandLineParams: TCmdLineParams;
  Settings: TApplicationSettings;
  Notifications: TNotificationList;
  Language: TApplicationLanguage;
  ActionsSequence: TFpSequence;
  SequenceExecutor: TFpSequenceExecutor;

{ procedures }

  procedure Initialize;
  procedure Finalize;
  function Initialized: Boolean;
  function Finalizing: Boolean;

implementation

uses

  Fp.Resources.ImageLists,
  Fp.UI.FrmMain, Fp.UI.ModMain, Fp.UI.FrmAbout;

var

  initializedEventHandle: DWORD;
  sysInitialized: Boolean;
  sysFinalizing: Boolean;

{ procedures }

function Initialized: Boolean;
begin
  Result := sysInitialized;
end;

function Finalizing: Boolean;
begin
  Result := sysFinalizing;
end;

procedure Initialize;
var
  auxBool: Boolean;
begin
  { sair se já iniciado }
  if Initialized then
    exit;

  { verificar versão do SO }
  OS_SUPPORTED := CheckWin32Version(5, 1); // XP
  OS_VISTA := CheckWin32Version(6, 0); // Vista
  OS_SEVEN := CheckWin32Version(6, 1);

  { XP é a versão mínima suportada, se não for, abortar }
  if not OS_SUPPORTED then begin
    Application.MessageBox(PChar(RS_MSG_NOT_MIN_OS), PChar(APP_TITLE));
    Application.Terminate;
    Exit;
  end;

  { verificar se já existe uma outra instância em execução }
  initializedEventHandle := CreateEvent(nil, False, False, PChar(APP_INSTANCE_EVNT));
  auxBool := ((initializedEventHandle <> 0) and (GetLastError() = ERROR_ALREADY_EXISTS));

  { somente uma instância é permitida, senão abortar }
  ANT_INST_MSG := RegisterWindowMessage(PChar('FpAnotherInstanceFocus'));
  if auxBool then begin
    //Application.MessageBox(PChar(RS_MSG_ANOTHER_INSTANCE), PChar(APP_TITLE));
    PostMessage(HWND_BROADCAST, ANT_INST_MSG, 0, 0);
    Application.Terminate;
    Exit;
  end;

  { iniciar suporte a interfaces e APIs com suporte à COM }
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED);

  { reunir algumas informações do ambiente }
  APP_PATH := ExtractFilePath(Application.EXEName);
  APP_VERSION := GetExeVersion(Application.EXEName);
  APP_DATA := GetKnownFolder(CSIDL_LOCAL_APPDATA) + '\' + APP_DATA_FOLDER;
  LOCALE_CODE := Winapi.Windows.GetSystemDefaultLCID;

  { ler os parâmetros de linha de comando }
  CommandLineParams.ReadCommandLine;

  { criar pastas padrão no AppData do usuário }
  if not DirectoryExists(APP_DATA) then
    ForceDirectories(APP_DATA);

  { criar objetos globais do sistema }
  Settings := TApplicationSettings.Create;
  Language := TApplicationLanguage.Create;
  Notifications := TNotificationList.Create;
  ActionsSequence := TFpSequence.Create;
  SequenceExecutor := nil;

  { aplicar últimas configurações salvas }
  Settings.Storage.FileName := APP_DATA + '\' + APP_SETTINGS_FILE;
  Settings.Storage.Load;

  { carregar arquivo de idioma }
  if not LoadLocalizedResources(LOCALE_CODE) then begin
    MsgBox(SafeFormat(LOAD_LANG_FAIL, [Language.Storage.FileName,
      Language.Storage.Errors.Text]), '', mbiError);
    Application.Terminate;
    Exit;
  end;

  { definir títulos dos diálogos de mensagens }
  MBC_ERROR := Language.Strings('error', MBC_ERROR);
  MBC_QUESTION := Language.Strings('question', MBC_QUESTION);
  MBC_WARNING := Language.Strings('warning', MBC_WARNING);
  MBC_INFORMATION := Language.Strings('information', MBC_INFORMATION);

  { create data modules }
  Application.CreateForm(TModImageLists, ModImageLists);
  Application.CreateForm(TModMain, ModMain);

  { create main form }
  Application.CreateForm(TFrmMain, FrmMain);
  if not Settings.Storage.Loaded then FrmMain.Position := poScreenCenter;
  FrmMain.Visible := False;

  { create forms }
  Application.CreateForm(TFrmAbout, FrmAbout);

  sysInitialized := True;

  { send system loaded notification }
  Notifications.Broadcast(NOTF_APP_SYSTEM_LOADED, [], nil);

  { show main form }
  FrmMain.Show;

  Notifications.Broadcast(NOTF_APP_SYSTEM_ACTIVE, [], nil);
end;

procedure Finalize;
begin
  {sair se não iniciado ou já finalizando}
  if (not Initialized) or Finalizing then
    exit;

  sysFinalizing := True;

  { notificar }
  Fp.System.Notifications.Broadcast(NOTF_APP_TERMINATED, [], nil);

  {salvar altereções}
  Settings.Storage.Save;

  { destruir objetos globais }
  FreeAndNil(ActionsSequence);
  FreeAndNil(Settings);
  FreeAndNil(Notifications);
  FreeAndNil(Language);

  if Assigned(SequenceExecutor) then
    FreeAndNil(SequenceExecutor);

  { liberar evento de instância }
  if initializedEventHandle <> 0 then
    CloseHandle(initializedEventHandle);

  { desativar suporte COM }
  CoUninitialize;

  { fechar form principal }
  FrmMain.Close;
end;

initialization

  initializedEventHandle := 0;
  sysInitialized := False;
  sysFinalizing := False;

finalization

end.
