unit Fp.Types.Storage;

interface

uses

  Winapi.msxml,
  System.Classes, System.Contnrs, System.SysUtils;

const
   DEF_DOC_PROC_INSTRUCTION: WideString = 'version="1.0" encoding="UTF-8"';
   DEF_DOC_ROOT: WideString = 'root';
   DEF_DOC_NAMESPACE: WideString = 'xmlstorage';

   SEL_NODE_TMPL: String = '//%s';

resourcestring

   XML_FILE_NOT_FOUND = 'File "%s" not found.';
   XML_FILE_ERROR = 'Error while loading file "%s", reason: "%s".';
   XML_FILE_INVALID_NS = 'Invalid namespace.';
   XML_FILE_INVALID_FILEN = 'Invalid file name.';

type

  IXMLDOMNode = Winapi.msxml.IXMLDOMNode;
  IXMLDOMElement = Winapi.msxml.IXMLDOMElement;

   IXmlStorageUser = interface ['{E8B3F976-61DD-4C18-9CA3-C4A834D4FCEB}']
      procedure OnNodeLoad(Node: IXMLDOMNode);
      procedure OnNodeSave(Node: IXMLDOMNode);
      function GetStorageName: String;
   end;

   TXmlStorage = class(TObject)
      private
         FFileName: TFileName;
         FErrors: TStrings;
         FDocumentNamespaceURI: WideString;
         FDocumentProcessingInstruction: WideString;
         FDocumentRoot: WideString;
         function GetLoaded: Boolean;
      protected
         FUsersList: TObjectList;
         XMLDocument: IXMLDOMDocument3;
         
         procedure LoadUsers; virtual;
         procedure SaveUsers(ParentNode: IXMLDOMNode); virtual;
      public
         constructor Create; virtual;
         destructor Destroy; override;
         procedure AddUser(Obj: TObject); virtual;
         procedure RemoveUser(Obj: TObject); virtual;
         function Load: Boolean; virtual;
         function Save: Boolean; virtual;
         procedure Reload;
         procedure ReloadSingle(Obj: TObject); virtual;
         procedure Unload;
         property FileName: TFileName read FFileName write FFileName;
         property Errors: TStrings read FErrors;
         property Loaded: Boolean read GetLoaded;
         property DocumentNamespaceURI: WideString read FDocumentNamespaceURI write FDocumentNamespaceURI;
         property DocumentProcessingInstruction: WideString read FDocumentProcessingInstruction write FDocumentProcessingInstruction;
         property DocumentRoot: WideString read FDocumentRoot write FDocumentRoot;

         class function GetNodeAttributeDef(Node: IXMLDOMNode; const Attribute: WideString; const Default: OleVariant): OleVariant;
         class function GetNodeValueDef(Node: IXMLDOMNode; const Name: WideString; const Default: OleVariant): OleVariant;
         class function CreateCDATAChild(Node: IXMLDOMNode; const Name, Data: WideString): IXMLDOMElement;
   end;

implementation

{ TXmlStorage }

constructor TXmlStorage.Create;
begin
   FUsersList := TObjectList.Create;
   FUsersList.OwnsObjects := False;

   FErrors := TStringList.Create;

   Self.DocumentNamespaceURI := DEF_DOC_NAMESPACE;
   Self.DocumentProcessingInstruction := DEF_DOC_PROC_INSTRUCTION;
   Self.DocumentRoot := DEF_DOC_ROOT;
end;

class function TXmlStorage.CreateCDATAChild(Node: IXMLDOMNode; const Name,
  Data: WideString): IXMLDOMElement;
var
  childNode: IXMLDOMElement;
  cdataNode: IXMLDOMCDATASection;
begin
  childNode := Node.ownerDocument.createElement(Name);
  cdataNode := Node.ownerDocument.createCDATASection(Data);
  childNode.appendChild(cdataNode);
  Node.appendChild(childNode);
  Result := childNode;
end;

destructor TXmlStorage.Destroy;
begin
   FUsersList.Free;
   FErrors.Free;

   inherited;
end;

function TXmlStorage.GetLoaded: Boolean;
begin
   Result := (XMLDocument <> nil);
end;

class function TXmlStorage.GetNodeAttributeDef(Node: IXMLDOMNode;
  const Attribute: WideString; const Default: OleVariant): OleVariant;
var
  attr: IXMLDOMNode;
begin
  attr := Node.attributes.getNamedItem(Attribute);
  if attr <> nil then
    Result := attr.nodeValue
  else
    Result := Default;
end;

class function TXmlStorage.GetNodeValueDef(Node: IXMLDOMNode; const Name: WideString;
  const Default: OleVariant): OleVariant;
var
  child: IXMLDOMNode;
begin
  child := Node.selectSingleNode(Name);
  if child <> nil then
    Result := child.text
  else
    Result := Default;
end;

procedure TXmlStorage.AddUser(Obj: TObject);
begin
   FUsersList.Add(Obj);
end;

procedure TXmlStorage.Reload;
begin
   Self.LoadUsers;
end;

procedure TXmlStorage.ReloadSingle(Obj: TObject);
var
   storageName: WideString;
   curIntf: IXmlStorageUser;
   curNode: IXMLDOMNode;
begin
   if not Self.Loaded then exit;
   
   if Supports(Obj, IXmlStorageUser, curIntf) then begin
      storageName := curIntf.GetStorageName;

      storageName := Format(SEL_NODE_TMPL, [String(storageName)]);
      curNode := XMLDocument.documentElement.selectSingleNode(storageName);
      if curNode <> nil then
         curIntf.OnNodeLoad(curNode);
   end;
end;

procedure TXmlStorage.RemoveUser(Obj: TObject);
begin
   FUsersList.Remove(Obj);
end;

procedure TXmlStorage.LoadUsers;
var
   curPtr: Pointer;
   curObj: TObject;
begin
   if not Self.Loaded then exit;
   
   for curPtr in FUsersList do begin
      if curPtr = nil then continue;

      curObj := TObject(curPtr);
      Self.ReloadSingle(curObj);
   end;
end;

function TXmlStorage.Load: Boolean;
var
   oleFileName: OleVariant;
begin
   Result := False;

   FErrors.Clear;
   if Self.Loaded then Self.Unload;

   if not FileExists(Self.FileName) then begin
      FErrors.Append(Format(XML_FILE_NOT_FOUND, [Self.FileName]));
      exit;
   end;

   oleFileName := Self.FileName;
   XMLDocument := CoDOMDocument60.Create;
   XMLDocument.async := False;
   XMLDocument.setProperty('SelectionLanguage', 'XPath');
   XMLDocument.load(oleFileName);

   if XMLDocument.parseError.errorCode <> 0 then begin
      FErrors.Append(Format(XML_FILE_ERROR, [Self.FileName, XMLDocument.parseError.reason]));
      Self.UnLoad;
      exit;
   end;

   try
      if (XMLDocument.documentElement.namespaceURI <> Self.DocumentNamespaceURI) then begin
         FErrors.Append(Format(XML_FILE_ERROR, [Self.FileName, XML_FILE_INVALID_NS]));
         Self.UnLoad;
         exit;
      end;

      Self.LoadUsers;

      Result := True;
   except
      on E: Exception do begin
         FErrors.Append(Format(XML_FILE_ERROR, [Self.FileName, E.Message]));
         Self.UnLoad;
      end;
   end;
end;

procedure TXmlStorage.UnLoad;
begin
   XMLDocument := nil;
end;

procedure TXmlStorage.SaveUsers(ParentNode: IXMLDOMNode);
var
   storageName: WideString;
   curPtr: Pointer;
   curObj: TObject;
   curIntf: IXmlStorageUser;
   curNode: IXMLDOMNode;
begin
   for curPtr in FUsersList do begin
      if curPtr = nil then continue;
      
      curObj := TObject(curPtr);
      if Supports(curObj, IXmlStorageUser, curIntf) then begin
         storageName := curIntf.GetStorageName;

         if (ParentNode.selectSingleNode(storageName) <> nil) then continue;
          
         curNode := XMLDocument.createElement(storageName);
         curIntf.OnNodeSave(curNode);

         ParentNode.appendChild(curNode);
      end;
   end;
end;

function TXmlStorage.Save: Boolean;
var
   oleFileName: OleVariant;
   rootNode: IXMLDOMNode;
begin
   Result := False;
   FErrors.Clear;

   if Trim(Self.FileName) = '' then begin
      FErrors.Append(Format(XML_FILE_ERROR, [Self.FileName, XML_FILE_INVALID_FILEN]));
      Self.UnLoad;
      exit;
   end;

   oleFileName := Self.FileName;
   XMLDocument := CoDOMDocument60.Create;
   XMLDocument.async := False;
   XMLDocument.setProperty('SelectionLanguage', 'XPath');
   
   try
      XMLDocument.appendChild(
         XMLDocument.createProcessingInstruction('xml', Self.DocumentProcessingInstruction)
      );
      
      rootNode := XMLDocument.createNode(1, Self.DocumentRoot, Self.DocumentNamespaceURI);
      
      Self.SaveUsers(rootNode);

      XMLDocument.appendChild(rootNode);
      XMLDocument.save(oleFileName);

      Result := True;
   except
      on E: Exception do begin
         FErrors.Append(Format(XML_FILE_ERROR, [Self.FileName, E.Message]));
         Self.UnLoad;
      end;
   end;
end;

end.
