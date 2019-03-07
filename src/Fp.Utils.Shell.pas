unit Fp.Utils.Shell;

interface

uses

  Winapi.Windows, Winapi.ShlObj, Winapi.ShellApi;

{ Globals }

  procedure OpenURL(const URL: String);
  function GetKnownFolder(csidl: Integer; ForceFolder: Boolean = False): String;
  function BrowseForFolder(const DialogCaption: String; var FolderName: String;
    const Owner: HWND): Boolean;

implementation

procedure OpenURL(const URL: String);
begin
  ShellExecute(0, PChar('open'), PChar(URL), nil, nil, SW_SHOW);
end;

function GetKnownFolder(csidl: Integer; ForceFolder: Boolean): String;
var
    I: Integer;
begin
    SetLength(Result, MAX_PATH);
    if ForceFolder then
        SHGetFolderPath(0, csidl or CSIDL_FLAG_CREATE, 0, 0, PChar(Result))
    else
        SHGetFolderPath(0, csidl, 0, 0, PChar(Result));
    I := Pos(#0, Result);
    if I > 0 then
        SetLength(Result, Pred(I));
end;

function BrowseForFolder(const DialogCaption: String; var FolderName: String;
  const Owner: HWND): Boolean;
var
  IDList: PItemIDList;
  Buffer: String;
  Title: String;
  BrowseInfo: TBrowseInfo;
begin
  Result := False;
  Title := DialogCaption;

  ZeroMemory(@BrowseInfo, SizeOf(BrowseInfo));
  BrowseInfo.hWndOwner := Owner;
  BrowseInfo.lpszTitle := @Title[1];
  BrowseInfo.ulFlags := BIF_RETURNONLYFSDIRS + BIF_DONTGOBELOWDOMAIN + BIF_NEWDIALOGSTYLE;

  IDList := SHBrowseForFolder(BrowseInfo);

  if (IDList <> nil) then begin
    SetLength(Buffer, MAX_PATH);
    if SHGetPathFromIDList(IDList, @Buffer[1]) then begin
      FolderName := Copy(Buffer, 1, Pos(#0, Buffer) - 1);
      Result := True;
    end;
  end;
end;

end.
