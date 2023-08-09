unit uTCPSync;

interface

uses Windows, WinSock, SysUtils, uTCPSyncConsts;

type
  TSockProtocol = (spTCP, spUDP);

  TOnSendReceive = procedure(Send: Boolean; const Data: AnsiString) of object;
  TOnCheckData = function(const Data: AnsiString): Boolean of object;

  TTCPSync = class
  private
    FProtocol: TSockProtocol;
    FLogFolder: string;
    FLogEnabled: Boolean;
    FWSAStarted: Boolean;
    FReceiveTimeOut: Cardinal;
    FSocket: THandle;
    FServer, FPort: AnsiString;
    FWSAData: TWSAData;
    FOnSendReceive: TOnSendReceive;
    FOnCheckData: TOnCheckData;
    function GetConnected: Boolean;
    procedure WriteLog(const Caption, Msg: string);
  protected
    FResultDescription: string;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function Connect(NoDelay: Boolean = False; SndBufSize: Integer = -1;
      RcvBufSize: Integer = -1): Boolean;
    procedure Disconnect;

    function SendData(const StrData: AnsiString): Boolean; overload;
    function SendData(var Buf; BytesSend: Integer): Boolean; overload;
    function SendDataUTF8(const StrData: string): Boolean;

    function ReceiveData(out StrData: AnsiString): Boolean; overload;
    function ReceiveData(var Buf; BytesReceive: Integer): Boolean; overload;
    function ReceiveDataWithCheck(out StrData: AnsiString): Boolean;
    function ReceiveDataUTF8(out StrData: string): Boolean;

    property Connected: Boolean read GetConnected;
    property Server: AnsiString read FServer write FServer;
    property Port: AnsiString read FPort write FPort;
    property ResultDescription: string read FResultDescription;
    property ReceiveTimeOut: Cardinal read FReceiveTimeOut
      write FReceiveTimeOut;
    property LogEnabled: Boolean read FLogEnabled write FLogEnabled;
    property LogFolder: string read FLogFolder write FLogFolder;
    property Protocol: TSockProtocol read FProtocol write FProtocol;
    property OnSendReceive: TOnSendReceive read FOnSendReceive
      write FOnSendReceive;
    property OnCheckData: TOnCheckData read FOnCheckData write FOnCheckData;
  end;

implementation

{ TTCPSync }

function TTCPSync.Connect(NoDelay: Boolean = False; SndBufSize: Integer = -1;
  RcvBufSize: Integer = -1): Boolean;
var
  FAddr: TSockAddrIn;
  OptVal: Integer;
begin
  Result := False;
  try
    if (Length(FServer) = 0) or (Length(FPort) = 0) then
    begin
      FResultDescription := ERR_INVALID_SRV;
      Exit;
    end;

    if not FWSAStarted then
    begin
      WSAStartup($0101, FWSAData);
      FWSAStarted := True;
    end;

    if FProtocol = spTCP then
      FSocket := Socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
    else
      FSocket := Socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);

{$IF CompilerVersion > 19}
    if NativeUInt(FSocket) = NativeUInt(INVALID_SOCKET) then
{$ELSE}
      if FSocket = INVALID_SOCKET then
{$IFEND}
      begin
        FResultDescription := SysErrorMessage(WSAGetLastError);
        Exit;
      end;

    try
      FAddr.sin_addr.s_addr := inet_addr(PAnsiChar(FServer));
      if FAddr.sin_addr.s_addr = Integer(INADDR_NONE) then
      begin
        FResultDescription := ERR_WrongIPAddress;
        Exit;
      end;
      OptVal := -1;
      if SetSockOpt(FSocket, SOL_SOCKET, SO_REUSEADDR, PAnsiChar(@OptVal),
        SizeOf(OptVal)) <> 0 then
      begin
        FResultDescription := SysErrorMessage(WSAGetLastError);
        Exit;
      end;

      if NoDelay then // Отправлять пакеты сразу
      begin
        OptVal := 1;
        if SetSockOpt(FSocket, IPPROTO_TCP, TCP_NODELAY, PAnsiChar(@OptVal),
          SizeOf(OptVal)) <> 0 then
        begin
          FResultDescription := SysErrorMessage(WSAGetLastError);
          Exit;
        end;
      end;

      if SndBufSize > 0 then
      begin
        OptVal := SndBufSize;
        if SetSockOpt(FSocket, SOL_SOCKET, SO_SNDBUF, PAnsiChar(@OptVal),
          SizeOf(OptVal)) <> 0 then
        begin
          FResultDescription := SysErrorMessage(WSAGetLastError);
          Exit;
        end;
      end;

      if RcvBufSize > 0 then
      begin
        OptVal := RcvBufSize;
        if SetSockOpt(FSocket, SOL_SOCKET, SO_RCVBUF, PAnsiChar(@OptVal),
          SizeOf(OptVal)) <> 0 then
        begin
          FResultDescription := SysErrorMessage(WSAGetLastError);
          Exit;
        end;
      end;

      FAddr.sin_family := AF_INET;
      FAddr.sin_port := htons(StrToInt(FPort));

      if FProtocol = spTCP then
        Result := WinSock.Connect(FSocket, FAddr, SizeOf(FAddr)) = 0
      else
        Result := WinSock.Bind(FSocket, FAddr, SizeOf(FAddr)) = 0;

      if not Result then
      begin
        FResultDescription := SysErrorMessage(WSAGetLastError);
        Exit;
      end;
    except
      CloseSocket(FSocket);
      FSocket := INVALID_HANDLE_VALUE;
      raise;
    end;
  finally
    WriteLog('Connect', BoolToStr(Result, True) + ' - ' + FResultDescription);
  end;

end;

constructor TTCPSync.Create;
begin
  FLogFolder := '';
  FLogEnabled := False;
  FSocket := INVALID_HANDLE_VALUE;
  FServer := '';
  FPort := '';
  FReceiveTimeOut := 10;
  FWSAStarted := False;
  FProtocol := spTCP;
end;

destructor TTCPSync.Destroy;
begin
  Disconnect;
  if FWSAStarted then
    WSACleanup;
  inherited;
end;

procedure TTCPSync.Disconnect;
begin
  if Connected then
  begin
    CloseSocket(FSocket);
    FSocket := INVALID_HANDLE_VALUE;
    WriteLog('Disconnect', BoolToStr(True, True));
  end;
end;

function TTCPSync.GetConnected: Boolean;
begin
  Result := FSocket <> INVALID_HANDLE_VALUE;
end;

function TTCPSync.ReceiveData(var Buf; BytesReceive: Integer): Boolean;
var
  ReadSet: TFDSet;
  TimeOutVal: TTimeVal;
  StrData: AnsiString;
  BytesReceived: Integer;
begin
  FResultDescription := '';
  StrData := '';
  BytesReceived := 0;
  Result := False;

  try
    if not Connected then
    begin
      FResultDescription := ERR_NOT_CONNECTED;
      Exit;
    end;

    FD_ZERO(ReadSet);
    FD_SET(FSocket, ReadSet);
    TimeOutVal.tv_sec := FReceiveTimeOut;
    TimeOutVal.tv_usec := 0;
    if Select(0, @ReadSet, nil, nil, @TimeOutVal) = SOCKET_ERROR then
    begin
      FResultDescription := SysErrorMessage(GetLastError);
      Exit;
    end;

    if (ReadSet.fd_Count > 0) and FD_ISSET(FSocket, ReadSet) then
      BytesReceived := recv(FSocket, Buf, BytesReceive, 0);
    if (BytesReceived = 0) or (BytesReceived = SOCKET_ERROR) then
      FResultDescription := ERR_NOT_RESPONSE
    else
    begin
      SetLength(StrData, BytesReceived);
      MoveMemory(@StrData[1], @Buf, BytesReceived);
      Result := True;
    end;
  finally
    WriteLog('ReceiveData', BoolToStr(Result, True) + ' - ' + FResultDescription
      + '; StrData: ' + StrData);
    if Result and Assigned(FOnSendReceive) then
      FOnSendReceive(False, StrData);
  end;
end;

function TTCPSync.ReceiveDataUTF8(out StrData: string): Boolean;
var
  DataAnsi: AnsiString;
begin
  Result := ReceiveDataWithCheck(DataAnsi);
  if Result then
    StrData := UTF8Decode(DataAnsi);
end;

function TTCPSync.ReceiveDataWithCheck(out StrData: AnsiString): Boolean;
var
  StartTime: Cardinal;
  TimeOutError: Boolean;
  Packet: AnsiString;
begin
  if not Assigned(FOnCheckData) then
    raise Exception.Create(ERR_CheckDataNotAssigned);

  TimeOutError := True;
  StrData := '';
  StartTime := GetTickCount;

  repeat
    Result := ReceiveData(Packet);

    if not Result then
    begin
      TimeOutError := False;
      Break;
    end;

    StrData := StrData + Packet;

    Result := FOnCheckData(StrData);
    if Result then
    begin
      TimeOutError := False;
      Break;
    end;
  until (GetTickCount - StartTime) > (FReceiveTimeOut * 1000);

  if Result and TimeOutError then
  begin
    Result := False;
    FResultDescription := ERR_RESPONSE_NOT_CORRECT;
  end;
end;

function TTCPSync.ReceiveData(out StrData: AnsiString): Boolean;
var
  ReadSet: TFDSet;
  TimeOutVal: TTimeVal;
  BytesReceived: Integer;
  Buf: array[0..MAX_PACKET_SIZE] of Byte;
begin
  FResultDescription := '';
  StrData := '';
  BytesReceived := 0;
  Result := False;

  try
    if not Connected then
    begin
      FResultDescription := ERR_NOT_CONNECTED;
      Exit;
    end;

    FD_ZERO(ReadSet);
    FD_SET(FSocket, ReadSet);
    TimeOutVal.tv_sec := FReceiveTimeOut;
    TimeOutVal.tv_usec := 0;
    if Select(0, @ReadSet, nil, nil, @TimeOutVal) = SOCKET_ERROR then
    begin
      FResultDescription := SysErrorMessage(GetLastError);
      Exit;
    end;

    if (ReadSet.fd_Count > 0) and FD_ISSET(FSocket, ReadSet) then
      BytesReceived := recv(FSocket, Buf[0], MAX_PACKET_SIZE, 0);
    if (BytesReceived = 0) or (BytesReceived = SOCKET_ERROR) then
      FResultDescription := ERR_NOT_RESPONSE
    else
    begin
      SetLength(StrData, BytesReceived);
      MoveMemory(@StrData[1], @Buf[0], BytesReceived);
      Result := True;
    end;
  finally
    WriteLog('ReceiveData', BoolToStr(Result, True) + ' - ' + FResultDescription
      + '; StrData: ' + StrData);
    if Result and Assigned(FOnSendReceive) then
      FOnSendReceive(False, StrData);
  end;
end;

function TTCPSync.SendData(const StrData: AnsiString): Boolean;
var
  BytesSend: Integer;
  PBuf: Pointer;
begin
  Result := False;
  FResultDescription := '';

  try
    GetMem(PBuf, Length(StrData));
    try
      if Connected then
      begin
        ZeroMemory(PBuf, Length(StrData));
        MoveMemory(PBuf, @StrData[1], Length(StrData));
        BytesSend := Send(FSocket, PBuf^, Length(StrData), 0);
        if BytesSend = SOCKET_ERROR then
          FResultDescription := SysErrorMessage(WSAGetLastError)
        else if BytesSend < Length(StrData) then
          FResultDescription := ERR_SEND_DATA
        else
          Result := True;
      end
      else
        FResultDescription := ERR_NOT_CONNECTED;
    finally
      FreeMem(PBuf);
    end;
  finally
    WriteLog('SendData', BoolToStr(Result, True) + ' - ' + FResultDescription +
      '; StrData: ' + StrData);
    if Result and Assigned(FOnSendReceive) then
      FOnSendReceive(True, StrData);
  end;
end;

procedure TTCPSync.WriteLog(const Caption, Msg: string);

  function GetModuleFileNameStr: string;
  var
    Buffer: array[0..MAX_PATH] of Char;
  begin
    FillChar(Buffer, MAX_PATH, #0);
    GetModuleFileName(hInstance, Buffer, MAX_PATH);
    Result := Buffer;
  end;

var
  F: TextFile;
  S: string;
begin
  if not FLogEnabled then
    Exit;
  if DirectoryExists(FLogFolder) then
    S := FLogFolder
  else
    S := ExtractFileDir(GetModuleFileNameStr);

  S := IncludeTrailingPathDelimiter(S) + ExtractFileName
    (GetModuleFileNameStr) + '.log';

  try
    AssignFile(F, S);
    if FileExists(S) then
      Append(F)
    else
      ReWrite(F);

    WriteLn(F, DateTimeToStr(Now) + #9 + Caption + ': '#9 + Msg);
  finally
    CloseFile(F);
  end;
end;

function TTCPSync.SendData(var Buf; BytesSend: Integer): Boolean;
var
  BytesSended: Integer;
  StrData: AnsiString;
begin
  Result := False;
  FResultDescription := '';
  SetLength(StrData, BytesSend);
  MoveMemory(@StrData[1], @Buf, BytesSend);

  try
    if Connected then
    begin
      BytesSended := Send(FSocket, Buf, BytesSend, 0);
      if BytesSended = SOCKET_ERROR then
        FResultDescription := SysErrorMessage(WSAGetLastError)
      else if BytesSended < BytesSend then
        FResultDescription := ERR_SEND_DATA
      else
        Result := True;
    end
    else
      FResultDescription := ERR_NOT_CONNECTED;
  finally
    WriteLog('SendData', BoolToStr(Result, True) + ' - ' + FResultDescription +
      '; StrData: ' + StrData);
    if Result and Assigned(FOnSendReceive) then
      FOnSendReceive(True, StrData);
  end;
end;

function TTCPSync.SendDataUTF8(const StrData: string): Boolean;
var
  DataUTF8: AnsiString;
begin
  DataUTF8 := UTF8Encode(StrData);
  Result := SendData(DataUTF8);
end;

end.

