unit Fp.Types.LangStorage;

interface

uses

  Winapi.msxml,
  System.Classes, System.SysUtils, System.TypInfo, System.Variants, System.IniFiles,
  Vcl.ComCtrls, VirtualTrees,
  Fp.Types.Storage, Fp.Types.Interfaces;

const

  DEF_DOC_ROOT_LANG: WideString      = 'language';
  DEF_DOC_NAMESPACE_LANG: WideString = 'langstorage';

  MAX_RECURSION_LEVELS: Integer = 5;

type

  IXMLDOMNode = Fp.Types.Storage.IXMLDOMNode;

  ILangStorageUser = interface
    ['{27131ACE-62DF-4FD2-8ADC-43DBF59330D6}']
    procedure OnLoadLangStrings(Node: IXMLDOMNode);
    function GetLangStorageName: String;
  end;

  TLangStorage = class(TXmlStorage)
    public
      constructor Create; override;
      function Save: Boolean; override;
      procedure ReloadSingle(Obj: TObject); override;
  end;

  TLangStorageMetadata = class(TSingletonInterfacedObject, ILangStorageUser)
    private
      FLanguage: String;
      FVersion: String;
      FAuthor: String;
      FLCID: Integer;
      FAppVersion: String;
    public // ILangStorageUser
      procedure OnLoadLangStrings(Node: IXMLDOMNode);
      function GetLangStorageName: String;
    public
      property LCID: Integer read FLCID;
      property Language: String read FLanguage;
      property Author: String read FAuthor;
      property Version: String read FVersion;
      property AppVersion: String read FAppVersion;
  end;

  TApplicationLanguage = class(TSingletonInterfacedObject, ILangStorageUser)
    private
      FStorage: TLangStorage;
      FGlobalsList: TStringList;
      FMetadata: TLangStorageMetadata;
      FStringRightMark: Char;
      FStringLeftMark: Char;
      RecursionLevel: Integer;
    protected
      function NodeString(const ID: String; Node: IXMLDOMNode): String;
      function IsPropLangID(const PropertyValue: String; out LangID: String): Boolean;
    public // ILangStorageUser
      procedure OnLoadLangStrings(Node: IXMLDOMNode);
      function GetLangStorageName: String;
    public
      constructor Create;
      destructor Destroy; override;
      property Storage: TLangStorage read FStorage;
      property Metadata: TLangStorageMetadata read FMetadata;
      property StringLeftMark: Char read FStringLeftMark write FStringLeftMark;
      property StringRightMark: Char read FStringRightMark write FStringRightMark;
      function Strings(const Name: String; const Default: String = ''): String;
      procedure SetComponentStrings(Comp: TPersistent; Node: IXMLDOMNode;
        const SetChildren: Boolean = True);
      procedure SetStringListStrings(StringList: TStrings; Node: IXMLDOMNode);
      procedure SetListColumnsStrings(ListColumns: TListColumns; Node: IXMLDOMNode);
      procedure SetVTColumnsStrings(VTColumns: TVirtualTreeColumns; Node: IXMLDOMNode);
  end;

implementation

{ TLangStorage }

constructor TLangStorage.Create;
begin
  inherited;
  Self.DocumentNamespaceURI := DEF_DOC_NAMESPACE_LANG;
  Self.DocumentRoot := DEF_DOC_ROOT_LANG;
end;

procedure TLangStorage.ReloadSingle(Obj: TObject);
var
  storageName: WideString;
  curIntf: ILangStorageUser;
  curNode: IXMLDOMNode;
begin
  if not Self.Loaded then
    exit;

  if Supports(Obj, ILangStorageUser, curIntf) then begin
    storageName := curIntf.GetLangStorageName;

    storageName := Format(SEL_NODE_TMPL, [String(storageName)]);
    curNode := XMLDocument.documentElement.selectSingleNode(storageName);
    if curNode <> nil then
      curIntf.OnLoadLangStrings(curNode);
  end;
end;

function TLangStorage.Save: Boolean;
begin
  Result := False;
end;

{ TApplicationLanguage }

constructor TApplicationLanguage.Create;
begin
  FStringLeftMark := '{';
  FStringRightMark := '}';

  FGlobalsList := THashedStringList.Create;
  FGlobalsList.CaseSensitive := False;

  FMetadata := TLangStorageMetadata.Create;

  FStorage := TLangStorage.Create;
  FStorage.AddUser(FMetadata);
  FStorage.AddUser(Self);

  RecursionLevel := 0;
end;

destructor TApplicationLanguage.Destroy;
begin
  FStorage.Free;
  FGlobalsList.Free;
  FMetadata.Free;
  inherited;
end;

function TApplicationLanguage.GetLangStorageName: String;
begin
  Result := 'globals';
end;

function TApplicationLanguage.IsPropLangID(const PropertyValue: String;
  out LangID: String): Boolean;
var
  pLen: Integer;
begin
  pLen := Length(PropertyValue);
  Result := (pLen >= 3) and (PropertyValue[1] = FStringLeftMark) and
    (PropertyValue[pLen] = FStringRightMark);
  if not Result then
    exit;
  LangID := LowerCase(Copy(PropertyValue, 2, pLen - 2));
end;

function TApplicationLanguage.NodeString(const ID: String; Node: IXMLDOMNode): String;
var
  strNode: IXMLDOMNode;
begin
  Result := '';
  strNode := Node.selectSingleNode
    ('string[translate(@id, "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz")="'
    + ID + '"]');
  if strNode <> nil then
    Result := strNode.text;
end;

procedure TApplicationLanguage.OnLoadLangStrings(Node: IXMLDOMNode);
var
  I: Integer;
  strNode: IXMLDOMNode;
  attrNode: IXMLDOMNode;
  strID, strValue: String;
begin
  FGlobalsList.Clear;
  for I := 0 to Node.childNodes.length - 1 do begin
    strNode := Node.childNodes.item[I];
    attrNode := strNode.attributes.getNamedItem('id');
    if attrNode = nil then
      continue;

    strID := attrNode.text;
    strValue := strNode.text;

    FGlobalsList.Append(strID + FGlobalsList.NameValueSeparator + strValue);
  end;
end;

procedure TApplicationLanguage.SetVTColumnsStrings(VTColumns: TVirtualTreeColumns;
  Node: IXMLDOMNode);
var
  item: TCollectionItem;
  S, SID: String;
begin
  for item in VTColumns do begin
    S := TVirtualTreeColumn(item).Text;
    if not IsPropLangID(S, SID) then
      continue;

    S := NodeString(SID, Node);
    TVirtualTreeColumn(item).Text := S;
  end;
end;

procedure TApplicationLanguage.SetComponentStrings(Comp: TPersistent; Node: IXMLDOMNode;
  const SetChildren: Boolean);
var
  P: Integer;
  PropList: TPropList;
  propName, propVal, propLangId: String;
  propValAsVariant: Variant;
  propType: TTypeKind;
  propObj: TObject;
begin
  if RecursionLevel > MAX_RECURSION_LEVELS then
    exit;
  Inc(RecursionLevel);

  P := 0;
  FillChar(PropList[0], Length(Proplist), 0);
  GetPropList(Comp.ClassInfo, tkProperties, @PropList);

  while (PropList[P] <> nil) and (P < High(PropList)) do begin
    propName := '';
    propVal := '';

    propName := String(PropList[P].Name);
    propType := PropList[P].PropType^.Kind;

    if (GetPropInfo(Comp, propName) = nil) or
      (not(propType in [tkString, tkLString, tkWString, tkUString, tkClass])) then begin
      Inc(P);
      continue;
    end;

    propValAsVariant := GetPropValue(Comp, propName);
    propVal := VarToStr(propValAsVariant);

    if propType = tkClass then begin
      propObj := TObject(GetOrdProp(Comp, PropList[P]));

      if (propObj is TStrings) then
        SetStringListStrings(propObj as TStrings, Node)
      else if (propObj is TListColumns) then
        SetListColumnsStrings(propObj as TListColumns, Node)
      else if (propObj is TVirtualTreeColumns) then
        SetVTColumnsStrings(propObj as TVirtualTreeColumns, Node)
      else if (propObj is TPersistent) then
        SetComponentStrings(propObj as TPersistent, Node);
    end
    else if IsPropLangID(propVal, propLangId) then begin
      propVal := NodeString(propLangId, Node);
      SetStrProp(Comp, propName, propVal);
    end;

    Inc(P);
  end;

  Dec(RecursionLevel);

  if SetChildren and (Comp is TComponent) then begin
    for P := 0 to TComponent(Comp).ComponentCount - 1 do
      SetComponentStrings(TComponent(Comp).Components[P], Node);
  end;
end;

procedure TApplicationLanguage.SetListColumnsStrings(ListColumns: TListColumns;
  Node: IXMLDOMNode);
var
  item: TCollectionItem;
  S, SID: String;
begin
  for item in ListColumns do begin
    S := TListColumn(item).Caption;
    if not IsPropLangID(S, SID) then
      continue;

    S := NodeString(SID, Node);
    TListColumn(item).Caption := S;
  end;
end;

procedure TApplicationLanguage.SetStringListStrings(StringList: TStrings;
  Node: IXMLDOMNode);
var
  I: Integer;
  S, SID: String;
begin
  for I := 0 to StringList.Count - 1 do begin
    S := StringList.Strings[I];
    if not IsPropLangID(S, SID) then
      continue;

    S := NodeString(SID, Node);
    StringList.Strings[I] := S;
  end;
end;

function TApplicationLanguage.Strings(const Name, Default: String): String;
var
  sIdx: Integer;
begin
  sIdx := FGlobalsList.IndexOfName(Name);
  if sIdx >= 0 then
    Result := FGlobalsList.ValueFromIndex[sIdx]
  else
    Result := Default;
end;

{ TLangStorageMetadata }

function TLangStorageMetadata.GetLangStorageName: String;
begin
  Result := 'meta';
end;

procedure TLangStorageMetadata.OnLoadLangStrings(Node: IXMLDOMNode);
var
  auxNode: IXMLDOMNode;
begin
  FLCID := 0;
  auxNode := Node.attributes.getNamedItem('lcid');
  if auxNode <> nil then
    FLCID := StrToIntDef(auxNode.text, 0);

  FVersion := '';
  auxNode := Node.attributes.getNamedItem('version');
  if auxNode <> nil then
    FVersion := auxNode.text;

  FAppVersion := '';
  auxNode := Node.attributes.getNamedItem('appversion');
  if auxNode <> nil then
    FAppVersion := auxNode.text;

  FLanguage := '';
  auxNode := Node.selectSingleNode('language');
  if auxNode <> nil then
    FLanguage := auxNode.text;

  FAuthor := '';
  auxNode := Node.selectSingleNode('author');
  if auxNode <> nil then
    FAuthor := auxNode.text;
end;

end.
