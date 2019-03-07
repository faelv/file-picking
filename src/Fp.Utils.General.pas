unit Fp.Utils.General;

interface

uses

  Fp.Resources.Definitions, Fp.Resources.Strings,
  Fp.Utils.Dialogs,
  System.SysUtils;

  function SafeFormat(const Format: string; const Args: array of const): String; overload;
  function SafeFormat(
    const Format: string; const Args: array of const;
    const FormatSettings: TFormatSettings
  ): String; overload;

  function FormatByteSize(const Bytes: Int64; FormatSettings: TFormatSettings): string;

  function LoadLocalizedResources(const LangID: Integer): Boolean;

implementation

uses

  Fp.System;

function VarRecToStr(AVarRec: TVarRec): String;
const
  NamedBool: array[Boolean] of String = ('False', 'True');
begin
  case AVarRec.VType of
    vtInteger:    Result := IntToStr(AVarRec.VInteger);
    vtBoolean:    Result := NamedBool[AVarRec.VBoolean];
    vtExtended:   Result := FloatToStr(AVarRec.VExtended^);
    vtCurrency:   Result := CurrToStr(AVarRec.VCurrency^);
    vtObject:     Result := AVarRec.VObject.ClassName;
    vtClass:      Result := AVarRec.VClass.ClassName;
    vtAnsiString: Result := String(AVarRec.VAnsiString);
    vtString:     Result := String(AVarRec.VString^);
    vtPChar:      Result := String(AVarRec.VPChar);
    vtChar:       Result := String(AVarRec.VChar);
    vtVariant:    Result := String(AVarRec.VVariant^);
  else
    Result := #0;
  end;
end;

function SafeFormat(const Format: string; const Args: array of const): String;
var
  I: Integer;
begin
  try
    Result := System.SysUtils.Format(Format, Args);
  except
    Result := Format;
    for I := 0 to Length(Args) - 1 do
      Result := Result + #13#10#149#32 + VarRecToStr(Args[I]);
  end;
end;

function SafeFormat(const Format: string; const Args: array of const;
  const FormatSettings: TFormatSettings): String; overload;
var
  I: Integer;
begin
  try
    Result := System.SysUtils.Format(Format, Args, FormatSettings);
  except
    Result := Format;
    for I := 0 to Length(Args) - 1 do
      Result := Result + #13#10#149 + VarRecToStr(Args[I]);
  end;
end;

function LoadLocalizedResources(const LangID: Integer): Boolean;
begin
  Language.Storage.FileName := APP_PATH + Format(LANG_FILE_TEMPLATE, [LangID]);
  Result := Language.Storage.Load;

  if not Result then begin
    Language.Storage.FileName := APP_PATH +'\' + Format(
      LANG_FILE_TEMPLATE, [LANG_DEFAULT_LOCALE]
    );
    Result := Language.Storage.Load;
  end;
end;

function FormatByteSize(const Bytes: Int64; FormatSettings: TFormatSettings): string;
const
  B = 1; //byte
  KB = 1024 * B; //kilobyte
  MB = 1024 * KB; //megabyte
  GB = 1024 * MB; //gigabyte
begin
  if bytes > GB then
    result := FormatFloat('0.##GB', bytes / GB, FormatSettings)
  else begin
    if bytes > MB then
      result := FormatFloat('0.#MB', bytes / MB, FormatSettings)
    else begin
      if bytes > KB then
        result := FormatFloat('0.#KB', bytes / KB, FormatSettings)
      else
        result := FormatFloat('0B', bytes, FormatSettings);
    end;
  end;
end;

end.
