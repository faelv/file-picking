unit Fp.Types.General;

interface

uses

  Fp.Resources.Definitions,
  Winapi.Windows,
  System.SysUtils, System.Math;

type

  TCmdLineParams = record
    FileName: String;
    ShellOpen: Boolean;
    procedure ReadCommandLine();
  end;

  THighResTimer = class(TObject)
    private
      FPerfFreq, FOverhead, FOverhead_St, FOverhead_Sp, FPerfStart, FPerfStop: Int64;
      FEllapsedTime: Double;
      FStarted: Boolean;
    public
      procedure Start;
      procedure Stop;
      property EllapsedTime: Double read FEllapsedTime;
      property Started: Boolean read FStarted;
  end;

  TTickTimer = class(TObject)
    private
      FStarted: Boolean;
      FStart, FStop: Cardinal;
      FEllapsedTime: Extended;
    public
      procedure Start;
      procedure Stop;
      property EllapsedTime: Extended read FEllapsedTime;
      property Started: Boolean read FStarted;
  end;

implementation

{ TPerformanceCounter }

procedure THighResTimer.Start;
begin
  FEllapsedTime := 0;
  FStarted := True;

  QueryPerformanceFrequency(FPerfFreq);

  QueryPerformanceCounter(FOverhead_St);
  QueryPerformanceCounter(FOverhead_Sp);
  FOverhead := FOverhead_Sp - FOverhead_St;

  QueryPerformanceCounter(FPerfStart);
end;

procedure THighResTimer.Stop;
begin
  QueryPerformanceCounter(FPerfStop);
  FEllapsedTime := ((FPerfStop - FPerfStart - FOverhead) * 1000) / FPerfFreq;
  FStarted := False;
end;

{ TTickTimer }

procedure TTickTimer.Start;
begin
  FEllapsedTime := 0;
  FStarted := True;
  FStart := GetTickCount;
end;

procedure TTickTimer.Stop;
begin
  FStop := GetTickCount;
  FStarted := False;
  FEllapsedTime := Abs((FStop - FStart) / 1000);
end;

{ TCmdLineParams }

procedure TCmdLineParams.ReadCommandLine;
var
  P: Integer;
begin
  Self.FileName := '';
  Self.ShellOpen := False;

  P := 1;
  while P <= ParamCount do begin
     if P = 1 then begin
        Self.FileName := Trim(ParamStr(P));
        Self.ShellOpen := FileExists(Self.FileName);
     end;
     Inc(P);
  end;
end;

end.
