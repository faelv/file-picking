unit Fp.Types.SequenceExecutor;

interface

uses

  Fp.Resources.Definitions,
  Fp.Types.FileActions, Fp.Types.General,
  Winapi.Windows,
  System.IOUtils, System.Classes, System.SyncObjs, System.SysUtils, System.Types,
  System.DateUtils, System.StrUtils;

type

  {$WARN SYMBOL_PLATFORM OFF}

  TFpExecutorOperation = (eoCopy, eoMove, eoDelete, eoNone, eoSkip);

  TFpExecutorState = (
    esUnknow,
    esStarted,
    esAnalyzing, //calculando quantidade e tamanho de arquivos
    esResuming,
    esWorking, //processando
    esFinished, //terminado
    esPausing, //tentando pausar
    esPaused, //pausado
    esStopping //tentando parar
  );

  TFpExecutorNotification = (
    enStarted, //acabou de começar
    enAnalyzing, //analisando
    enWorking, //análise terminou, começar processando
    enPausing, //tentando pausar
    enPaused, //pausado
    enResuming,
    enResume, //recomeçou
    enStopping, //tentando parar
    enFinished, //terminou ou foi parado
    enFolderPicked, //entrou em uma pasta
    enActionPicked, //entrou em uma ação
    enFileEvaluating, //verificando se um arquivo passa nos filtros
    enFileEvaluatedFalse, //o arquivo não passa nos filtros
    enFileEvaluatedTrue, //o arquivo passaou nos filtros
    enFileStarted, //um arquivo começou a ser processado, a operação Move, Copy, Delete também é informada
    enFileProgress, //progresso do arquivo, a operação Move, Copy, Delete também é informada, junto à % de progresso
    enFileFinished, //arquivo terminou de ser processado, a operação Move, Copy, Delete também é informada
    enFileError, //houve um erro no processamento do arquivo, a operação Move, Copy, Delete também é informada
    enProgress //progresso geral
  );

  TFpNotificationData = record
    Notification: TFpExecutorNotification;
    Source: TFpFile;
    Destination: TFpFile;
    Operation: TFpExecutorOperation;
    OperationID: Integer;
    Progress: Integer;
    Attributes: TFileAttributes;
  end;
  PFpNotificationData = ^TFpNotificationData;

  TFpNotificationEvent = procedure (Data: TFpNotificationData) of object;

  TExecuteCopyCallback = reference to function(Bytes, TotalBytes: Int64): Boolean;
  PExecuteCopyCallback = ^TExecuteCopyCallback;

  TFpSequenceExecutor = class(TThread)
    private
      FCS: TCriticalSection;
      FState: TFpExecutorState;
      FNotfData: TFpNotificationData;
      FOnNotfEvent: TFpNotificationEvent;
      FCurrentFile: Integer;
      FTotalFiles: Integer;
      FProgress: Integer;
      FRemainingTime: TTime;
      FSpeed: Integer;
      FTotalBytes: Int64;
      FCurrentBytes: Int64;
      FTimer: TTickTimer;
      FSequence: TFpSequence;
      FTestMode: Boolean;
      FSizeThreshold: Int64;
      FFileID: Integer;
      FCopyWaitEvent: TSimpleEvent;
      FPauseWaitEvent: TSimpleEvent;

      procedure CallNotify;
      procedure DoNotify(Notf: TFpExecutorNotification; Src: TFpFile = ''; Dest: TFpFile = '';
        Op: TFpExecutorOperation = eoNone; Prg: Integer = 0; ID: Integer = 0;
        Attr: TFileAttributes = []);

      function GetState: TFpExecutorState;
      function GetCurrentFile: Integer;
      function GetProgress: Integer;
      function GetRemainingTime: TTime;
      function GetSpeed: Integer;
      function GetTotalFiles: Integer;
      function GetCurrentBytes: Int64;
      function GetTotalBytes: Int64;

      procedure SetCurrentFile(Value: Integer);
      procedure SetProgress(Value: Integer);
      procedure SetRemainingTime(Value: TTime);
      procedure SetSpeed(Value: Integer);
      procedure SetTotalFiles(Value: Integer);
      procedure SetState(Value: TFpExecutorState);
      procedure SetTotalBytes(Value: Int64);
      procedure SetCurrentBytes(Value: Int64);

      procedure ExecuteProgress;
      procedure ExecutePause;
      procedure ExecuteAnalysis;
      procedure ExecuteAction(Action: TFpAction);
      function ExecuteOperation(Operation: TFpOperationKind; Source, Dest: String;
          Attr: TFileAttributes; ExistsDecision: TFpOnExistsDecision;
          NotExistsDecision: TFpOnNotExistsDecision; FileID: Integer)
      : TFpExecutorOperation;
      function ExecuteCopy(SrcPath, DestPath: String; DeleteSrc: Boolean = False;
        TrackProgress: Boolean = False; Callback: TExecuteCopyCallback = nil)
      : Boolean;
      procedure ExecuteDelete(Path: String; const IsDirectory: Boolean = False);
      function GetTestMode: Boolean;
    protected
      procedure Execute; override;
    public
      constructor Create(ASequence: TFpSequence; const UseTestMode: Boolean = False); reintroduce;
      destructor Destroy; override;
      property State: TFpExecutorState read GetState;
      property Speed: Integer read GetSpeed; //bytes por segundo
      property RemainingTime: TTime read GetRemainingTime;
      property TotalFiles: Integer read GetTotalFiles;
      property CurrentFile: Integer read GetCurrentFile;
      property Progress: Integer read GetProgress;
      property TotalBytes: Int64 read GetTotalBytes;
      property CurrentBytes: Int64 read GetCurrentBytes;
      property TestMode: Boolean read GetTestMode;
      property OnNotification: TFpNotificationEvent read FOnNotfEvent write FOnNotfEvent;
      procedure Stop;
      procedure Pause;
      procedure Restart;

      class procedure StringArrayAdd(var StrArr: TStringDynArray; const NewItem: String); overload;
      class procedure StringArrayAdd(var StrArr: TStringDynArray; NewItems: TStringDynArray); overload;
  end;

  function CopyProgressCallback(
    TotalFileSize, TotalBytesTransferred, StreamSize, StreamBytesTransferred: LARGE_INTEGER;
    dwStreamNumber, dwCallbackReason: DWORD;
    hSourceFile, hDestinationFile: THANDLE;
    lpData: LPVOID
  ): DWORD; stdcall;

implementation

uses

  Fp.System;

{ TFpSequenceExecutor }

class procedure TFpSequenceExecutor.StringArrayAdd(var StrArr: TStringDynArray;
  const NewItem: String);
var
  len: Integer;
begin
  len := Length(StrArr);
  SetLength(StrArr, len+1);
  StrArr[len] := NewItem;
end;

class procedure TFpSequenceExecutor.StringArrayAdd(var StrArr: TStringDynArray;
  NewItems: TStringDynArray);
var
  len, leni, I: Integer;
begin
  len := Length(StrArr);
  leni := Length(NewItems);
  SetLength(StrArr, len+leni);
  for I := 0 to leni-1 do
    StrArr[len+I] := NewItems[I];
end;

constructor TFpSequenceExecutor.Create(ASequence: TFpSequence; const UseTestMode: Boolean);
begin
  inherited Create(True);
  Self.FreeOnTerminate := True;

  FSequence := ASequence;
  FTestMode := UseTestMode;
  FState := esUnknow;
  //FCopyWaiting := False;
  FSizeThreshold := DEF_SIZE_THRESHOLD;
  FTimer := TTickTimer.Create;
  FCS := TCriticalSection.Create;

  FCopyWaitEvent := TSimpleEvent.Create(nil, True, True, 'FpSequenceExecutorCopyWait');
  FPauseWaitEvent := TSimpleEvent.Create(nil, True, True, 'FpSequenceExecutorPauseWait');
end;

destructor TFpSequenceExecutor.Destroy;
begin
  FCopyWaitEvent.SetEvent;
  FreeAndNil(FCopyWaitEvent);

  FPauseWaitEvent.SetEvent;
  FreeAndNil(FPauseWaitEvent);

  FreeAndNil(FTimer);
  FreeAndNil(FCS);
  inherited;
end;

procedure TFpSequenceExecutor.CallNotify;
var
  tmpNotfData: TFpNotificationData;
begin
  if Assigned(FOnNotfEvent) then begin
    tmpNotfData := FNotfData;
    FOnNotfEvent(tmpNotfData);
  end;
end;

procedure TFpSequenceExecutor.DoNotify(Notf: TFpExecutorNotification; Src, Dest: TFpFile;
  Op: TFpExecutorOperation; Prg, ID: Integer; Attr: TFileAttributes);
begin
  if not Assigned(FOnNotfEvent) then exit;

  FNotfData.Notification := Notf;
  FNotfData.Source := Src;
  FNotfData.Destination := Dest;
  FNotfData.Operation := Op;
  FNotfData.Progress := Prg;
  FNotfData.OperationID := ID;
  FNotfData.Attributes := Attr;

  Self.Synchronize(CallNotify);
end;

function TFpSequenceExecutor.GetCurrentBytes: Int64;
begin
  FCS.Enter;
  Result := FCurrentBytes;
  FCS.Leave;
end;

function TFpSequenceExecutor.GetCurrentFile: Integer;
begin
  FCS.Enter;
  Result := FCurrentFile;
  FCS.Leave;
end;

function TFpSequenceExecutor.GetProgress: Integer;
begin
  FCS.Enter;
  Result := FProgress;
  FCS.Leave;
end;

function TFpSequenceExecutor.GetRemainingTime: TTime;
begin
  FCS.Enter;
  Result := FRemainingTime;
  FCS.Leave;
end;

function TFpSequenceExecutor.GetSpeed: Integer;
begin
  FCS.Enter;
  Result := FSpeed;
  FCS.Leave;
end;

function TFpSequenceExecutor.GetState: TFpExecutorState;
begin
  FCS.Enter;
  Result := FState;
  FCS.Leave;
end;

function TFpSequenceExecutor.GetTestMode: Boolean;
begin
  FCS.Enter;
  Result := FTestMode;;
  FCS.Leave;
end;

function TFpSequenceExecutor.GetTotalBytes: Int64;
begin
  FCS.Enter;
  Result := FTotalBytes;
  FCS.Leave;
end;

function TFpSequenceExecutor.GetTotalFiles: Integer;
begin
  FCS.Enter;
  Result := FTotalFiles;
  FCS.Leave;
end;

procedure TFpSequenceExecutor.SetCurrentBytes(Value: Int64);
var
  diff: Int64;
begin
  if Value = 0 then exit;
  
  FCS.Enter;
  if Value > FTotalBytes then Value := FTotalBytes;

  diff := Value - FCurrentBytes;
  FCurrentBytes := Value;

  if not FTimer.Started then
    FTimer.Start
  else begin
    FTimer.Stop;
    FSpeed := Round(diff / FTimer.EllapsedTime);
    if FSpeed < 0 then begin
      FSpeed := 0;
    end else
      FRemainingTime := IncSecond(0, Round((FTotalBytes - FCurrentBytes) / FSpeed));
  end;

  FCS.Leave;
end;

procedure TFpSequenceExecutor.SetCurrentFile(Value: Integer);
begin
  FCS.Enter;
  FCurrentFile := Value;
  FCS.Leave;
end;

procedure TFpSequenceExecutor.SetProgress(Value: Integer);
begin
  FCS.Enter;
  FProgress := Value;
  FCS.Leave;
end;

procedure TFpSequenceExecutor.SetRemainingTime(Value: TTime);
begin
  FCS.Enter;
  FRemainingTime := Value;
  FCS.Leave;
end;

procedure TFpSequenceExecutor.SetSpeed(Value: Integer);
begin
  FCS.Enter;
  FSpeed := Value;
  FCS.Leave;
end;

procedure TFpSequenceExecutor.SetState(Value: TFpExecutorState);
begin
  FCS.Enter;
  FState := Value;
  FCS.Leave;
end;

procedure TFpSequenceExecutor.SetTotalBytes(Value: Int64);
begin
  FCS.Enter;
  FTotalBytes := Value;
  FCS.Leave;
end;

procedure TFpSequenceExecutor.SetTotalFiles(Value: Integer);
begin
  FCS.Enter;
  FTotalFiles := Value;
  FCS.Leave;
end;

procedure TFpSequenceExecutor.Stop;
begin
  if Self.State in [esAnalyzing, esWorking, esPaused] then begin
    Self.SetState(esStopping);
    Self.DoNotify(enStopping);
    FPauseWaitEvent.SetEvent;
    Self.Terminate;
  end;
end;

procedure TFpSequenceExecutor.Pause;
begin
  if Self.State in [esWorking] then begin
    Self.SetState(esPausing);
    Self.DoNotify(enPausing);
  end;
end;

procedure TFpSequenceExecutor.Restart;
begin
  if Self.State in [esPaused] then begin
    Self.SetState(esResuming);
    Self.DoNotify(enResuming);
    FPauseWaitEvent.SetEvent;
  end;
end;

procedure TFpSequenceExecutor.Execute;
var
  Action: TFpAction;
begin
  FFileID := 0;

  Self.SetState(esStarted);
  Self.DoNotify(enStarted);

  if not Assigned(FSequence) then begin
    Self.DoNotify(enFinished);
    exit;
  end;

  Self.SetState(esAnalyzing);
  Self.DoNotify(enAnalyzing);

  Self.ExecuteAnalysis;

  Self.SetState(esWorking);
  Self.DoNotify(enWorking);

  for Action in FSequence.Actions do begin
    if Self.State = esPausing then
      Self.ExecutePause;

    if Self.State = esStopping then
      break;
    
    Self.ExecuteAction(Action);
  end;

  Self.SetRemainingTime(0);
  Self.SetSpeed(0);

  Self.DoNotify(enFinished);
end;

procedure TFpSequenceExecutor.ExecuteAction(Action: TFpAction);
var
  ActFiles: TStringDynArray;
  actOp: TFpExecutorOperation;
  lenFiles, F: Integer;
  filePath, srcPath, destPath, destFolder: String;
  fileAttr: TFileAttributes;
  ok: Boolean;
begin
  if not Action.Enabled then exit;

  Self.DoNotify(enActionPicked, Action.Description);

  actOp := TFpExecutorOperation(Ord(Action.Operation));

  try
    //---
    if not TDirectory.Exists(Action.SourceFolder, True) then exit;

    Self.DoNotify(enFolderPicked, Action.SourceFolder);

    if Action.IncludeSubFolders then
      ActFiles := TDirectory.GetFiles(Action.SourceFolder, TSearchOption.soAllDirectories, nil)
    else
      ActFiles := TDirectory.GetFiles(Action.SourceFolder, TSearchOption.soTopDirectoryOnly, nil);

    lenFiles := High(ActFiles);
    for F := 0 to lenFiles do begin
      FFileID := FFileID + 1;

      if Self.State = esPausing then
        Self.ExecutePause;

      if Self.State = esStopping then
        break;

      try
        //---//---
        filePath := ActFiles[F];
        srcPath := filePath;

        if Action.Operation <> okDelete then begin
          destPath := StringReplace(
            filePath,
            NormalizeFolderPath(Action.SourceFolder),
            NormalizeFolderPath(Action.DestFolder),
            [rfIgnoreCase]
          );
        end;

        Self.DoNotify(enFileEvaluating, srcPath, destPath, actOp, 0, FFileID);

        if not Action.EvaluateFilters(srcPath, fileAttr) then begin
          Self.DoNotify(enFileEvaluatedFalse, filePath, destPath, actOp, 0, FFileID);
          continue;
        end else
          Self.DoNotify(enFileEvaluatedTrue, srcPath, destPath, actOp, 0, FFileID);

        if Action.Operation <> okDelete then begin
          destFolder := ExtractFileDir(destPath);
          if (not TDirectory.Exists(destFolder, False)) and (not Self.TestMode) then begin
            if not ForceDirectories(destFolder) then begin
              Self.DoNotify(enFileError, srcPath, destPath, actOp, 0, FFileID, fileAttr);
              continue;
            end;
          end;
        end;

        if OS_VISTA and (TFileAttribute.faSymLink in fileAttr)
          and (TFileAttribute.faSymLink in Action.FileTypes) then begin
            if not TFile.GetSymLinkTarget(filePath, srcPath) then begin
              Self.DoNotify(enFileError, filePath, destPath, actOp, 0, FFileID, fileAttr);
              continue;
            end;
        end;

        Self.SetCurrentFile(Self.CurrentFile + 1);
        Self.DoNotify(enFileStarted, srcPath, destPath, actOp, 0, FFileID, fileAttr);

        actOp := Self.ExecuteOperation(
          Action.Operation, srcPath, destPath, fileAttr,
          Action.FileExistsDecision, Action.FileNotExistsDecision,
          FFileID
        );

        Self.ExecuteProgress;
        Self.DoNotify(enFileFinished, srcPath, destPath, actOp, 0, FFileID, fileAttr);
        //---//---
      except
        Self.DoNotify(enFileError, filePath, destPath, actOp, 0, FFileID, fileAttr);
        continue;
      end;
    end;

    if Action.DeleteEmptyFolders then begin
      fileAttr := [TFileAttribute.faDirectory];
      ActFiles := TDirectory.GetDirectories(Action.SourceFolder, TSearchOption.soAllDirectories, nil);
      lenFiles := Length(ActFiles);
      ok := (lenFiles > 0);
      while ok do begin
        ok := False;
        for F := 0 to lenFiles-1 do begin
          try
            filePath := ActFiles[F];
            if (filePath = '') or (not TDirectory.Exists(filePath))
            or (not TDirectory.IsEmpty(filePath)) then continue;

            ok := True;
            ActFiles[F] := '';
            FFileID := FFileID + 1;

            Self.DoNotify(enFileStarted, filePath, '', eoDelete, 0, FFileID, fileAttr);
            ExecuteDelete(filePath, True);
            Self.DoNotify(enFileFinished, filePath, '', eoDelete, 0, FFileID, fileAttr);
          except
            Self.DoNotify(enFileError, filePath, '', eoDelete, 0, FFileID, fileAttr);
          end;
        end;
      end;
    end;

    //---
  except
  end;
end;

function TFpSequenceExecutor.ExecuteOperation(Operation: TFpOperationKind; Source,
  Dest: String; Attr: TFileAttributes; ExistsDecision: TFpOnExistsDecision;
  NotExistsDecision: TFpOnNotExistsDecision; FileID: Integer): TFpExecutorOperation;
var
  destExists, trackProg, greater, newer, sizeEquals, dateEquals: Boolean;
  fileSize, destSize, lastBytes: Int64;
  fileDate, destDate: TDateTime;
  fileStream: TFileStream;
  progCallback: TExecuteCopyCallback;
  exOp: TFpExecutorOperation;
  lastFileProg: Integer;
  SrcPath, DestPath: String;

  procedure CallCopy;
  begin
    if trackProg then fileSize := 0;
    if not Self.ExecuteCopy(SrcPath, DestPath, False, trackProg, progCallback) then
      Self.DoNotify(enFileError, srcPath, destPath, Result, 0, FileID, Attr);
  end;

  procedure CallMove;
  begin
    if trackProg then fileSize := 0;
    if not Self.ExecuteCopy(SrcPath, DestPath, True, trackProg, progCallback) then
      Self.DoNotify(enFileError, srcPath, destPath, Result, 0, FileID, Attr);
  end;

  function GetNextName(const Name: String): String;
  var
    N, D: Integer;
    newName: String;
    hasExt: Boolean;
  begin
    N := 2;
    hasExt := TPath.HasExtension(Name);
    D := LastDelimiter('.', Name);
    repeat
      if hasExt then
        newName := StuffString(Name, D, 0, ' (' + IntToStr(N) + ')')
      else
        newName := Name + ' (' + IntToStr(N) + ')';

      N := N + 1;
    until not TFile.Exists(newName);
    Result := newName;
  end;
begin
  //----------------------------------------
  progCallback := function(Bytes, TotalBytes: Int64): Boolean
  var
    fileProg: Integer;
  begin
    Result := True;
    Self.SetCurrentBytes(Self.CurrentBytes + (Bytes - lastBytes));
    lastBytes := Bytes;
    if Bytes >= TotalBytes then begin
      Self.DoNotify(enFileProgress, SrcPath, DestPath, exOp, 100, FileID, Attr);
      FCopyWaitEvent.SetEvent;
    end else begin
      fileProg := Trunc((Bytes / TotalBytes) * 100);
      if fileProg <> lastFileProg then begin
        lastFileProg := fileProg;
        Self.DoNotify(enFileProgress, SrcPath, DestPath, exOp, fileProg, FileID, Attr);
      end;
      if Self.State = esStopping then begin
        Result := False;
        FCopyWaitEvent.SetEvent;
      end;
    end;
    Self.ExecuteProgress;
  end;
  //----------------------------------------

  exOp := TFpExecutorOperation(Ord(Operation));
  Result := exOp;

  SrcPath := Source;
  DestPath := Dest;

  fileStream := TFile.OpenRead(srcPath);
  if fileStream <> nil then begin
    fileSize := fileStream.Size;
    FreeAndNil(fileStream);
  end else begin
    Self.DoNotify(enFileError, srcPath, destPath, Result, 0, FileID, Attr);
    exit;
  end;

  destSize := 0;
  greater := False;
  newer := False;
  sizeEquals := False;
  dateEquals := False;
  lastBytes := 0;
  lastFileProg := 0;

  try

  destExists := TFile.Exists(DestPath, False);
  trackProg := (fileSize > FSizeThreshold);

  if destExists then begin
    fileStream := TFile.OpenRead(DestPath);
    if fileStream <> nil then begin
      destSize := fileStream.Size;
      FreeAndNil(fileStream);
    end;

    fileDate := TFile.GetLastWriteTime(SrcPath);
    destDate := TFile.GetLastWriteTime(DestPath);

    greater := (fileSize > destSize);
    sizeEquals := (fileSize = destSize);

    newer := (CompareDateTime(fileDate, destDate) = GreaterThanValue);
    dateEquals := (CompareDateTime(fileDate, destDate) = EqualsValue);
  end;

  case Operation of
    okDelete: begin
      if not Self.TestMode then ExecuteDelete(SrcPath);
    end;

    okCopy: begin
      if destExists then begin

        case ExistsDecision of
          edOverwrite: begin
            CallCopy;
          end;
          edOverwriteIfNewer: begin
            if (newer) and (not dateEquals) then CallCopy else Result := eoSkip;
          end;
          edOverwriteIfOlder: begin
            if (not newer) and (not dateEquals) then CallCopy else Result := eoSkip;
          end;
          edOverwriteIfGreater: begin
            if (greater) and (not sizeEquals) then CallCopy else Result := eoSkip;
          end;
          edOverwriteIfSmaller: begin
            if (not greater) and (not sizeEquals) then CallCopy else Result := eoSkip;
          end;
          edSkip: begin
            Result := eoSkip;
          end;
          edSkipDelete: begin
            Result := eoDelete;
            ExecuteDelete(SrcPath);
          end;
          edKeepBoth: begin
            DestPath := GetNextName(DestPath);
            CallCopy;
          end;
        end;

      end else begin

        case NotExistsDecision of
          ndContinue: begin
            CallCopy;
          end;
          ndSkip: begin
            Result := eoSkip;
          end;
          ndDelete: begin
            Result := eoDelete;
            ExecuteDelete(SrcPath);
          end;
        end;

      end;
    end;

    okMove: begin
      if destExists then begin

        case ExistsDecision of
          edOverwrite: begin
            CallMove;
          end;
          edOverwriteIfNewer: begin
            if (newer) and (not dateEquals) then CallMove else Result := eoSkip;
          end;
          edOverwriteIfOlder: begin
            if (not newer) and (not dateEquals) then CallMove else Result := eoSkip;
          end;
          edOverwriteIfGreater: begin
            if (greater) and (not sizeEquals) then CallMove else Result := eoSkip;
          end;
          edOverwriteIfSmaller: begin
            if (not greater) and (not sizeEquals) then CallMove else Result := eoSkip;
          end;
          edSkip: begin
            Result := eoSkip;
          end;
          edSkipDelete: begin
            Result := eoDelete;
            ExecuteDelete(SrcPath);
          end;
          edKeepBoth: begin
            DestPath := GetNextName(DestPath);
            CallMove;
          end;
        end;

      end else begin

        case NotExistsDecision of
          ndContinue: begin
            CallMove;
          end;
          ndSkip: begin
            Result := eoSkip;
          end;
          ndDelete: begin
            Result := eoDelete;
            ExecuteDelete(srcPath);
          end;
        end;

      end;
    end;
    //case
  end;

  finally
    if fileSize > 0 then
      Self.SetCurrentBytes(Self.CurrentBytes + fileSize);
  end;
end;

function TFpSequenceExecutor.ExecuteCopy(SrcPath, DestPath: String; DeleteSrc,
  TrackProgress: Boolean; Callback: TExecuteCopyCallback): Boolean;
var
  flags: Cardinal;
begin
  Result := True;

  if Self.TestMode then exit;  

  if not(SrcPath[1] = '\') then //and (SrcPath[2] = '\') then
    SrcPath := '\\?\' + SrcPath;

  if not(DestPath[1] = '\') then //and (DestPath[2] = '\') then
    DestPath := '\\?\' + DestPath;

  flags := COPY_FILE_ALLOW_DECRYPTED_DESTINATION;
  if OS_VISTA then
    flags := flags or COPY_FILE_NO_BUFFERING or COPY_FILE_COPY_SYMLINK;

  try
    if not TrackProgress then begin
      TFile.Copy(SrcPath, DestPath, True);
      if DeleteSrc then ExecuteDelete(SrcPath);
    end else begin
      FCopyWaitEvent.ResetEvent;

      Result := CopyFileEx(
        PChar(SrcPath), PChar(DestPath),
        @CopyProgressCallback, @Callback, nil,
        flags
      );

      if Result then begin
        FCopyWaitEvent.WaitFor(INFINITE);

        if DeleteSrc and (Self.State <> esStopping) then
          ExecuteDelete(SrcPath);
      end;

    end;
  except
    Result := False;
  end;
end;

procedure TFpSequenceExecutor.ExecuteDelete(Path: String; const IsDirectory: Boolean);
begin
  if Self.TestMode then exit;
  
  if not(Path[1] = '\') and (Path[2] = '\') then
    Path := '\\?\' + Path;

  if IsDirectory then
    TDirectory.Delete(Path, False)
  else
    TFile.Delete(Path);
end;

procedure TFpSequenceExecutor.ExecuteAnalysis;
var
  Action: TFpAction;
  ActFiles: TStringDynArray;
  len, I, tFiles: Integer;
  fPath, srcPath: String;
  fStream: TFileStream;
  tBytes: Int64;
  fileAttr: TFileAttributes;
begin
  tBytes := 0;
  tFiles := 0;

  for Action in FSequence.Actions do begin
    if Self.State = esStopping then break;

    if not Action.Enabled then continue;
    try

      if TDirectory.Exists(Action.SourceFolder, True) then begin
        if Action.IncludeSubFolders then
          ActFiles := TDirectory.GetFiles(Action.SourceFolder, TSearchOption.soAllDirectories, nil)
        else
          ActFiles := TDirectory.GetFiles(Action.SourceFolder, TSearchOption.soTopDirectoryOnly, nil);

        len := High(ActFiles);
        for I := 0 to len do begin
          if Self.State = esStopping then break;
          try

            fPath := ActFiles[I];
            if not Action.EvaluateFilters(fPath, fileAttr) then continue;

            srcPath := fPath;
            if OS_VISTA and (TFileAttribute.faSymLink in fileAttr)
            and (TFileAttribute.faSymLink in Action.FileTypes) then begin
              if not TFile.GetSymLinkTarget(fPath, srcPath) then continue;
            end;

            fStream := TFile.OpenRead(srcPath);
            if fStream <> nil then begin
              tBytes := tBytes + fStream.Size;
              FreeAndNil(fStream);
              tFiles := tFiles + 1;

              if (tFiles mod 10 = 0) then begin
                Self.SetTotalBytes(tBytes);
                Self.SetTotalFiles(tFiles);
              end;
            end;

          except
            continue;
          end;
        end;
        SetLength(ActFiles, 0);
      end;

    except
      continue;
    end;
  end;

  Self.SetTotalBytes(tBytes);
  Self.SetTotalFiles(tFiles);
end;

procedure TFpSequenceExecutor.ExecutePause;
begin
  if Self.State <> esPausing then exit;

  Self.SetState(esPaused);
  Self.DoNotify(enPaused);

  FPauseWaitEvent.ResetEvent;
  FPauseWaitEvent.WaitFor(INFINITE);

  if Self.State = esResuming then begin  
    Self.SetState(esWorking);
    Self.DoNotify(enResume);
  end;
end;

procedure TFpSequenceExecutor.ExecuteProgress;
var
  curProg, newProg: Integer;
  totBytes, curBytes: Int64;
begin
  curProg := Self.Progress;
  totBytes := Self.TotalBytes;
  curBytes := Self.CurrentBytes;
  newProg := Trunc((curBytes / totBytes) * 100);
  if newProg <> curProg then begin
    Self.SetProgress(newProg);
    Self.DoNotify(enProgress, '', '', eoNone, newProg, 0);
  end;
end;

{$WARN SYMBOL_PLATFORM ON}

function CopyProgressCallback(
  TotalFileSize, TotalBytesTransferred, StreamSize, StreamBytesTransferred: LARGE_INTEGER;
  dwStreamNumber, dwCallbackReason: DWORD;
  hSourceFile, hDestinationFile: THANDLE;
  lpData: LPVOID
): DWORD; stdcall;
var
  execCallback: TExecuteCopyCallback;
begin
  Result := PROGRESS_CONTINUE;
  if dwCallbackReason = CALLBACK_CHUNK_FINISHED then begin
    if lpData <> nil then begin
      execCallback := PExecuteCopyCallback(lpData)^;
      if not execCallback(TotalBytesTransferred.QuadPart, TotalFileSize.QuadPart) then
        Result := PROGRESS_CANCEL;
    end;
  end;
end;

end.
