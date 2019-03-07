unit Fp.Types.SequenceStorage;

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
      function CreateFilterNodeNode(Parent: IXMLDOMNode; FilterNode: TFpFilterNode): IXMLDOMElement;
      function CreateFilterNode(Parent: IXMLDOMNode; Filter: TFpFilter): IXMLDOMElement;

      procedure LoadActionsNode(Node: IXMLDOMNode; Actions: TFpActionList);
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
var
  filtersXmlNode: IXMLDOMNode;
  filterNode: TFpFilterNode;
begin
  Result := Parent.ownerDocument.createElement('action');
  Parent.appendChild(Result);

  Result.setAttribute('enabled', Action.Enabled);
  Result.setAttribute('includeSubFolders', Action.IncludeSubFolders);
  Result.setAttribute('deleteEmptyFolders', Action.DeleteEmptyFolders);

  Result.setAttribute('fileTypeNormal', (TFileAttribute.faArchive in Action.FileTypes));
  Result.setAttribute('fileTypeReadOnly', (TFileAttribute.faReadOnly in Action.FileTypes));
  Result.setAttribute('fileTypeHidden', (TFileAttribute.faHidden in Action.FileTypes));
  Result.setAttribute('fileTypeSystem', (TFileAttribute.faSystem in Action.FileTypes));
  Result.setAttribute('fileTypeOffline', (TFileAttribute.faOffline in Action.FileTypes));
  Result.setAttribute('fileTypeEncrypted', (TFileAttribute.faEncrypted in Action.FileTypes));
  Result.setAttribute('fileTypeSymlink', (TFileAttribute.faSymLink in Action.FileTypes));

  Result.setAttribute('operation', Ord(action.Operation));
  Result.setAttribute('onExistsDecision', Ord(action.FileExistsDecision));
  Result.setAttribute('onNotExistsDecision', Ord(action.FileNotExistsDecision));

  TXmlStorage.CreateCDATAChild(Result, 'description', Action.Description);
  TXmlStorage.CreateCDATAChild(Result, 'sourceFolder', Action.SourceFolder);
  TXmlStorage.CreateCDATAChild(Result, 'destFolder', Action.DestFolder);

  filtersXmlNode := Parent.ownerDocument.createElement('filters');
  Result.appendChild(filtersXmlNode);

  for filterNode in action.Filters do
    Self.CreateFilterNodeNode(filtersXmlNode, filterNode);
end;

procedure TFpSequenceStorage.LoadActionsNode(Node: IXMLDOMNode; Actions: TFpActionList);
var
  action: TFpAction;
  child, filtersNode, childFilter: IXMLDOMNode;
  newFilter: TFpFilterNode;
  I, F: Integer;
  fa: TFileAttributes;
begin
  for I := 0 to Node.childNodes.length -1 do begin
    child := Node.childNodes.item[I];
    action := Actions.New;
    fa := [];

    with TXmlStorage do begin
      action.Enabled := GetNodeAttributeDef(child, 'enabled', True);
      action.IncludeSubFolders := GetNodeAttributeDef(child, 'includeSubFolders', True);
      action.DeleteEmptyFolders := GetNodeAttributeDef(child, 'deleteEmptyFolders', False);
      action.Description := GetNodeValueDef(child, 'description', '');
      action.SourceFolder := GetNodeValueDef(child, 'sourceFolder', '');
      action.DestFolder := GetNodeValueDef(child, 'destFolder', '');
      action.Operation := TFpOperationKind(Integer(GetNodeAttributeDef(child, 'operation', 0)));
      action.FileExistsDecision := TFpOnExistsDecision(
        Integer(GetNodeAttributeDef(child, 'onExistsDecision', 0))
      );
      action.FileNotExistsDecision := TFpOnNotExistsDecision(
        Integer(GetNodeAttributeDef(child, 'onNotExistsDecision', 0))
      );

      if Boolean(GetNodeAttributeDef(
        child, 'fileTypeNormal', (TFileAttribute.faArchive in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faArchive];

      if Boolean(GetNodeAttributeDef(
        child, 'fileTypeReadOnly', (TFileAttribute.faReadOnly in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faReadOnly];

      if Boolean(GetNodeAttributeDef(
        child, 'fileTypeHidden', (TFileAttribute.faHidden in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faHidden];

      if Boolean(GetNodeAttributeDef(
        child, 'fileTypeSystem', (TFileAttribute.faSystem in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faSystem];

      if Boolean(GetNodeAttributeDef(
        child, 'fileTypeOffline', (TFileAttribute.faOffline in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faOffline];

      if Boolean(GetNodeAttributeDef(
        child, 'fileTypeEncrypted', (TFileAttribute.faEncrypted in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faEncrypted];

      if Boolean(GetNodeAttributeDef(
        child, 'fileTypeSymlink', (TFileAttribute.faSymLink in action.FileTypes))
      ) then
        fa := fa + [TFileAttribute.faSymLink];

      action.FileTypes := fa;

      filtersNode := child.selectSingleNode('filters');
      if filtersNode <> nil then begin
        for F := 0 to filtersNode.childNodes.length-1 do begin
          childFilter := filtersNode.childNodes.item[F];
          newFilter := action.Filters.New;
          Self.LoadFilerNodeNode(childFilter, newFilter);
        end;
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
  Result.appendChild(valuesNode);

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
  if not(iComp in [Ord(fcEqual)..Ord(fcNotContains)]) then
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
      val := valNode.text;
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

  Result := Parent.ownerDocument.createElement('filterNode');
  Parent.appendChild(Result);

  Result.setAttribute('kind', Ord(FilterNode.Kind));

  itemsNode := Parent.ownerDocument.createElement('items');
  Result.appendChild(itemsNode);

  nodesNode := Parent.ownerDocument.createElement('nodes');
  Result.appendChild(nodesNode);

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

  actionsNode := Node.ownerDocument.createElement('actions');
  Node.appendChild(actionsNode);

  for action in FSequence.Actions do begin
    Self.CreateActionNode(actionsNode, action);
  end;
end;

{$WARN SYMBOL_PLATFORM ON}

end.
