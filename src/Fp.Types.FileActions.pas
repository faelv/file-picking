unit Fp.Types.FileActions;

interface

uses

  System.IOUtils, System.Generics.Collections, System.Types, System.SysUtils,
  System.Classes, System.DateUtils, System.StrUtils;

type

  {$WARN SYMBOL_PLATFORM OFF}

  TFpFile = String;
  TFpFolder = String;
  TFpValues = TStringList;

  TFpOperationKind = (okCopy, okMove, okDelete);

  TFilterNodeKind = (fkAnd, fkOr);

  TFpOnExistsDecision = (
    edOverwrite,
    edOverwriteIfNewer,
    edOverwriteIfOlder,
    edOverwriteIfGreater,
    edOverwriteIfSmaller,
    edSkip,
    edSkipDelete,
    edKeepBoth
  );

  TFpOnNotExistsDecision = (
    ndContinue,
    ndSkip,
    ndDelete
  );

  TFpFileAttributes = (
    faName,
    faExtension,
    faPath,
    faSize,
    faCreated,
    faModified
  );

  TFpComparison = (
    fcEqual,
    fcNotEqual,
    fcGreater,
    fcGreaterEqual,
    fcSmaller,
    fcSmallerEqual,
    fcIn,
    fcNotIn,
    fcContains,
    fcNotContains
  );

  TFpValidateResult = (vrOk, vrNoActions, vrNoDestDir, vrNoSrcDir, vrNoFileTypes);

  TFpFilter = class;
  TFpFilterNode = class;
  TFpFilterList = class;
  TFpSequence = class;
  TFpActionList = class;
  TFpAction = class;
  TFpFilterNodeList = class;

  TGenericCollectionNotification = System.Generics.Collections.TCollectionNotification;

  TFpFilterChangeEvent = procedure (Sender: TFpFilter) of object;

  TFpFilter = class(TObject)
    private
      class var
        FFmtSettings: TFormatSettings;
        FFmtSettingsSet: Boolean;
    private
      FAttribute: TFpFileAttributes;
      FComparison: TFpComparison;
      FValues: TFpValues;
      FParent: TFpFilterList;
      FOnChange: TFpFilterChangeEvent;
      procedure DoOnChange;
      procedure SetAttribute(const Value: TFpFileAttributes);
      procedure SetComparison(const Value: TFpComparison);
      procedure OnValuesChange(Sender: TObject);
    public
      destructor Destroy; override;
      constructor Create(AParent: TFpFilterList);
      property Parent: TFpFilterList read FParent;
      property Attribute: TFpFileAttributes read FAttribute write SetAttribute;
      property Comparison: TFpComparison read FComparison write SetComparison;
      property Values: TFpValues read FValues;
      function Evaluate(const Source: TFpFile): Boolean;
      property OnChange: TFpFilterChangeEvent read FOnChange write FOnChange;
  end;

  TFpFilterListChangeKind = (ftcAdd, ftcRemove, ftcClear, ftcChange);

  TFpFilterListChangeEvent = procedure (Sender: TFpFilterList; Filter: TFpFilter; Kind: TFpFilterListChangeKind) of object;

  TFpFilterList = class(TObjectList<TFpFilter>)
    private
      FParent: TFpFilterNode;
      FOnChange: TFpFilterListChangeEvent;
      procedure DoOnChange(Filter: TFpFilter; Kind: TFpFilterListChangeKind);
      procedure OnChildChange(Sender: TFpFilter);
    protected
      procedure Notify(const Value: TFpFilter; Action: TGenericCollectionNotification); override;
    public
      constructor Create(AParent: TFpFilterNode);
      property Parent: TFpFilterNode read FParent;
      property OnChange: TFpFilterListChangeEvent read FOnChange write FOnChange;
      function New: TFpFilter;
      procedure Clear; reintroduce;
  end;

  TFpNodeChangeEvent = procedure (Sender: TFpFilterNode) of object;

  TFpNodeListChangeKind = (ncAdd, ncRemove, ncClear, ncChange);

  TFpNodeListChangeEvent = procedure (Sender: TFpFilterNodeList; Node: TFpFilterNode; Kind: TFpNodeListChangeKind) of object;

  TFpFilterNode = class(TObject)
    private
      FKind: TFilterNodeKind;
      FItems: TFpFilterList;
      FNodes: TFpFilterNodeList;
      FParent: TFpFilterNodeList;
      FOnChange: TFpNodeChangeEvent;
      procedure DoOnChange;
      procedure SetKind(const Value: TFilterNodeKind);
      procedure OnItemsChange(Sender: TFpFilterList; Filter: TFpFilter; Kind: TFpFilterListChangeKind);
      procedure OnNodesChange(Sender: TFpFilterNodeList; Node: TFpFilterNode; Kind: TFpNodeListChangeKind);
    public
      constructor Create(AParent: TFpFilterNodeList);
      destructor Destroy; override;
      property Parent: TFpFilterNodeList read FParent;
      property Kind: TFilterNodeKind read FKind write SetKind;
      property Items: TFpFilterList read FItems;
      property Nodes: TFpFilterNodeList read FNodes;
      function Evaluate(const Source: TFpFile): Boolean;
      property OnChange: TFpNodeChangeEvent read FOnChange write FOnChange;
  end;

  TFpFilterNodeList = class(TObjectList<TFpFilterNode>)
    private
      FParent: TFpFilterNode;
      FOnChange: TFpNodeListChangeEvent;
      procedure DoOnChange(Node: TFpFilterNode; Kind: TFpNodeListChangeKind);
      procedure OnChildChange(Sender: TFpFilterNode);
    protected
      procedure Notify(const Value: TFpFilterNode; Action: TGenericCollectionNotification); override;
    public
      constructor Create(AParent: TFpFilterNode);
      property Parent: TFpFilterNode read FParent;
      property OnChange: TFpNodeListChangeEvent read FOnChange write FOnChange;
      function New: TFpFilterNode;
      procedure Clear; reintroduce;
  end;

  TFpActionChangeEvent = procedure (Sender: TFpAction) of object;

  TFpAction = class(TObject)
    private
      FDescription: String;
      FSourceFolder: TFpFOlder;
      FDestFolder: TFpFolder;
      FIncludeSubFolders: Boolean;
      FOperation: TFpOperationKind;
      FFileTypes: System.IOUtils.TFileAttributes;
      FEnabled: Boolean;
      FFilters: TFpFilterNodeList;
      FParent: TFpActionList;
      FOnChange: TFpActionChangeEvent;
      FFileExistsDecision: TFpOnExistsDecision;
      FFileNotExistsDecision: TFpOnNotExistsDecision;
    FDeleteEmptyFolders: Boolean;
      procedure SetDestFolder(const Value: TFpFolder);
      procedure SetSourceFolder(const Value: TFpFolder);
      procedure DoOnChange;
      procedure OnFiltersChange(Sender: TFpFilterNodeList; Node: TFpFilterNode; Kind: TFpNodeListChangeKind);
      procedure SetDescription(const Value: String);
      procedure SetEnabled(const Value: Boolean);
      procedure SetFileTypes(const Value: TFileAttributes);
      procedure SetIncludeSubFolders(const Value: Boolean);
      procedure SetOperation(const Value: TFpOperationKind);
      procedure SetFileExistsDecision(const Value: TFpOnExistsDecision);
      procedure SetFileNotExistsDecision(const Value: TFpOnNotExistsDecision);
    procedure SetDeleteEmptyFolders(const Value: Boolean);
    public
      constructor Create(AParent: TFpActionList);
      destructor Destroy; override;
      property Parent: TFpActionList read FParent;
      property Enabled: Boolean read FEnabled write SetEnabled;
      property Description: String read FDescription write SetDescription;
      property SourceFolder: TFpFolder read FSourceFolder write SetSourceFolder;
      property DestFolder: TFpFolder read FDestFolder write SetDestFolder;
      property IncludeSubFolders: Boolean read FIncludeSubFolders write SetIncludeSubFolders;
      property DeleteEmptyFolders: Boolean read FDeleteEmptyFolders write SetDeleteEmptyFolders;
      property FileTypes: TFileAttributes read FFileTypes write SetFileTypes;
      property Operation: TFpOperationKind read FOperation write SetOperation;
      property FileExistsDecision: TFpOnExistsDecision read FFileExistsDecision write SetFileExistsDecision;
      property FileNotExistsDecision: TFpOnNotExistsDecision read FFileNotExistsDecision write SetFileNotExistsDecision;
      property Filters: TFpFilterNodeList read FFilters write FFilters;
      property OnChange: TFpActionChangeEvent read FOnChange write FOnChange;
      function EvaluateFilters(const Source: TFpFile; out Attributes: TFileAttributes): Boolean;
  end;

  TFpActionListChangeKind = (acAdd, acRemove, acClear, acChange);

  TFpActionListChangeEvent = procedure (Sender: TFpActionList; Action: TFpAction; Kind: TFpActionListChangeKind) of object;

  TFpActionList = class(TObjectList<TFpAction>)
    private
      FParent: TFpSequence;
      FOnChange: TFpActionListChangeEvent;
      procedure DoOnChange(Action: TFpAction; Kind: TFpActionListChangeKind);
      procedure OnChildChange(Sender: TFpAction);
    protected
      procedure Notify(const Value: TFpAction; Action: TGenericCollectionNotification); override;
    public
      constructor Create(AParent: TFpSequence);
      property Parent: TFpSequence read FParent;
      property OnChange: TFpActionListChangeEvent read FOnChange write FOnChange;
      function New: TFpAction;
      procedure Clear; reintroduce;
  end;

  TFpSequence = class(TObject)
    private
      FActions: TFpActionList;
    public
      constructor Create;
      destructor Destroy; override;
      property Actions: TFpActionList read FActions;
      procedure Clear;
      function Validate(out Action: TFpAction): TFpValidateResult;
  end;

  function NormalizeFolderPath(const Folder: String): String;

implementation

function NormalizeFolderPath(const Folder: String): String;
begin
  Result := Trim(Folder);
  if Result = '' then exit;  

  // substituir tipo correto de barra
  Result := StringReplace(Result, '/', '\', [rfReplaceAll]);

  // remover barras duplas
  while Pos('\\', Result) > 0 do
    Result := StringReplace(Result, '\\', '\', [rfReplaceAll]);

  // remover barra final se existir
  if Result[Length(Result)] = '\' then
    Result := Copy(Result, 1, Length(Result) - 1);

  // corrigir caminho de rede, se existir
  if Result[1] = '\' then
    Result := '\' + Result;
end;

{ TFpSequence }

procedure TFpSequence.Clear;
begin
  FActions.Clear;
end;

constructor TFpSequence.Create;
begin
  FActions := TFpActionList.Create(Self);
end;

destructor TFpSequence.Destroy;
begin
  FActions.Free;
  inherited;
end;

function TFpSequence.Validate(out Action: TFpAction): TFpValidateResult;
var
  act: TFpAction;
begin
  Result := vrOk;
  Action := nil;

  if FActions.Count = 0 then begin
    Result := vrNoActions;
    exit;
  end;

  for act in FActions do begin

    if act.SourceFolder = '' then begin
      Result := vrNoSrcDir;
      Action := act;
      break;
    end;

    if act.FileTypes = [] then begin
      Result := vrNoFileTypes;
      Action := act;
      break;
    end;

    if (act.Operation <> okDelete) and (act.DestFolder = '') then begin
      Result := vrNoDestDir;
      Action := act;
      break;
    end;

  end;
end;

{ TFpActionList }

procedure TFpActionList.Clear;
begin
  inherited Clear;
  Self.DoOnChange(nil, acClear);
end;

constructor TFpActionList.Create(AParent: TFpSequence);
begin
  inherited Create(True);
  FParent := AParent;
end;

procedure TFpActionList.DoOnChange(Action: TFpAction; Kind: TFpActionListChangeKind);
begin
  if Assigned(FOnChange) then
    FOnChange(Self, Action, Kind);
end;

function TFpActionList.New: TFpAction;
begin
  Result := TFpAction.Create(Self);
  Result.OnChange := Self.OnChildChange;
  Self.Add(Result);
end;

procedure TFpActionList.Notify(const Value: TFpAction; Action: TGenericCollectionNotification);
begin
  if Action = TGenericCollectionNotification.cnAdded then
    Self.DoOnChange(Value, acAdd)
  else if Action = TGenericCollectionNotification.cnRemoved then
    Self.DoOnChange(Value, acRemove);

  inherited;
end;

procedure TFpActionList.OnChildChange(Sender: TFpAction);
begin
  Self.DoOnChange(Sender, acChange);
end;

{ TFpAction }

constructor TFpAction.Create(AParent: TFpActionList);
begin
  FParent := AParent;
  FEnabled := True;
  FFileExistsDecision := edOverwrite;
  FFileNotExistsDecision := ndContinue;
  FIncludeSubFolders := True;
  FDeleteEmptyFolders := False;
  FFileTypes := [TFileAttribute.faArchive];
  FOperation := okCopy;
  FFilters := TFpFilterNodeList.Create(nil);
  FFilters.OnChange := Self.OnFiltersChange;
end;

destructor TFpAction.Destroy;
begin
  FFilters.Free;
  inherited;
end;

procedure TFpAction.DoOnChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TFpAction.EvaluateFilters(const Source: TFpFile; out Attributes: TFileAttributes): Boolean;
var
  filterNode: TFpFilterNode;
begin
  Result := False;
  try
    Attributes := TFile.GetAttributes(Source, False);
    if not(Attributes <= Self.FileTypes) then exit;
  except
    exit;
  end;

  Result := True;
  if FFilters.Count = 0 then exit;

  for filterNode in FFilters do begin
    Result := filterNode.Evaluate(Source);
    if not Result then break;    
  end;
end;

procedure TFpAction.OnFiltersChange(Sender: TFpFilterNodeList; Node: TFpFilterNode;
  Kind: TFpNodeListChangeKind);
begin
  Self.DoOnChange;
end;

procedure TFpAction.SetDeleteEmptyFolders(const Value: Boolean);
begin
  FDeleteEmptyFolders := Value;
  Self.DoOnChange;
end;

procedure TFpAction.SetDescription(const Value: String);
begin
  FDescription := Value;
  Self.DoOnChange;
end;

procedure TFpAction.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
  Self.DoOnChange;
end;

procedure TFpAction.SetFileExistsDecision(const Value: TFpOnExistsDecision);
begin
  FFileExistsDecision := Value;
  Self.DoOnChange;
end;

procedure TFpAction.SetFileNotExistsDecision(const Value: TFpOnNotExistsDecision);
begin
  FFileNotExistsDecision := Value;
  Self.DoOnChange;
end;

procedure TFpAction.SetFileTypes(const Value: TFileAttributes);
begin
  FFileTypes := Value;
  Self.DoOnChange;
end;

procedure TFpAction.SetIncludeSubFolders(const Value: Boolean);
begin
  FIncludeSubFolders := Value;
  Self.DoOnChange;
end;

procedure TFpAction.SetOperation(const Value: TFpOperationKind);
begin
  FOperation := Value;
  Self.DoOnChange;
end;

procedure TFpAction.SetSourceFolder(const Value: TFpFolder);
begin
  FSourceFolder := NormalizeFolderPath(Value);
  Self.DoOnChange;
end;

procedure TFpAction.SetDestFolder(const Value: TFpFolder);
begin
  FDestFolder := NormalizeFolderPath(Value);
  Self.DoOnChange;
end;

{ TFpFilterNode }

constructor TFpFilterNode.Create(AParent: TFpFilterNodeList);
begin
  FParent := AParent;
  FKind := fkAnd;
  FItems := TFpFilterList.Create(Self);
  FNodes := TFpFilterNodeList.Create(Self);

  FItems.OnChange := Self.OnItemsChange;
  FNodes.OnChange := Self.OnNodesChange;
end;

destructor TFpFilterNode.Destroy;
begin
  FItems.Free;
  FNodes.Free;
  inherited;
end;

procedure TFpFilterNode.DoOnChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TFpFilterNode.Evaluate(const Source: TFpFile): Boolean;
var
  filter: TFpFilter;
  node: TFpFilterNode;
begin
  Result := False;

  if FKind = fkOr then begin

    for filter in FItems do begin
      Result := filter.Evaluate(Source);
      if Result then break;      
    end;

    for node in FNodes do begin
      if Result then break;
      Result := node.Evaluate(Source);
    end;

  end else begin

    Result := True;

    for filter in FItems do begin
      Result := Result and filter.Evaluate(Source);
      if not Result then break;
    end;

    for node in FNodes do begin
      if not Result then break;
      Result := Result and node.Evaluate(Source);
    end;

  end;
end;

procedure TFpFilterNode.OnItemsChange(Sender: TFpFilterList; Filter: TFpFilter;
  Kind: TFpFilterListChangeKind);
begin
  Self.DoOnChange;
end;

procedure TFpFilterNode.OnNodesChange(Sender: TFpFilterNodeList; Node: TFpFilterNode;
  Kind: TFpNodeListChangeKind);
begin
  Self.DoOnChange;
end;

procedure TFpFilterNode.SetKind(const Value: TFilterNodeKind);
begin
  FKind := Value;
  Self.DoOnChange;
end;

{ TFpFilterNodeList }

procedure TFpFilterNodeList.Clear;
begin
  Self.DoOnChange(nil, ncClear);
  inherited Clear;
end;

constructor TFpFilterNodeList.Create(AParent: TFpFilterNode);
begin
  inherited Create(True);
  FParent := AParent;
end;

procedure TFpFilterNodeList.DoOnChange(Node: TFpFilterNode; Kind: TFpNodeListChangeKind);
begin
  if Assigned(FOnChange) then
    FOnChange(Self, Node, Kind);
end;

function TFpFilterNodeList.New: TFpFilterNode;
begin
  Result := TFpFilterNode.Create(Self);
  Result.OnChange := Self.OnChildChange;
  Self.Add(Result);
end;

procedure TFpFilterNodeList.Notify(const Value: TFpFilterNode;
  Action: TGenericCollectionNotification);
begin
  if Action = TGenericCollectionNotification.cnAdded then
    Self.DoOnChange(Value, ncAdd)
  else if Action = TGenericCollectionNotification.cnRemoved then
    Self.DoOnChange(Value, ncRemove);

  inherited;
end;

procedure TFpFilterNodeList.OnChildChange(Sender: TFpFilterNode);
begin
  Self.DoOnChange(Sender, ncChange);
end;

{ TFpFilterList }

procedure TFpFilterList.Clear;
begin
  Self.DoOnChange(nil, ftcClear);
  inherited Clear;
end;

constructor TFpFilterList.Create(AParent: TFpFilterNode);
begin
  inherited Create(True);
  FParent := AParent;
end;

procedure TFpFilterList.DoOnChange(Filter: TFpFilter; Kind: TFpFilterListChangeKind);
begin
  if Assigned(FOnChange) then
    FOnChange(Self, Filter, Kind);
end;

function TFpFilterList.New: TFpFilter;
begin
  Result := TFpFilter.Create(Self);
  Result.OnChange := Self.OnChildChange;
  Self.Add(Result);
end;

procedure TFpFilterList.Notify(const Value: TFpFilter;
  Action: TGenericCollectionNotification);
begin
  if Action = TGenericCollectionNotification.cnAdded then
    Self.DoOnChange(Value, ftcAdd)
  else if Action = TGenericCollectionNotification.cnRemoved then
    Self.DoOnChange(Value, ftcRemove);

  inherited;
end;

procedure TFpFilterList.OnChildChange(Sender: TFpFilter);
begin
  Self.DoOnChange(Sender, ftcChange);
end;

{ TFpFilter }

constructor TFpFilter.Create(AParent: TFpFilterList);
begin
  FParent := AParent;
  FValues := TFpValues.Create;
  FAttribute := faName;
  FComparison := fcEqual;

  FValues.OnChange := Self.OnValuesChange;

  if not FFmtSettingsSet then begin
    FFmtSettingsSet := True;
    FFmtSettings := TFormatSettings.Create('');
  end;
end;

destructor TFpFilter.Destroy;
begin
  FValues.Free;
  inherited;
end;

procedure TFpFilter.DoOnChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TFpFilter.Evaluate(const Source: TFpFile): Boolean;
var
  I, M: Integer;
  attrStr, valStr: String;
  attrNum, valNum: Int64;
  valFloat: Extended;
  attrDate, valDate: TDateTime;
  attrErr: Boolean;
  fileStream: TFileStream;
  dateComp: TValueRelationship;
  sChar: Char;
begin
  Result := False;
  attrNum := 0;
  attrDate := 0;

  if FValues.Count = 0 then exit;

  attrErr := False;

  case FAttribute of
    faName: begin
      attrStr := LowerCase(ExtractFileName(Source));
    end;

    faExtension: begin
      attrStr := ExtractFileExt(Source);
      if (Length(attrStr) > 0) then
        attrStr := Copy(attrStr, 2, Length(attrStr)-1);
      attrStr := LowerCase(attrStr);
    end;

    faPath: begin
      attrStr := LowerCase(ExtractFileDir(Source));
    end;

    faSize: begin
      try
        fileStream := TFile.OpenRead(Source);
        if fileStream <> nil then begin
          attrNum := fileStream.Size;
          FreeAndNil(fileStream);
        end else
          attrErr := True;
      except
        attrErr := True;
      end;
    end;

    faCreated: begin
      try
        attrDate := TFile.GetCreationTime(Source);
      except
        attrErr := True;
      end;
    end;

    faModified: begin
      try
        attrDate := TFile.GetLastWriteTime(Source);
      except
        attrErr := True;
      end;
    end;
  end;

  if attrErr then exit;

  if FAttribute in [faSize] then begin

    for I := 0 to FValues.Count-1 do begin
      valStr := FValues.Strings[I];
      valStr := StringReplace(valStr, 'B', '', [rfReplaceAll, rfIgnoreCase]);
      valStr := StringReplace(valStr, 'i', '', [rfReplaceAll, rfIgnoreCase]);
      sChar := valStr[Length(valStr)];
      valStr := Copy(valStr, 1, Length(valStr)-1);

      M := 1;
      if CharInSet(sChar, ['K', 'k']) then
        M := 1024
      else if CharInSet(sChar, ['M', 'm']) then
        M := 1024*1024
      else if CharInSet(sChar, ['G', 'g']) then
        M := 1024*1024*1024;

      if not TryStrToFloat(valStr, valFloat, FFmtSettings) then continue;

      valNum := Trunc(valFloat * M);

      case FComparison of
        fcEqual: begin
          Result := attrNum = valNum;
          break;
        end;
        fcNotEqual: begin
          Result := attrNum <> valNum;
          break;
        end;
        fcGreater: begin
          Result := attrNum > valNum;
          break;
        end;
        fcGreaterEqual: begin
          Result := attrNum >= valNum;
          break;
        end;
        fcSmaller: begin
          Result := attrNum < valNum;
          break;
        end;
        fcSmallerEqual: begin
          Result := attrNum <= valNum;
          break;
        end;
        fcIn: begin
          Result := attrNum = valNum;
          if Result then break;          
        end;
        fcNotIn: begin
          Result := attrNum <> valNum;
          if not Result then break;
        end;
        fcContains: begin
          Result := attrNum < valNum;
        end;
        fcNotContains: begin
          Result := not(attrNum < valNum);
        end;
      end;
    end;

  end
  else if FAttribute in [faCreated, faModified] then begin

    for I := 0 to FValues.Count-1 do begin
      if not TryStrToDateTime(FValues.Strings[I], valDate, FFmtSettings) then continue;

      case FComparison of
        fcEqual: begin
          Result := (CompareDateTime(attrDate, valDate) = EqualsValue);
          break;
        end;
        fcNotEqual: begin
          dateComp := CompareDateTime(attrDate, valDate);
          Result := (dateComp = LessThanValue) or (dateComp = GreaterThanValue);
          break;
        end;
        fcGreater: begin
          Result := (CompareDateTime(attrDate, valDate) = GreaterThanValue);
          break;
        end;
        fcGreaterEqual: begin
          dateComp := CompareDateTime(attrDate, valDate);
          Result := (dateComp = GreaterThanValue) or (dateComp = EqualsValue);
          break;
        end;
        fcSmaller: begin
          Result := (CompareDateTime(attrDate, valDate) = LessThanValue);
          break;
        end;
        fcSmallerEqual: begin
          dateComp := CompareDateTime(attrDate, valDate);
          Result := (dateComp = LessThanValue) or (dateComp = EqualsValue);
          break;
        end;
        fcIn: begin
          Result := (CompareDateTime(attrDate, valDate) = EqualsValue);
          if Result then break;
        end;
        fcNotIn: begin
          dateComp := CompareDateTime(attrDate, valDate);
          Result := (dateComp = LessThanValue) or (dateComp = GreaterThanValue);
          if not Result then break;
        end;
        fcContains: begin
          Result := False;
        end;
        fcNotContains: begin
          Result := False;
        end;
      end;
    end;

  end else begin //strings

    for I := 0 to FValues.Count-1 do begin
      valStr := LowerCase(FValues.Strings[I]);

      case FComparison of
        fcEqual: begin
          Result := attrStr = valStr;
          break;
        end;
        fcNotEqual: begin
          Result := attrStr <> valStr;
          break;
        end;
        fcGreater: begin
          Result := Length(attrStr) > Length(valStr);
          break;
        end;
        fcGreaterEqual: begin
          Result := Length(attrStr) >= Length(valStr);
          break;
        end;
        fcSmaller: begin
          Result := Length(attrStr) < Length(valStr);
          break;
        end;
        fcSmallerEqual: begin
          Result := Length(attrStr) <= Length(valStr);
          break;
        end;
        fcIn: begin
          Result := attrStr = valStr;
          if Result then break;
        end;
        fcNotIn: begin
          Result := attrStr <> valStr;
          if not Result then break;
        end;
        fcContains: begin
          Result := ContainsText(attrStr, valStr);
        end;
        fcNotContains: begin
          Result := not ContainsText(attrStr, valStr);
        end;
      end;
    end;

  end;
end;

procedure TFpFilter.OnValuesChange(Sender: TObject);
begin
  Self.DoOnChange;
end;

procedure TFpFilter.SetAttribute(const Value: TFpFileAttributes);
begin
  FAttribute := Value;
  Self.DoOnChange;
end;

procedure TFpFilter.SetComparison(const Value: TFpComparison);
begin
  FComparison := Value;
  Self.DoOnChange;
end;

{$WARN SYMBOL_PLATFORM ON}

end.
