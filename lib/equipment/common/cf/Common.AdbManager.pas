unit Common.AdbManager;

interface

uses System.SysUtils, Common.WinProcessUtils;

type
  TAdbManager = class
  protected const
    ADB = 'adb.exe';
    class procedure ExecAdb(AArgs: array of const; out AOutput: string); overload;
    class procedure ExecAdb(AArgs: array of const); overload;
  public
    class var AdbDirectory: string;
  public
    class function GetDeviceCount(out AOutput: string): Integer; overload;
    class function GetDeviceCount: Integer; overload;
    class procedure ForvardPort(const APort: Word);
  end;

implementation

{ TAdbManager }

class procedure TAdbManager.ExecAdb(AArgs: array of const; out AOutput: string);
var
  LDir: string;
begin
  if not AdbDirectory.IsEmpty then
    LDir := IncludeTrailingPathDelimiter(AdbDirectory)
  else
    LDir := '';
  ExecConsoleApp(LDir + ADB, AArgs, AOutput, ceOEM);
end;

class procedure TAdbManager.ExecAdb(AArgs: array of const);
var
  LOutput: string;
begin
  ExecAdb(AArgs, LOutput);
end;

class procedure TAdbManager.ForvardPort(const APort: Word);
var
  LPort: string;
  LOutput: string;
begin
  LPort := IntToStr(APort);
  ExecAdb(['forward', 'tcp:' + LPort, 'tcp:' + LPort], LOutput);
end;

class function TAdbManager.GetDeviceCount: Integer;
var
  LOutput: string;
begin
  Result := GetDeviceCount(LOutput);
end;

class function TAdbManager.GetDeviceCount(out AOutput: string): Integer;
var
  LOutStrings: TArray<string>;
  I: Integer;
begin
  Result := 0;
  ExecAdb(['devices'], AOutput);
  LOutStrings := AOutput.Split([sLineBreak]);
  for I := Low(LOutStrings) to High(LOutStrings) do
    if (I > Low(LOutStrings)) and (Pos('device', LOutStrings[I]) > 0) then
      Inc(Result);
end;

initialization
  TAdbManager.AdbDirectory := '';

end.
