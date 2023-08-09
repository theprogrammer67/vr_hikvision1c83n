unit Common.Log;

interface

uses System.IOUtils, System.SyncObjs;

{$IFDEF DEBUG}
{$DEFINE Log}
{$ENDIF}

type
  TWinVersion = (wvUnknown, wv95, wv98, wvME, wvNT3, wvNT4, wvW2K, wvXP, wv2003,
    wvVista, wv70, wv80, wv81, wv10);

  TVersionInfo = record
    MajorVersion: WORD;
    MinorVersion: WORD;
    ProductRelease: WORD;
    ProductBuild: WORD;
  end;

  TLog = class
  public type
    TMsgType = (mtInfo, mtDebug, mtError);
    TLevel = (llNone, llError, llCommon, llDebug);
    TOnLogAppend = procedure(const ACaption, AMessage: string;
      AMsgType: TMsgType) of object;
  public const
    MSG_INFO = 'INFO';
    MSG_DEBUG = 'DEBUG';
    MSG_ERROR = 'ERROR';
  private
    class var FCriticalSection: TCriticalSection;
    class var FFileName: string;
    class var FDirectory: string;
    class var FStarted: Boolean;
    class var FOnAppend: TOnLogAppend;
    class var FOnBeforeAppend: TOnLogAppend;
    class var FLevel: TLevel;
  private
    class procedure SetLevel(ALevel: TLevel); static;
    class procedure InternalAppend(const AString: string); static;
  public
    class function GetAbsolutePath(AOnlyDirectory: Boolean = False)
      : string; static;
    class function FormatLogString(const ACaption, AMessage: string;
      AMsgType: TMsgType): string; static;
    class procedure Start; static;
    class procedure Stop; static;
    class procedure Append(const ACaption, AMessage: string;
      AMsgType: TMsgType); virtual;
    class procedure WriteTextFile(const AFileName, AText: string); static;
  public
    class property FileName: string read FFileName write FFileName;
    class property Directory: string read FDirectory write FDirectory;
    class property Started: Boolean read FStarted write FStarted;
    class property OnAppend: TOnLogAppend read FOnAppend write FOnAppend;
    class property OnBeforeAppend: TOnLogAppend read FOnBeforeAppend
      write FOnBeforeAppend;
    class property Level: TLevel read FLevel write SetLevel;
  end;

implementation

uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.ShlObj,
  Common.BaseSecurity;

function LongPathName(const ShortPathName: string): string;
var
  Buffer: array [0 .. MAX_PATH - 1] of Char;
begin
  FillChar(Buffer, MAX_PATH, #0);
  GetLongPathName(PChar(ShortPathName), Buffer, Length(Buffer));
  Result := Buffer;
end;

function GetModuleFileNameStr: string;
var
  Buffer: array [0 .. MAX_PATH - 1] of Char;
begin
  FillChar(Buffer, MAX_PATH, #0);
  GetModuleFileName(hInstance, Buffer, MAX_PATH);
  Result := LongPathName(Buffer);
end;

function GetModuleDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFileDir(GetModuleFileNameStr));
end;

function GetSpecialPath(CSIDL: WORD): string;
var
  S: string;
begin
  SetLength(S, MAX_PATH);
  if not SHGetSpecialFolderPath(0, PChar(S), CSIDL, True) then
    S := GetSpecialPath(CSIDL_COMMON_APPDATA);
  Result := IncludeTrailingPathDelimiter(PChar(S));
end;

function GetAppDataPath: string;
begin
  Result := GetSpecialPath(CSIDL_COMMON_APPDATA);
end;

function GetFileVer(const FileName: string = ''): TVersionInfo;
var
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
  FName: string;
begin
  Result.MajorVersion := 0;
  Result.MinorVersion := 0;
  Result.ProductRelease := 0;
  Result.ProductBuild := 0;
  FName := GetModuleFileNameStr;

  VerInfoSize := GetFileVersionInfoSize(PChar(FName), Dummy);
  if VerInfoSize = 0 then
    Exit;
  GetMem(VerInfo, VerInfoSize);
  try
    Winapi.Windows.GetFileVersionInfo(PChar(FName), 0, VerInfoSize, VerInfo);
    if VerInfo = nil then
      Exit;
    VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
    with VerValue^ do
    begin
      Result.MajorVersion := dwFileVersionMS shr 16;
      Result.MinorVersion := dwFileVersionMS and $FFFF;
      Result.ProductRelease := dwFileVersionLS shr 16;
      Result.ProductBuild := dwFileVersionLS and $FFFF;
    end;
  finally
    FreeMem(VerInfo, VerInfoSize);
  end;
end;

function DetectWinVersion(out AddVerInfo: string): TWinVersion;
var
  OSVersionInfo: TOSVersionInfo;
  strCSDVersion: string;
begin
  Result := wvUnknown; // Неизвестная версия ОС
  AddVerInfo := '';

  OSVersionInfo.dwOSVersionInfoSize := sizeof(TOSVersionInfo);
  if GetVersionEx(OSVersionInfo) then
  begin
    case OSVersionInfo.DwMajorVersion of
      3:
        Result := wvNT3; // Windows NT 3
      4:
        case OSVersionInfo.DwMinorVersion of
          0:
            if OSVersionInfo.dwPlatformId = VER_PLATFORM_WIN32_NT then
              Result := wvNT4 // Windows NT 4
            else
              Result := wv95; // Windows 95
          10:
            Result := wv98; // Windows 98
          90:
            Result := wvME; // Windows ME
        end;
      5:
        case OSVersionInfo.DwMinorVersion of
          0:
            Result := wvW2K; // Windows 2000
          1:
            Result := wvXP; // Windows XP
          2:
            Result := wv2003; // Windows 2003
        end;
      6:
        case OSVersionInfo.DwMinorVersion of
          0:
            Result := wvVista; // Windows Vista
          1:
            Result := wv70; // Windows 7
          2:
            Result := wv80; // Windows 8.0
          3:
            Result := wv81; // Windows 8.1
        end;
      10:
        case OSVersionInfo.DwMinorVersion of
          0:
            Result := wv10; // Windows 10
        end;
    end;

    strCSDVersion := OSVersionInfo.szCSDVersion;
    if Length(strCSDVersion) > 0 then
      AddVerInfo := strCSDVersion + ' ';

    AddVerInfo := AddVerInfo + '(' + Format('%d.%d.%d',
      [OSVersionInfo.DwMajorVersion, OSVersionInfo.DwMinorVersion,
      OSVersionInfo.dwBuildNumber]) + ')';
  end;
end;

function DetectWinVersionStr: string;
const
  VersStr: array [TWinVersion] of string = ('Unknown', 'Windows 95',
    'Windows 98', 'Windows ME', 'Windows NT 3', 'Windows NT 4', 'Windows 2000',
    'Windows XP', 'Windows 2003', 'Windows Vista', 'Windows 7', 'Windows 8.0',
    'Windows 8.1', 'Windows 10');
var
  AddVerInfo: string;
begin
  Result := VersStr[DetectWinVersion(AddVerInfo)];
  Result := Result + ' ' + AddVerInfo;
end;

{ TLog }

class procedure TLog.InternalAppend(const AString: string);
var
  LStream: TFileStream;
  LBuf: TBytes;
  LFilePath: string;
begin
  LFilePath := GetAbsolutePath;
  LBuf := TEncoding.UTF8.GetBytes(AString + sLineBreak);

  FCriticalSection.Enter;
  try
    if TFile.Exists(LFilePath) then
      LStream := TFileStream.Create(LFilePath, fmShareDenyWrite or
        fmOpenReadWrite)
    else
      LStream := TFileStream.Create(LFilePath, fmShareDenyWrite or fmCreate);

    try
      LStream.Position := LStream.Size;
      LStream.Write(LBuf, Length(LBuf));
    finally
      FreeAndNil(LStream);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

class procedure TLog.SetLevel(ALevel: TLevel);
var
  LOldLevel: TLevel;
begin
  LOldLevel := FLevel;
  FLevel := ALevel;

  if (LOldLevel <> llNone) and (ALevel = llNone) then
  begin
    Stop;
    TLog.FStarted := False;
  end;
end;

class procedure TLog.Start;
var
  LVerInfo: TVersionInfo;
  LVersion: string;
begin
  if (FLevel = llNone) or FStarted then
    Exit;

  LVerInfo := GetFileVer;
  LVersion := Format('%d.%d.%d.%d', [LVerInfo.MajorVersion,
    LVerInfo.MinorVersion, LVerInfo.ProductRelease, LVerInfo.ProductBuild]);

  InternalAppend('                                        ');
  InternalAppend('============Start log=============');
  InternalAppend('OS version:'#9 + DetectWinVersionStr);
  InternalAppend('Application:'#9 + ExtractFileName(GetModuleFileNameStr));
  InternalAppend('App. version:'#9 + LVersion);
  InternalAppend('                                        ');

  FStarted := True;
end;

class procedure TLog.Stop;
begin
  if (FLevel = llNone) or not(FStarted) then
    Exit;

  InternalAppend('============Stop log===============' + sLineBreak);
end;

class function TLog.FormatLogString(const ACaption, AMessage: string;
  AMsgType: TMsgType): string;
begin
  Result := FormatDateTime('yyyy.mm.dd hh:nn:ss.zzz', Now);

  case AMsgType of
    mtInfo:
      Result := Result + #9 + MSG_INFO;
    mtDebug:
      Result := Result + #9 + MSG_DEBUG;
    mtError:
      Result := Result + #9 + MSG_ERROR;
  end;

  Result := Result + #9 + Trim(ACaption);
  if not AMessage.IsEmpty then
    Result := Result + ': '#9 + Trim(AMessage);
end;

class function TLog.GetAbsolutePath(AOnlyDirectory: Boolean = False): string;
var
  LName, LDirectory: string;
begin
  if FFileName.IsEmpty then
    LName := TPath.GetFileNameWithoutExtension(GetModuleFileNameStr)
  else
  begin
    if TPath.IsPathRooted(FFileName) then
      Exit(FFileName) // Указан полный путь к файлу, ничего не делаем
    else
      LName := System.IOUtils.TPath.GetFileNameWithoutExtension(FFileName);
  end;

  if FDirectory.IsEmpty then
    LDirectory := GetAppDataPath + LName
  else
  begin
    if TPath.IsPathRooted(FDirectory) then
      LDirectory := FDirectory // Указан полный путь к папке
    else
      LDirectory := GetAppDataPath + FDirectory;
  end;

  LDirectory := IncludeTrailingPathDelimiter(LDirectory);
  if not TDirectory.Exists(LDirectory) then
  begin
    TDirectory.CreateDirectory(LDirectory);
    SetFullAccess(LDirectory);
  end;

  if not AOnlyDirectory then
    Result := Format('%s%s_%s.log', [LDirectory, LName,
      FormatDateTime('yyyy.mm.dd', Now)])
  else
    Result := LDirectory;
end;

class procedure TLog.WriteTextFile(const AFileName, AText: string);
var
  LStream: TStringStream;
begin
  if FLevel = llNone then
    Exit;

  LStream := TStringStream.Create(AText, TEncoding.UTF8);
  try
    LStream.SaveToFile(GetAbsolutePath(True) + AFileName);
  finally
    LStream.Free;
  end;
end;

class procedure TLog.Append(const ACaption, AMessage: string;
  AMsgType: TMsgType);
begin
  if Assigned(FOnBeforeAppend) then
    FOnBeforeAppend(ACaption, AMessage, AMsgType);

  try
    case FLevel of
      llError:
        if AMsgType <> mtError then
          Exit;
      llCommon:
        if not(AMsgType in [mtError, mtInfo]) then
          Exit;
      llDebug:
        ; // Пишем всё
    else
      Exit; // llNone
    end;
  finally
    if Assigned(FOnAppend) then
      FOnAppend(ACaption, AMessage, AMsgType);
  end;

  TLog.Start;

  InternalAppend(FormatLogString(ACaption, AMessage, AMsgType));
end;

initialization

TLog.FCriticalSection := TCriticalSection.Create;

{$IFDEF DEBUG}
TLog.FLevel := llDebug;
{$ELSE}
{$IFDEF Log}
TLog.Level := llCommon;
{$ELSE}
TLog.Level := llNone;
{$ENDIF}
{$ENDIF}

finalization

TLog.Stop;
FreeAndNil(TLog.FCriticalSection);

end.
