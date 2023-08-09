unit Common.PipeMessaging;

interface

{$IF CompilerVersion >= 24.0 }
{$LEGACYIFEND ON}
{$IFEND}

{$WARN SYMBOL_PLATFORM OFF}

uses
{$IF CompilerVersion >= 28.0} System.Threading, {$IFEND} Winapi.Windows,
  System.Classes, System.SysUtils, System.Generics.Collections, System.SyncObjs;

const
  DEF_PIPE_BUF_SIZE = 32768;
  CMD_CHECKCONNECTION = 'CheckConnection';

type
  PACE_HEADER = ^ACE_HEADER;
{$EXTERNALSYM PACE_HEADER}

  _ACE_HEADER = record
    AceType: Byte;
    AceFlags: Byte;
    AceSize: Word;
  end;
{$EXTERNALSYM _ACE_HEADER}

  ACE_HEADER = _ACE_HEADER;
{$EXTERNALSYM ACE_HEADER}
  TAceHeader = ACE_HEADER;
  PAceHeader = PACE_HEADER;

  PACCESS_ALLOWED_ACE = ^ACCESS_ALLOWED_ACE;
{$EXTERNALSYM PACCESS_ALLOWED_ACE}

  _ACCESS_ALLOWED_ACE = record
    Header: ACE_HEADER;
    Mask: ACCESS_MASK;
    SidStart: DWORD;
  end;
{$EXTERNALSYM _ACCESS_ALLOWED_ACE}

  ACCESS_ALLOWED_ACE = _ACCESS_ALLOWED_ACE;
{$EXTERNALSYM ACCESS_ALLOWED_ACE}
  TAccessAllowedAce = ACCESS_ALLOWED_ACE;
  PAccessAllowedAce = PACCESS_ALLOWED_ACE;

type
  EPipeError = class(Exception);

  TReceiveMessageProc = procedure(const AMessage: string; out AReply: string)
    of object;

  TPipeMsgCustom = class
  protected
    FPipe: THandle;
    FPipeName: string;
  public
    procedure WriteMessage(const AMessage: string);
    function ReadMessage(out AMessage: string): Boolean;
  public
    constructor Create(const APipeName: string); virtual;
  end;

  TPipeMsgClient = class(TPipeMsgCustom)
  private const
    DEF_REPLYTIMEOUT = 5200;
    DEF_CONNECTTIMEOUT = 5150;
  private
    FReplyTimeout: Cardinal;
    FConnectTimeout: Cardinal;
    FCS: TCriticalSection;
  private
    procedure WaitForReply(out AMessage: string);
  public
    constructor Create(const APipeName: string); override;
    destructor Destroy; override;
  public
    procedure Connect;
    procedure Disconnect;
    procedure SendMessage(const AMessage: string; out AReply: string); overload;
    procedure SendMessage(const AMessage: string); overload;
    procedure CheckConnection;
  public
    property ReplyTimeout: Cardinal read FReplyTimeout write FReplyTimeout;
    property ConnectTimeout: Cardinal read FConnectTimeout
      write FConnectTimeout;
  end;

{$IF CompilerVersion >= 28.0}

  TPipeMsgMonitor = class(TPipeMsgClient)
  private const
    DEF_READTIMEOUT = 50;
    DEF_MAXLINES = 200;
  private
    FEnabled: Boolean;
    FListenerTask: ITask;
    FLines: TStrings;
    FOnAppendMsg: TGetStrProc;
    FReadTimeout: Cardinal;
    FMaxLines: Integer;
  private
    procedure AppendMsg(const AMsg: string);
    procedure AppendMsgUIThread(const AMsg: string);
    procedure ListenerPolling;
  public
    constructor Create(const APipeName: string); overload; override;
    constructor Create(const APipeName: string; ALines: TStrings);
      reintroduce; overload;
    constructor Create(const APipeName: string; AOnAppendMsg: TGetStrProc);
      reintroduce; overload;
    constructor Create(const APipeName: string; ALines: TStrings;
      AOnAppendMsg: TGetStrProc); reintroduce; overload;
    destructor Destroy; override;
  public
    procedure Enable;
    procedure Disable;
  public
    property Enabled: Boolean read FEnabled;
    property Lines: TStrings read FLines write FLines;
    property OnAppendMsg: TGetStrProc read FOnAppendMsg write FOnAppendMsg;
    property MaxLines: Integer read FMaxLines write FMaxLines;
    property ReadTimeout: Cardinal read FReadTimeout write FReadTimeout;
  end;

  TPipeMsgSvrInstanse = class(TPipeMsgCustom)
  private const
    MAX_INSTANCES = 100;
    DEF_POLLTIMEOUT = 200;
  private
    FEnabled: Boolean;
    FOnReceiveMessage: TReceiveMessageProc;
    FOnError: TGetStrProc;
    FPollingTask: ITask;
    FConnected: Boolean;
  private
    procedure CreatePipe;
    procedure DestroyPipe;
    function WaitConnection: Boolean;
    procedure Polling;
    procedure ProcessMessage(const AMessage: string);
  public
    constructor Create(const APipeName: string;
      AOnReceiveMessage: TReceiveMessageProc); reintroduce;
    destructor Destroy; override;
  public
    procedure Enable;
    procedure Disable;
  public
    property Connected: Boolean read FConnected;
  end;

  TPipeMsgServer = class
  private
    FInstanses: TObjectList<TPipeMsgSvrInstanse>;
    FInstansesCount: Cardinal;
  public
    constructor Create(const APipeName: string;
      AOnReceiveMessage: TReceiveMessageProc; AInstansesCount: Cardinal = 1);
    destructor Destroy; override;
  public
    procedure Enable;
    procedure Disable;
  public
    procedure WriteMessage(const AMessage: string);
  public
    property InstansesCount: Cardinal read FInstansesCount;
  end;
{$IFEND}

implementation

resourcestring
  RsConnectedSuccsessful = 'Подключение к серверу выполнено успешно';

resourcestring
  RsErrConnect = 'Не удалось подключиться к серверу. Превшен таймаут ожидания';
  RsErrResponse = 'Сервер не отвечает. Превшен таймаут ожидания';
  RsErrWriteData = 'Не удалось передать данные полностью';

  { TPipeCtrlModule }

procedure TPipeMsgClient.CheckConnection;
var
  LReply: string;
begin
  SendMessage(CMD_CHECKCONNECTION, LReply);
end;

procedure TPipeMsgClient.Connect;
begin
  if FPipe <> INVALID_HANDLE_VALUE then
    Exit;

  if WaitNamedPipe(PWideChar('\\.\PIPE\' + FPipeName), DEF_CONNECTTIMEOUT) then
  begin
    FPipe := CreateFile(PWideChar('\\.\PIPE\' + FPipeName), GENERIC_READ or
      GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
    if FPipe = INVALID_HANDLE_VALUE then
      RaiseLastOSError;
  end
  else
    raise EPipeError.Create(RsErrConnect);
end;

constructor TPipeMsgClient.Create(const APipeName: string);
begin
  inherited;
  FReplyTimeout := DEF_REPLYTIMEOUT;
  FConnectTimeout := DEF_CONNECTTIMEOUT;
  FCS := TCriticalSection.Create;
end;

destructor TPipeMsgClient.Destroy;
begin
  Disconnect;
  FreeAndNil(FCS);
  inherited;
end;

procedure TPipeMsgClient.Disconnect;
begin
  if FPipe <> INVALID_HANDLE_VALUE then
    CloseHandle(FPipe);
  FPipe := INVALID_HANDLE_VALUE;
end;

procedure TPipeMsgClient.SendMessage(const AMessage: string);
begin
  Connect;
  try
    WriteMessage(AMessage);
  except
    on E: EOSError do
    begin
      if E.ErrorCode in [ERROR_PIPE_NOT_CONNECTED, ERROR_NO_DATA,
        ERROR_BROKEN_PIPE] then
      begin
        Disconnect;
        Connect;
        WriteMessage(AMessage);
      end
      else
        raise;
    end;
  end;
end;

procedure TPipeMsgClient.SendMessage(const AMessage: string;
  out AReply: string);
begin
  FCS.Enter;
  try
    SendMessage(AMessage);
    WaitForReply(AReply);
  finally
    FCS.Leave;
  end;
end;

procedure TPipeMsgClient.WaitForReply(out AMessage: string);
var
  LEndTime: Cardinal;
begin
  AMessage := '';

  LEndTime := GetTickCount + FReplyTimeout;
  while GetTickCount < LEndTime do
  begin
    if ReadMessage(AMessage) then
      Exit;
    Sleep(50);
  end;

  raise Exception.Create(RsErrResponse);
end;

{$IF CompilerVersion >= 28.0}

constructor TPipeMsgSvrInstanse.Create(const APipeName: string;
  AOnReceiveMessage: TReceiveMessageProc);
begin
  inherited Create(APipeName);

  FEnabled := False;
  FConnected := False;
  FOnReceiveMessage := AOnReceiveMessage;
  FPollingTask := nil;
  FOnError := nil;
end;

procedure TPipeMsgSvrInstanse.CreatePipe;
const
  SECURITY_WORLD_SID_AUTHORITY: TSidIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 1));
  SECURITY_WORLD_RID = ($00000000);
  ACL_REVISION = (2);
var
  SIA: SID_IDENTIFIER_AUTHORITY;
  SID: PSID;
  DaclSize: Integer;
  ACL: PACL;
  Descriptor: SECURITY_DESCRIPTOR;
  Attributes: SECURITY_ATTRIBUTES;
begin
  if FPipe <> INVALID_HANDLE_VALUE then
    Exit;

  SIA := SECURITY_WORLD_SID_AUTHORITY;
  SID := AllocMem(GetSidLengthRequired(1));
  try
    Win32Check(InitializeSid(SID, SECURITY_WORLD_SID_AUTHORITY, 1));
    PDWORD(GetSidSubAuthority(SID, 0))^ := SECURITY_WORLD_RID;
    DaclSize := SizeOf(ACL) + SizeOf(ACCESS_ALLOWED_ACE) + GetLengthSid(SID);
    ACL := AllocMem(DaclSize);
    try
      Win32Check(InitializeAcl(ACL^, DaclSize, ACL_REVISION));
      Win32Check(AddAccessAllowedAce(ACL^, ACL_REVISION, GENERIC_ALL, SID));
      Win32Check(InitializeSecurityDescriptor(@Descriptor,
        SECURITY_DESCRIPTOR_REVISION));
      Win32Check(SetSecurityDescriptorDacl(@Descriptor, True, ACL, False));
      Attributes.nLength := SizeOf(SECURITY_ATTRIBUTES);
      Attributes.lpSecurityDescriptor := @Descriptor;
      Attributes.bInheritHandle := False;

      FPipe := CreateNamedPipe(PWideChar('\\.\PIPE\' + FPipeName),
        PIPE_ACCESS_DUPLEX, PIPE_TYPE_MESSAGE or PIPE_READMODE_MESSAGE or
        PIPE_NOWAIT, MAX_INSTANCES, DEF_PIPE_BUF_SIZE, DEF_PIPE_BUF_SIZE, 500,
        @Attributes);

      if FPipe = INVALID_HANDLE_VALUE then
        RaiseLastOSError;

    finally
      FreeMem(ACL);
    end;

  finally
    FreeMem(SID);
  end;
end;

destructor TPipeMsgSvrInstanse.Destroy;
begin
  Disable;
  inherited;
end;

procedure TPipeMsgSvrInstanse.DestroyPipe;
begin
  if FPipe <> INVALID_HANDLE_VALUE then
  begin
    DisconnectNamedPipe(FPipe);
    CloseHandle(FPipe);
    FPipe := INVALID_HANDLE_VALUE;
  end;
end;

procedure TPipeMsgSvrInstanse.Disable;
begin
  if not FEnabled then
    Exit;
  FEnabled := False;

  if Assigned(FPollingTask) then
  begin
    TTask.WaitForAll([FPollingTask]);
    FPollingTask := nil;
  end;

  FConnected := False;
  DestroyPipe;
end;

procedure TPipeMsgSvrInstanse.Enable;
begin
  if FEnabled then
    Exit;

  Self.CreatePipe;

  FEnabled := True;
  try
    FPollingTask := TTask.Run(
      procedure()
      begin
        Polling;
      end);
  except
    FEnabled := False;
    raise;
  end;
end;

procedure TPipeMsgSvrInstanse.ProcessMessage(const AMessage: string);
var
  LReply: string;
begin
  if Trim(AMessage) = CMD_CHECKCONNECTION then
  begin
    WriteMessage(True.ToString(True));
    Exit;
  end;

  if not Assigned(FOnReceiveMessage) then
    Exit;

  LReply := '';
  FOnReceiveMessage(AMessage, LReply);
  if LReply <> '' then
    WriteMessage(LReply);
end;

procedure TPipeMsgSvrInstanse.Polling;
var
  LMsg: string;
begin
  while FEnabled do
  begin
    try
      if WaitConnection then
      begin
        if ReadMessage(LMsg) then
          ProcessMessage(LMsg);
      end;
    except
      if Assigned(FOnError) then
        FOnError(Exception(ExceptObject).Message);
    end;

    Sleep(DEF_POLLTIMEOUT);
  end;
end;

function TPipeMsgSvrInstanse.WaitConnection: Boolean;
var
  LError: DWORD;
begin
  Result := ConnectNamedPipe(FPipe, nil);
  try
    if not Result then
    begin
      LError := GetLastError;
      Result := LError = ERROR_PIPE_CONNECTED;
      if Result then
        Exit;

      if LError = ERROR_NO_DATA then
        DisconnectNamedPipe(FPipe);
    end;
  finally
    FConnected := Result;
  end;
end;

{$IFEND}
{ TPipeMsgCustom }

constructor TPipeMsgCustom.Create(const APipeName: string);
begin
  FPipe := INVALID_HANDLE_VALUE;
  FPipeName := APipeName;
end;

function TPipeMsgCustom.ReadMessage(out AMessage: string): Boolean;
var
  LRead: DWORD;
  LBuf: array of Byte; // Буфер чтения.
  LTotalBytesAvail: DWORD;
begin
  AMessage := '';
  Result := False;

  if not PeekNamedPipe(FPipe, nil, 0, nil, @LTotalBytesAvail, nil) then
    RaiseLastOSError;

  if LTotalBytesAvail = 0 then
    Exit;

  SetLength(LBuf, LTotalBytesAvail + 1);
  FillChar(LBuf[0], Length(LBuf), #0);
  if not ReadFile(FPipe, LBuf[0], LTotalBytesAvail, LRead, nil) then
    RaiseLastOSError;

  Result := LRead > 0;
  if Result then
  begin
    SetLength(AMessage, LRead div SizeOf(Char));
    Move(LBuf[0], AMessage[1], LRead);
  end;
end;

procedure TPipeMsgCustom.WriteMessage(const AMessage: string);
var
  LBytesWritten, LMsgLength: DWORD;
begin
  LMsgLength := Length(AMessage) * SizeOf(Char);
  if not WriteFile(FPipe, AMessage[1], LMsgLength, LBytesWritten, nil) then
    RaiseLastOSError;
  if LBytesWritten <> LMsgLength then
    raise Exception.Create(RsErrWriteData);
end;

{ TPipeMsgServer }
{$IF CompilerVersion >= 28.0}

constructor TPipeMsgServer.Create(const APipeName: string;
AOnReceiveMessage: TReceiveMessageProc; AInstansesCount: Cardinal);
var
  I: Integer;
begin
  FInstanses := TObjectList<TPipeMsgSvrInstanse>.Create;
  for I := 0 to AInstansesCount - 1 do
    FInstanses.Add(TPipeMsgSvrInstanse.Create(APipeName, AOnReceiveMessage));
end;

destructor TPipeMsgServer.Destroy;
begin
  Disable;
  FreeAndNil(FInstanses);
  inherited;
end;

procedure TPipeMsgServer.Disable;
var
  LInstance: TPipeMsgSvrInstanse;
begin
  for LInstance in FInstanses do
    LInstance.Disable;
end;

procedure TPipeMsgServer.Enable;
var
  LInstance: TPipeMsgSvrInstanse;
begin
  for LInstance in FInstanses do
    LInstance.Enable;
end;

procedure TPipeMsgServer.WriteMessage(const AMessage: string);
var
  LInstance: TPipeMsgSvrInstanse;
begin
  for LInstance in FInstanses do
    if LInstance.Connected then
      LInstance.WriteMessage(AMessage);
end;

{ TPipeMsgMonitor }

procedure TPipeMsgMonitor.AppendMsg(const AMsg: string);
begin
  if Assigned(FLines) then
  begin
    FLines.BeginUpdate;
    try
      FLines.Add(AMsg);

      while (FLines.Count > FMaxLines) do
        FLines.Delete(0);

    finally
      FLines.EndUpdate;
    end;
  end;

  if Assigned(FOnAppendMsg) then
    FOnAppendMsg(AMsg);
end;

procedure TPipeMsgMonitor.AppendMsgUIThread(const AMsg: string);
var
  LMsg: string;
begin
  LMsg := Trim(AMsg);

  TThread.Queue(nil,
    procedure
    begin
      AppendMsg(LMsg);
    end);
end;

constructor TPipeMsgMonitor.Create(const APipeName: string; ALines: TStrings);
begin
  Create(APipeName);
  FLines := ALines;
end;

constructor TPipeMsgMonitor.Create(const APipeName: string;
AOnAppendMsg: TGetStrProc);
begin
  Create(APipeName);
  FOnAppendMsg := AOnAppendMsg;
end;

constructor TPipeMsgMonitor.Create(const APipeName: string);
begin
  inherited;
  FOnAppendMsg := nil;
  FLines := nil;
  FMaxLines := DEF_MAXLINES;
  FReadTimeout := DEF_READTIMEOUT;
end;

destructor TPipeMsgMonitor.Destroy;
begin
  FOnAppendMsg := nil;
  FLines := nil;
  Disable;

  inherited;
end;

procedure TPipeMsgMonitor.Disable;
begin
  FEnabled := False;
  if Assigned(FListenerTask) then
  begin
    TTask.WaitForAll([FListenerTask]);
    FListenerTask := nil;
  end;
end;

procedure TPipeMsgMonitor.Enable;
begin
  FEnabled := True;
  try
    FListenerTask := TTask.Run(
      procedure()
      begin
        ListenerPolling;
      end);
  except
    FEnabled := False;
    raise;
  end;
end;

procedure TPipeMsgMonitor.ListenerPolling;
type
  TConnectionStatus = (csConnected, csDisconnected, csUnknown);
var
  LPrevStatus: TConnectionStatus; // Предыдущее состояние
  LMessage: string;
begin
  LPrevStatus := csUnknown;
  LMessage := RsConnectedSuccsessful;

  while FEnabled do
  begin
    try
      try
        Connect;
        LMessage := RsConnectedSuccsessful;
      except
        if LPrevStatus <> csDisconnected then // Если до этого был подключен
        begin
          AppendMsgUIThread(Exception(ExceptObject).Message);
          // Чтоб не дублировать сообщение об ошибке
          LPrevStatus := csDisconnected;
        end;
        Continue;
      end;

      if LPrevStatus <> csConnected then
        AppendMsgUIThread(LMessage);
      LPrevStatus := csConnected; // Запомним состояние

      try
        if ReadMessage(LMessage) then
          AppendMsgUIThread(LMessage);
      except
        AppendMsgUIThread(Exception(ExceptObject).Message);
        Disconnect;
      end;
    finally
      Sleep(FReadTimeout);
    end;
  end;

  Disconnect;
end;

constructor TPipeMsgMonitor.Create(const APipeName: string; ALines: TStrings;
AOnAppendMsg: TGetStrProc);
begin
  Create(APipeName);

  FOnAppendMsg := AOnAppendMsg;
  FLines := ALines;
end;
{$IFEND}

{$WARN SYMBOL_PLATFORM ON}

end.
