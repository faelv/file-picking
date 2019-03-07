unit Fp.Utils.Versioning;

interface

uses

   Windows, SysUtils;

{Globals}

   function GetExeVersion(const FileName: String): String;

implementation

function GetExeVersion(const FileName: String): String;
var
    VerInfoSize: DWORD;
    VerInfo: Pointer;
    VerValueSize: DWORD;
    VerValue: PVSFixedFileInfo;
    Dummy: DWORD;
begin
    VerInfoSize := GetFileVersionInfoSize(PChar(FileName), Dummy);
    GetMem(VerInfo, VerInfoSize);
    GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo);
    VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
    with VerValue^ do begin
        Result := IntToStr(dwFileVersionMS shr 16);
        Result := Result + '.' + IntToStr(dwFileVersionMS and $FFFF);
        Result := Result + '.' + IntToStr(dwFileVersionLS shr 16);
        Result := Result + '.' + IntToStr(dwFileVersionLS and $FFFF);
    end;
    FreeMem(VerInfo, VerInfoSize);
end;

end.
