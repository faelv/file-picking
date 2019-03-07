unit Fp.Types.FileActionsStorage;

interface

uses

  Fp.Types.FileActions, Fp.Types.Storage, Fp.Types.Interfaces,
  Winapi.msxml, System.IOUtils;

type

  {$WARN SYMBOL_PLATFORM OFF}

  TFpSequenceStorage = class(TSingletonInterfacedObject, IXmlStorageUser)
    private
      FStorage: TXmlStorage;
      FSequence: TFpSequence;
      function CreateActionNode(Parent: IXMLDOMNode; Action: TFpAction): IXMLDOMElement;
      function CreateOperationNode(Parent: IXMLDOMNode; Operation: TFpOperation): IXMLDOMElement;
      function CreateFilterNodeNode(Parent: IXMLDOMNode; FilterNode: TFpFilterNode): IXMLDOMElement;
      function CreateFilterNode(Parent: IXMLDOMNode; Filter: TFpFilter): IXMLDOMElement;

      procedure LoadActionsNode(Node: IXMLDOMNode; Actions: TFpActionList);
      function LoadOperationNode(Node: IXMLDOMNode): TFpOperation;
      procedure LoadFilerNodeNode(Node: IXMLDOMNode; FilterNode: TFpFilterNode);
      procedure LoadFilterNode(Node: IXMLDOMNode; Filter: TFpFilter);
    public //IXmlStorageUser
      procedure OnNodeLoad(Node: IXMLDOMNode);
      procedure OnNodeSave(Node: IXMLDOMNode);
      function GetStorageName: String;
    public
      constructor Create;
      destructor Destroy; override;
      property Sequence: TFpSequence read FSequence write FSequence;
      property Storage: TXmlStorage read FStorage;
  end;

implementation

{ TFpSequenceStorage }

constructor TFpSequenceStorage.Create;
begin
  FStorage := TXmlStorage.Create;
  FStorage.DocumentNamespaceURI := 'actions-storage-file';
  FStorage.AddUser(Self);
end;

function TFpSequenceStorage.CreateActionNode(Parent: IXMLDOMNode;
  Action: TFpAction): IXMLDOMElement;
begin
  Result := Parent.ownerDocument.createElement('action');
  Parent.appendChild(Result);

  Result.setAttribute('enabled', Action.Enabled);
  Result.setAttribute('includeSubFolders', Action.IncludeSubFolders);
  Result.setAttribute('fileTypeNormal', (TFileAttribute.faNormal in Action.FileTypes));
  Result.setAttribute('fileTypeReadOnly', (TFileAttribute.faReadOnly in Action.FileTypes));
  Result.setAttribute('fileTypeHidden', (TFileAttribute.faHidden in Action.FileTypes));
  Result.setAttribute('fileTypeSystem', (TFileAttribute.faSystem in Action.FileTypes));
  Result.setAttribute('fileTypeOffline', (TFileAttribute.faOffline in Action.FileTypes));
  Result.setAttribute('fileTypeEncrypted', (TFileAttribute.faEncrypted in Action.FileTypes));
  Result.setAttribute('fileTypeSymlink', (TFileAttribute.faSymLink in Action.FileTypes));
  TXmlStorage.CreateCDATAChild(Result, 'description', Action.Description);
  TXmlStorage.CreateCDATAChild(Result, 'baseFolder', Action.BaseFolder);

  Self.CreateOperationNode(Result, Action.Operation);
  Self.CreateFilterNodeNode(Result, Action.Filters);
end;

procedure TFpSequenceStorage.LoadActionsNode(Node: IXMLDOMNode; Actions: TFpActionList);
var
  action: TFpAction;
  child, opNode, filtersNode: IXMLDOMNode;
  I: Integer;
  fa: TFileAttributes;
begin
  for I := 0 to Node.childNodes.length -1 do begin
    child := Node.childNodes.item[I];
    action := Actions.New;
    fa := [];

    with TXmlStorage do begin
      action.Enabled := GetNodeAttributeDef(child, 'enabled', True);
      action.IncludeSubFolders := GetNodeAttributeDef(child, 'includeSubFolders', True);
      action.Description := GetNodeValueDef(child, 'description', '');
      action.BaseFolder := GetNodeValueDef(child, 'baseFolder', '');

      if Boolean(GetNodeAttributeDef(
        child, 'fileTypeNormal', (TFileAttribute.faNormal in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faNormal];

      if Boolean(GetNodeAttributeDef(
        child, 'fileTypeReadOnly', (TFileAttribute.faReadOnly in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faReadOnly];

      if Boolean(GetNodeAttributeDef(
        child, 'fileType', (TFileAttribute.faHidden in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faHidden];

      if Boolean(GetNodeAttributeDef(
        child, 'fileType', (TFileAttribute.faSystem in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faSystem];

      if Boolean(GetNodeAttributeDef(
        child, 'fileType', (TFileAttribute.faOffline in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faOffline];

      if Boolean(GetNodeAttributeDef(
        child, 'fileType', (TFileAttribute.faEncrypted in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faEncrypted];

      if Boolean(GetNodeAttributeDef(
        child, 'fileType', (TFileAttribute.faSymLink in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faSymLink];

      action.FileTypes := fa;

      opNode := child.selectSingleNode('operation');
      if opNode <> nil then
        action.Operation := Self.LoadOperationNode(opNode);

      filtersNode := child.selectSingleNode('filters');
      if filtersNode <> nil then begin
        action.Filters := TFpFilterNode.Create(nil);
        Self.LoadFilerNodeNode(filtersNode, action.Filters);
      end;
    end;
  end;
end;

function TFpSequenceStorage.CreateFilterNode(Parent: IXMLDOMNode;
  Filter: TFpFilter): IXMLDOMElement;
var
  valuesNode: IXMLDOMElement;
  I: Integer;
begin
  Result := Parent.ownerDocument.createElement('filter');
  Parent.appendChild(Result);

  Result.setAttribute('attribute', Ord(Filter.Attribute));
  Result.setAttribute('comparison', Ord(Filter.Comparison));

  valuesNode := Parent.ownerDocument.createElement('values');
  Parent.appendChild(valuesNode);

  for I := 0 to Filter.Values.Count -1 do
    TXmlStorage.CreateCDATAChild(valuesNode, 'value', Filter.Values[I]);
end;

procedure TFpSequenceStorage.LoadFilterNode(Node: IXMLDOMNode; Filter: TFpFilter);
var
  iAttr, iComp, I: Integer;
  attr: TFpFileAttributes;
  comp: TFpComparison;
  valuesNode, valNode: IXMLDOMNode;
  val: String;
begin
  iAttr := TXmlStorage.GetNodeAttributeDef(Node, 'attribute', 0);
  if not(iAttr in [Ord(faName)..Ord(faModified)]) then
    attr := faName
  else
    attr := TFpFileAttributes(iAttr);

  iComp := TXmlStorage.GetNodeAttributeDef(Node, 'comparison', 0);
  if not(iComp in [Ord(fcEqual)..Ord(fcNotIn)]) then
    comp := fcEqual
  else
    comp := TFpComparison(iComp);

  Filter.Attribute := attr;
  Filter.Comparison := comp;

  Filter.Values.Clear;
  valuesNode := Node.selectSingleNode('values');
  if valuesNode <> nil then begin
    for I := 0 to valuesNode.childNodes.length -1 do begin
      valNode := valuesNode.childNodes.item[I];
      val := TXmlStorage.GetNodeValueDef(valNode, 'value', '');
      if val <> '' then
        Filter.Values.Append(val);
    end;
  end;
end;

function TFpSequenceStorage.CreateFilterNodeNode(Parent: IXMLDOMNode;
  FilterNode: TFpFilterNode): IXMLDOMElement;
var
  item: TFpFilter;
  node: TFpFilterNode;
  itemsNode,
  nodesNode: IXMLDOMElement;
begin
  if not Assigned(FilterNode) then exit;

  Result := Parent.ownerDocument.createElement('filters');
  Parent.appendChild(Result);

  Result.setAttribute('kind', Ord(FilterNode.Kind));

  itemsNode := Parent.ownerDocument.createElement('items');
  Parent.appendChild(itemsNode);

  nodesNode := Parent.ownerDocument.createElement('nodes');
  Parent.appendChild(nodesNode);

  for item in FilterNode.Items do
    Self.CreateFilterNode(itemsNode, item);

  for node in FilterNode.Nodes do
    Self.CreateFilterNodeNode(nodesNode, node);
end;

procedure TFpSequenceStorage.LoadFilerNodeNode(Node: IXMLDOMNode;
  FilterNode: TFpFilterNode);
var
  iKind, I: Integer;
  kind: TFilterNodeKind;
  itemsNode,
  nodesNode,
  childNode: IXMLDOMNode;
begin
  if not Assigned(FilterNode) then exit;
  
  FilterNode.Nodes.Clear;
  FilterNode.Items.Clear;

  iKind := TXmlStorage.GetNodeAttributeDef(Node, 'kind', 0);
  if not(iKind in [Ord(fkAnd)..Ord(fkOr)]) then
    kind := fkAnd
  else
    kind := TFilterNodeKind(iKind);

  FilterNode.Kind := kind;

  itemsNode := Node.selectSingleNode('items');
  if itemsNode <> nil then begin
    for I := 0 to itemsNode.childNodes.length -1 do begin
      childNode := itemsNode.childNodes.item[I];
      Self.LoadFilterNode(childNode, FilterNode.Items.New);
    end;
  end;

  nodesNode := Node.selectSingleNode('nodes');
  if nodesNode <> nil then begin
    for I := 0 to nodesNode.childNodes.length -1 do begin
      childNode := nodesNode.childNodes.item[I];
      Self.LoadFilerNodeNode(childNode, FilterNode.Nodes.New);
    end;
  end;
end;

function TFpSequenceStorage.CreateOperationNode(Parent: IXMLDOMNode;
  Operation: TFpOperation): IXMLDOMElement;

begin
  Result := Parent.ownerDocument.createElement('operation');
  Parent.appendChild(Result);

  Result.setAttribute('kind', Ord(Operation.Kind));
  case Operation.Kind of
    okCopy: begin
      Result.setAttribute(
        'conflictDecision', Ord(TFpOperationCopy(Operation).ConflictDecision)
      );
      TXmlStorage.CreateCDATAChild(
        Result, 'destinationFolder', TFpOperationCopy(Operation).DestinationFolder
      );
    end;
    okMove: begin
      Result.setAttribute(
        'conflictDecision', Ord(TFpOperationMove(Operation).ConflictDecision)
      );
      TXmlStorage.CreateCDATAChild(
        Result, 'destinationFolder', TFpOperationMove(Operation).DestinationFolder
      );
    end;
  end;
end;

function TFpSequenceStorage.LoadOperationNode(Node: IXMLDOMNode): TFpOperation;
var
  iKind, iDec: Integer;
  kind: TFpOperationKind;
  decCopy: TFpCopyDecision;
  decMove: TFpMoveDecision;
begin
  Result := nil;

  iKind := TXmlStorage.GetNodeAttributeDef(Node, 'kind', 0);
  if not(iKind in [Ord(okCopy)..Ord(okDelete)]) then
    kind := okCopy
  else
    kind := TFpOperationKind(iKind);

  case kind of
    okCopy: begin
      Result := TFpOperationCopy.Create;

      iDec := TXmlStorage.GetNodeAttributeDef(Node, 'conflictDecision', 0);
      if not(iDec in [Ord(cdOverwrite)..Ord(cdKeepBoth)]) then
        decCopy := cdOverwrite
      else
        decCopy := TFpCopyDecision(iDec);

      TFpOperationCopy(Result).ConflictDecision := decCopy;
      TFpOperationCopy(Result).DestinationFolder := TXmlStorage.GetNodeValueDef(
        Node, 'destinationFolder', ''
      );
    end;

    okMove: begin
      Result := TFpOperationMove.Create;

      iDec := TXmlStorage.GetNodeAttributeDef(Node, 'conflictDecision', 0);
      if not(iDec in [Ord(mdOverwrite)..Ord(mdKeepBoth)]) then
        decMove := mdOverwrite
      else
        decMove := TFpMoveDecision(iDec);

      TFpOperationMove(Result).ConflictDecision := decMove;
      TFpOperationMove(Result).DestinationFolder := TXmlStorage.GetNodeValueDef(
        Node, 'destinationFolder', ''
      );
    end;

    okDelete: begin
      Result := TFpOperationDelete.Create;
    end;
  end;
end;

destructor TFpSequenceStorage.Destroy;
begin
  FStorage.Free;
  inherited;
end;

function TFpSequenceStorage.GetStorageName: String;
begin
  Result := 'action-sequence';
end;

procedure TFpSequenceStorage.OnNodeLoad(Node: IXMLDOMNode);
var
  actionsNode: IXMLDOMNode;
begin
  if not Assigned(FSequence) then exit;

  FSequence.Clear;

  FSequence.Name := TXmlStorage.GetNodeValueDef(Node, 'name', '');
  FSequence.Description := TXmlStorage.GetNodeValueDef(Node, 'description', '');

  actionsNode := Node.selectSingleNode('actions');
  if actionsNode <> nil then
    Self.LoadActionsNode(actionsNode, FSequence.Actions);
end;

procedure TFpSequenceStorage.OnNodeSave(Node: IXMLDOMNode);
var
  actionsNode: IXMLDOMElement;
  action: TFpAction;
begin
  if not Assigned(FSequence) then exit;

  TXmlStorage.CreateCDATAChild(Node, 'name', FSequence.Name);
  TXmlStorage.CreateCDATAChild(Node, 'description', FSequence.Description);

  actionsNode := Node.ownerDocument.createElement('actions');
  Node.appendChild(actionsNode);

  for action in FSequence.Actions do begin
    Self.CreateActionNode(actionsNode, action);
  end;
end;

{$WARN SYMBOL_PLATFORM ON}

end.
