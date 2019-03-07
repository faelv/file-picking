unit Fp.Types.Settings;

interface

uses

  Winapi.msxml,
  System.Classes, System.SysUtils, System.IniFiles,
  Fp.Types.Storage, Fp.Types.Interfaces;

type

   TApplicationSettings = class(TSingletonInterfacedObject, IXmlStorageUser)
      private
         FStorage: TXmlStorage;
         FSettingsList: TStrings;
         FFmtSettings: TFormatSettings;
         FAutoSave: Boolean;
         procedure AppendNameValue(const Name, Value: String); inline;
         procedure DoAutoSave; inline;
      public //IXmlStorageUser
         procedure OnNodeLoad(Node: IXMLDOMNode);
         procedure OnNodeSave(Node: IXMLDOMNode);
         function GetStorageName: String;
      public
         constructor Create;
         destructor Destroy; override;
         
         property Storage: TXmlStorage read FStorage;
         property AutoSave: Boolean read FAutoSave write FAutoSave;
         procedure Clear;
         
         procedure Save(const Name: String; const Value: Boolean); overload;
         procedure Save(const Name: String; const Value: Double); overload;
         procedure Save(const Name: String; const Value: Integer); overload;
         procedure Save(const Name, Value: String); overload;

         function Read(const Name: String; const Default: Boolean = False): Boolean; overload;
         function Read(const Name: String; const Default: Double = 0.0): Double; overload;
         function Read(const Name: String; const Default: Integer = 0): Integer; overload;
         function Read(const Name: String; const Default: String = ''): String; overload;
   end;

implementation

{ TApplicationSettings }

procedure TApplicationSettings.AppendNameValue(const Name, Value: String);
begin
   FSettingsList.Append(Name + FSettingsList.NameValueSeparator + Value);
end;

procedure TApplicationSettings.Clear;
begin
   FSettingsList.Clear;
   Self.DoAutoSave;
end;

constructor TApplicationSettings.Create;
begin
   FFmtSettings := TFormatSettings.Create('en-US');
   FFmtSettings.DecimalSeparator := '.';
   FFmtSettings.ThousandSeparator := ',';

   FSettingsList := THashedStringList.Create;

   FAutoSave := False;

   FStorage := TXmlStorage.Create;
   FStorage.AddUser(Self);
end;

destructor TApplicationSettings.Destroy;
begin
   FSettingsList.Free;
   FStorage.Free;
   inherited;
end;

procedure TApplicationSettings.DoAutoSave;
begin
   if Self.AutoSave then
      Self.Storage.Save;
end;

function TApplicationSettings.GetStorageName: String;
begin
   Result := 'app-settings';
end;

procedure TApplicationSettings.OnNodeLoad(Node: IXMLDOMNode);
var
   I: Integer;
begin
   Self.Clear;
   for I := 0 to Node.attributes.length - 1 do begin
      if LowerCase(Node.attributes.item[I].nodeName) = 'xmlns' then continue;
      Self.AppendNameValue(Node.attributes.item[I].nodeName, String(Node.attributes.item[I].nodeValue));
   end;
end;

procedure TApplicationSettings.OnNodeSave(Node: IXMLDOMNode);
var
   XmlElement: IXMLDOMElement;
   I: Integer;
begin
   XmlElement := IXMLDOMElement(Node);
   for I := 0 to FSettingsList.Count - 1 do begin
      if LowerCase(FSettingsList.Names[I]) = 'xmlns' then continue;
      XmlElement.setAttribute(FSettingsList.Names[I], FSettingsList.ValueFromIndex[I]);
   end;
end;

function TApplicationSettings.Read(const Name: String; const Default: Integer): Integer;
var
   strResult: String;
begin
   strResult := Self.Read(Name, IntToStr(Default));
   Result := StrToInt(strResult);
end;

function TApplicationSettings.Read(const Name, Default: String): String;
var
   sIdx: Integer;
begin
   sIdx := FSettingsList.IndexOfName(Name);
   if sIdx >= 0 then
      Result := FSettingsList.ValueFromIndex[sIdx]
   else
      Result := Default;
end;

function TApplicationSettings.Read(const Name: String; const Default: Boolean): Boolean;
var
   strResult: String;
begin
   strResult := Self.Read(Name, BoolToStr(Default, True));
   Result := StrToBool(strResult);
end;

function TApplicationSettings.Read(const Name: String; const Default: Double): Double;
var
   strResult: String;
begin
   strResult := Self.Read(Name, FloatToStr(Default, FFmtSettings));
   Result := StrToFloat(strResult, FFmtSettings);
end;

procedure TApplicationSettings.Save(const Name: String; const Value: Integer);
begin
   Self.Save(Name, IntToStr(Value));
end;

procedure TApplicationSettings.Save(const Name, Value: String);
var
   sIdx: Integer;
begin
   sIdx := FSettingsList.IndexOfName(Name);
   if sIdx >= 0 then
      FSettingsList.ValueFromIndex[sIdx] := Value
   else
      Self.AppendNameValue(Name, Value);

   Self.DoAutoSave;
end;

procedure TApplicationSettings.Save(const Name: String; const Value: Boolean);
begin
   Self.Save(Name, BoolToStr(Value, True));
end;

procedure TApplicationSettings.Save(const Name: String; const Value: Double);
begin
   Self.Save(Name, FloatToStr(Value, FFmtSettings));
end;

end.
