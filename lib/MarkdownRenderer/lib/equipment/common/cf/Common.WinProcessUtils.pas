unit Common.WinProcessUtils;

interface

uses Winapi.Windows, System.SysUtils;

type
  TConsoleEncoding = (ceOEM, ceUTF8);

resourcestring
  RsErrorReadPipe = 'Неизвестная ошибка при чтении вывода консоли';
  RsErrorUnknown = 'Неизвестная ошибка при выполнении команды';

function ExecConsoleApp(const AApplication: string; AArgs: array of const;
  out AOutput: string; AEncoding: TConsoleEncoding): DWORD; overload;
function ExecConsoleApp(const AApplication: string; AArgs: array of const)
  : DWORD; overload;
function ExecConsoleApp(const AApplication: string; AArgs: array of const;
  AEncoding: TConsoleEncoding): DWORD; overload;
function KillProcess(const AProcessName: string): Boolean;

implementation

uses Winapi.TlHelp32, Winapi.ShlObj, System.IOUtils;

function ExecConsoleApp(const AApplication: string; AArgs: array of const;
  AUseOutput: Boolean; out AOutput: string; AEncoding: TConsoleEncoding)
  : DWORD; overload;
const
  StdOutSize: DWORD = 8192; // С запасом, иначе приложение заблокируется
var
  LSecurityAttr: TSecurityAttributes;
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
  LStdOutRd, LStdOutWr, LStdInRd, LStdInWr, LStdErrRd, LStdErrWr: THandle;
  LExitCode: DWORD;
  LErrorDescription: string;
  LCommandLie: WideString;

  function ReadOut(APipe: THandle): string;
  var
    LRead: DWORD;
    LBuf: TBytes;
    LTotalBytesAvail: DWORD;
  begin
    Result := '';
    // check if there is something to read in pipe
    PeekNamedPipe(APipe, nil, 0, nil, @LTotalBytesAvail, nil);
    if LTotalBytesAvail = 0 then
      Exit;

    SetLength(LBuf, LTotalBytesAvail + 1);
    FillChar(LBuf[0], Length(LBuf), #0);
    if not ReadFile(APipe, LBuf[0], LTotalBytesAvail, LRead, nil) then
      RaiseLastOSError;
    if LRead = 0 then
      raise Exception.Create(RsErrorReadPipe);

    LBuf[High(LBuf)] := 0;
    case AEncoding of
      ceOEM:
        begin
          OemToAnsi(LPCSTR(LBuf), LPCSTR(LBuf));
          Result := TEncoding.ANSI.GetString(LBuf);
        end;
      ceUTF8:
        Result := TEncoding.UTF8.GetString(LBuf);
    end;
  end;

  procedure PipeCreate(var hReadPipe, hWritePipe: THandle; nSize: DWORD = 0);
  begin
    if not CreatePipe(hReadPipe, hWritePipe, @LSecurityAttr, nSize) then
      RaiseLastOSError;
    if not SetHandleInformation(hReadPipe, HANDLE_FLAG_INHERIT, 0) then
      RaiseLastOSError;
  end;

begin
  Result := 0;
  AOutput := '';

  LSecurityAttr.nLength := SizeOf(SECURITY_ATTRIBUTES);
  LSecurityAttr.bInheritHandle := True;
  LSecurityAttr.lpSecurityDescriptor := nil;

  if AUseOutput then
  begin
    // Create a pipe for the process's STDOUT.
    PipeCreate(LStdOutRd, LStdOutWr, StdOutSize);
    // Create a pipe for the process's STDIN.
    PipeCreate(LStdInRd, LStdInWr);
  end;
  // Create a pipe for the process's STDERR.
  PipeCreate(LStdErrRd, LStdErrWr);

  try
    FillChar(LStartupInfo, SizeOf(TStartupInfo), 0);
    with LStartupInfo do
    begin
      cb := SizeOf(TStartupInfo);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      if AUseOutput then
      begin
        hStdOutput := LStdOutWr;
        hStdInput := LStdInRd;
      end;
      hStdError := LStdErrWr;
    end;

    LCommandLie := (AApplication + ' ' + string.Join(' ', AArgs));
    // UniqueString(LCommandLie);
    if CreateProcess(nil, LPWSTR(LCommandLie), nil, nil, True, 0, nil, nil,
      LStartupInfo, LProcessInfo) then
      with LProcessInfo do
      begin
        try
          Result := dwProcessId;
          // ждем завершения инициализации
          WaitForInputIdle(hProcess, { 3000 } INFINITE);
          // ждем завершения процесса
          WaitForSingleObject(hProcess, INFINITE);
          if AUseOutput then
            AOutput := ReadOut(LStdOutRd); // Читаем выходные данные
          // получаем код завершения
          if not GetExitCodeProcess(hProcess, LExitCode) then
            RaiseLastOSError;
          if LExitCode <> 0 then
          begin
            LErrorDescription := ReadOut(LStdErrRd);
            if AUseOutput then
            begin
              if LErrorDescription.IsEmpty then
                LErrorDescription := AOutput;
            end;
            if (LErrorDescription.IsEmpty) then
              LErrorDescription := RsErrorUnknown + ' (' +
                IntToStr(LExitCode) + ')';
            raise Exception.Create(LErrorDescription);
          end;
        finally
          CloseHandle(hThread); // закрываем дескриптор процесса
          CloseHandle(hProcess); // закрываем дескриптор потока
        end;
      end
    else
      RaiseLastOSError;
  finally
    if AUseOutput then
    begin
      CloseHandle(LStdOutRd);
      CloseHandle(LStdInRd);
    end;
    CloseHandle(LStdErrRd);
  end;
end;

function ExecConsoleApp(const AApplication: string; AArgs: array of const;
  out AOutput: string; AEncoding: TConsoleEncoding): DWORD; overload;
begin
  Result := ExecConsoleApp(AApplication, AArgs, True, AOutput, AEncoding);
end;

function ExecConsoleApp(const AApplication: string; AArgs: array of const)
  : DWORD; overload;
var
  LOutput: string;
begin
  Result := ExecConsoleApp(AApplication, AArgs, False, LOutput, ceOEM)
end;

function ExecConsoleApp(const AApplication: string; AArgs: array of const;
  AEncoding: TConsoleEncoding): DWORD; overload;
var
  LOutput: string;
begin
  Result := ExecConsoleApp(AApplication, AArgs, False, LOutput, AEncoding)
end;

function GetProcessID(const AProcessName: string): DWORD;
var
  lSnapHandle: THandle;
  lProcStruct: PROCESSENTRY32;
  lProcessName, lSnapProcessName: string;
  lOSVerInfo: TOSVersionInfo;
begin
  Result := INVALID_HANDLE_VALUE;
  lSnapHandle := CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
  if lSnapHandle = INVALID_HANDLE_VALUE then
    Exit;
  lProcStruct.dwSize := SizeOf(PROCESSENTRY32);
  lOSVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  GetVersionEx(lOSVerInfo);
  case lOSVerInfo.dwPlatformId of
    VER_PLATFORM_WIN32_WINDOWS:
      lProcessName := AProcessName;
    VER_PLATFORM_WIN32_NT:
      lProcessName := ExtractFileName(AProcessName);
  end;
  if Process32First(lSnapHandle, lProcStruct) then
  begin
    try
      repeat
        lSnapProcessName := lProcStruct.szExeFile;
        if AnsiUpperCase(lSnapProcessName) = AnsiUpperCase(lProcessName) then
        begin
          Result := lProcStruct.th32ProcessID;
          Break;
        end;
      until not Process32Next(lSnapHandle, lProcStruct);
    finally
      CloseHandle(lSnapHandle);
    end;
  end;
end;

function KillProcess(const AProcessName: string): Boolean;
var
  lPID, lCurrentProcPID: DWORD;
  lProcHandle: DWORD;
begin
  Result := False;
  try
    lCurrentProcPID := GetCurrentProcessId;
    lPID := GetProcessID(AProcessName);
    if (lPID <> INVALID_HANDLE_VALUE) and (lCurrentProcPID <> lPID) then
    begin
      lProcHandle := OpenProcess(PROCESS_TERMINATE, False, lPID);
      Winapi.Windows.TerminateProcess(lProcHandle, 0);
      WaitForSingleObject(lProcHandle, INFINITE);
      CloseHandle(lProcHandle);
      Result := True;
    end;
  except
    RaiseLastOSError;
  end;
end;

end.
