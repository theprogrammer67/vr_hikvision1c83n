unit Common.SimpleSocket;

interface

uses Winapi.Windows, Winapi.WinSock, System.SysUtils;

type
  TSockProtocol = (spTCP, spUDP);

  TOnSendReceive = procedure(Send: Boolean; const Data: AnsiString) of object;
  TOnCheckPacketEnd = function(const Data: AnsiString): Boolean of object;

  TSimpleSocket = class
  private
    FProtocol: TSockProtocol;
    FWSAStarted: Boolean;
    FReceiveTimeOut: Cardinal;
    FSocket: THandle;
    FHost: AnsiString;
    FPort: Word;
    FWSAData: TWSAData;
    FOnSendReceive: TOnSendReceive;
    FOnCheckPacketEnd: TOnCheckPacketEnd;
  private
    function GetConnected: Boolean;
    function ReceiveStringInternal: AnsiString; overload;
    function ReceivePacket: AnsiString;
  public
    constructor Create; virtual;
    destructor Destroy; override;
  public
    procedure Connect(NoDelay: Boolean = False; SndBufSize: Integer = -1;
      RcvBufSize: Integer = -1);
    procedure Disconnect;
  public
    procedure SendStringA(const AData: AnsiString);
    procedure SendStringUTF8(const StrData: string);
    procedure SendData(var Buf; BytesSend: Integer);
    procedure SendBytes(const ABytes: TBytes);
  public
    function ReceiveStringA: AnsiString;
    function ReceiveStringUTF8: string;
    procedure ReceiveData(var Buf; ACount: Integer);
    procedure ReceiveBytes(var ABytes: TBytes);
    function ReceiveByte: Byte;
  public
    property Connected: Boolean read GetConnected;
    property Host: AnsiString read FHost write FHost;
    property Port: Word read FPort write FPort;
    property ReceiveTimeOut: Cardinal read FReceiveTimeOut
      write FReceiveTimeOut;
    property Protocol: TSockProtocol read FProtocol write FProtocol;
    property OnSendReceive: TOnSendReceive read FOnSendReceive
      write FOnSendReceive;
    property OnCheckPacketEnd: TOnCheckPacketEnd read FOnCheckPacketEnd
      write FOnCheckPacketEnd;
  end;

implementation

const
  MAX_PACKET_SIZE = 8192;

resourcestring
  ERR_INVALID_SRV = 'Неверный адрес сервера или порт';
  ERR_NOT_CONNECTED = 'Соединение не установлено';
  ERR_NOT_RESPONSE = 'Сервер не отвечает';
  ERR_SEND_DATA = 'Ошибка отправки данных';
  ERR_WrongIPAddress = 'Неверный IP-адрес';
  ERR_RESPONSE_NOT_CORRECT = 'Некорректный или неполный ответ от сервера';

  { TTCPSync }

procedure TSimpleSocket.Connect(NoDelay: Boolean = False;
  SndBufSize: Integer = -1; RcvBufSize: Integer = -1);
var
  LAddr: TSockAddrIn;
  LOptVal: Integer;
  LResult: Boolean;
begin
  try
    if (Length(FHost) = 0) or (FPort = 0) then
      raise Exception.Create(ERR_INVALID_SRV);

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
      raise Exception.Create(SysErrorMessage(WSAGetLastError));

    LAddr.sin_addr.s_addr := inet_addr(PAnsiChar(FHost));
    if LAddr.sin_addr.s_addr = Integer(INADDR_NONE) then
      raise Exception.Create(ERR_WrongIPAddress);

    LOptVal := -1;
    if SetSockOpt(FSocket, SOL_SOCKET, SO_REUSEADDR, PAnsiChar(@LOptVal),
      SizeOf(LOptVal)) <> 0 then
      raise Exception.Create(SysErrorMessage(WSAGetLastError));

    if NoDelay then // Отправлять пакеты сразу
    begin
      LOptVal := 1;
      if SetSockOpt(FSocket, IPPROTO_TCP, TCP_NODELAY, PAnsiChar(@LOptVal),
        SizeOf(LOptVal)) <> 0 then
        raise Exception.Create(SysErrorMessage(WSAGetLastError));
    end;

    if SndBufSize > 0 then
    begin
      LOptVal := SndBufSize;
      if SetSockOpt(FSocket, SOL_SOCKET, SO_SNDBUF, PAnsiChar(@LOptVal),
        SizeOf(LOptVal)) <> 0 then
        raise Exception.Create(SysErrorMessage(WSAGetLastError));
    end;

    if RcvBufSize > 0 then
    begin
      LOptVal := RcvBufSize;
      if SetSockOpt(FSocket, SOL_SOCKET, SO_RCVBUF, PAnsiChar(@LOptVal),
        SizeOf(LOptVal)) <> 0 then
        raise Exception.Create(SysErrorMessage(WSAGetLastError));
    end;

    LAddr.sin_family := AF_INET;
    LAddr.sin_port := htons(FPort);

    if FProtocol = spTCP then
      LResult := Winapi.WinSock.Connect(FSocket, LAddr, SizeOf(LAddr)) = 0
    else
      LResult := Winapi.WinSock.Bind(FSocket, LAddr, SizeOf(LAddr)) = 0;

    if not LResult then
      raise Exception.Create(SysErrorMessage(WSAGetLastError));
  except
    CloseSocket(FSocket);
    FSocket := INVALID_HANDLE_VALUE;
    raise;
  end;
end;

constructor TSimpleSocket.Create;
begin
  FSocket := INVALID_HANDLE_VALUE;
  FHost := '';
  FPort := 0;
  FReceiveTimeOut := 10000;
  FWSAStarted := False;
  FProtocol := spTCP;
end;

destructor TSimpleSocket.Destroy;
begin
  Disconnect;
  if FWSAStarted then
    WSACleanup;
  inherited;
end;

procedure TSimpleSocket.Disconnect;
begin
  if Connected then
  begin
    CloseSocket(FSocket);
    FSocket := INVALID_HANDLE_VALUE;
  end;
end;

function TSimpleSocket.GetConnected: Boolean;
begin
  Result := FSocket <> INVALID_HANDLE_VALUE;
end;

function TSimpleSocket.ReceiveByte: Byte;
begin
  ReceiveData(Result, 1);
end;

procedure TSimpleSocket.ReceiveBytes(var ABytes: TBytes);
begin
  if Length(ABytes) = 0 then
    Exit;
  ReceiveData(ABytes[0], Length(ABytes));
end;

procedure TSimpleSocket.ReceiveData(var Buf; ACount: Integer);
var
  ReadSet: TFDSet;
  TimeOutVal: TTimeVal;
  StrData: AnsiString;
  BytesReceived: Integer;
begin
  StrData := '';
  BytesReceived := 0;

  if not Connected then
    raise Exception.Create(ERR_NOT_CONNECTED);

  FD_ZERO(ReadSet);
  FD_SET(FSocket, ReadSet);
  TimeOutVal.tv_sec := FReceiveTimeOut div 1000;
  TimeOutVal.tv_usec := 0;
  if Select(0, @ReadSet, nil, nil, @TimeOutVal) = SOCKET_ERROR then
    raise Exception.Create(SysErrorMessage(GetLastError));

  if (ReadSet.fd_Count > 0) and FD_ISSET(FSocket, ReadSet) then
    BytesReceived := recv(FSocket, Buf, ACount, 0);
  if (BytesReceived = 0) or (BytesReceived = SOCKET_ERROR) then
    raise Exception.Create(ERR_NOT_RESPONSE)
  else
  begin
    SetLength(StrData, BytesReceived);
    MoveMemory(@StrData[1], @Buf, BytesReceived);
  end;

  if Assigned(FOnSendReceive) then
    FOnSendReceive(False, StrData);
end;

function TSimpleSocket.ReceiveStringUTF8: string;
begin
  Result := UTF8ToString(ReceiveStringA);
end;

function TSimpleSocket.ReceivePacket: AnsiString;
var
  LEndTime: Cardinal;
  LPacket: AnsiString;
  LPacketEnd: Boolean;
begin
  Result := '';
  LEndTime := GetTickCount + FReceiveTimeOut;

  repeat
    LPacket := ReceiveStringInternal;
    Result := Result + LPacket;

    LPacketEnd := FOnCheckPacketEnd(Result);
    if LPacketEnd then
      Break;
  until GetTickCount > LEndTime;

  if not LPacketEnd then
    raise Exception.Create(ERR_RESPONSE_NOT_CORRECT);
end;

function TSimpleSocket.ReceiveStringA: AnsiString;
begin
  if Assigned(FOnCheckPacketEnd) then
    Result := ReceiveStringInternal
  else
    Result := ReceivePacket;
end;

function TSimpleSocket.ReceiveStringInternal: AnsiString;
var
  ReadSet: TFDSet;
  TimeOutVal: TTimeVal;
  BytesReceived: Integer;
  Buf: array [0 .. MAX_PACKET_SIZE] of Byte;
begin
  Result := '';
  BytesReceived := 0;

  if not Connected then
    raise Exception.Create(ERR_NOT_CONNECTED);

  FD_ZERO(ReadSet);
  FD_SET(FSocket, ReadSet);
  TimeOutVal.tv_sec := FReceiveTimeOut div 1000;
  TimeOutVal.tv_usec := 0;
  if Select(0, @ReadSet, nil, nil, @TimeOutVal) = SOCKET_ERROR then
    RaiseLastOSError;

  if (ReadSet.fd_Count > 0) and FD_ISSET(FSocket, ReadSet) then
    BytesReceived := recv(FSocket, Buf[0], MAX_PACKET_SIZE, 0);
  if (BytesReceived = 0) or (BytesReceived = SOCKET_ERROR) then
    raise Exception.Create(ERR_NOT_RESPONSE)
  else
  begin
    SetLength(Result, BytesReceived);
    MoveMemory(@Result[1], @Buf[0], BytesReceived);
  end;

  if Assigned(FOnSendReceive) then
    FOnSendReceive(False, Result);
end;

procedure TSimpleSocket.SendStringA(const AData: AnsiString);
var
  BytesSend: Integer;
  PBuf: Pointer;
begin
  GetMem(PBuf, Length(AData));
  try
    if Connected then
    begin
      ZeroMemory(PBuf, Length(AData));
      MoveMemory(PBuf, @AData[1], Length(AData));
      BytesSend := Send(FSocket, PBuf^, Length(AData), 0);
      if BytesSend = SOCKET_ERROR then
        raise Exception.Create(SysErrorMessage(WSAGetLastError))
      else if BytesSend < Length(AData) then
        raise Exception.Create(ERR_SEND_DATA);
    end
    else
      raise Exception.Create(ERR_NOT_CONNECTED);
  finally
    FreeMem(PBuf);
  end;

  if Assigned(FOnSendReceive) then
    FOnSendReceive(True, AData);
end;

procedure TSimpleSocket.SendBytes(const ABytes: TBytes);
begin
  SendData(ABytes[0], Length(ABytes));
end;

procedure TSimpleSocket.SendData(var Buf; BytesSend: Integer);
var
  BytesSended: Integer;
  LData: AnsiString;
begin
  if not Connected then
    raise Exception.Create(ERR_NOT_CONNECTED);

  BytesSended := Send(FSocket, Buf, BytesSend, 0);
  if BytesSended = SOCKET_ERROR then
    raise Exception.Create(SysErrorMessage(WSAGetLastError))
  else if BytesSended < BytesSend then
    raise Exception.Create(ERR_SEND_DATA);

  if Assigned(FOnSendReceive) then
  begin
    SetLength(LData, BytesSend);
    MoveMemory(@LData[1], @Buf, BytesSend);
    FOnSendReceive(True, LData);
  end;
end;

procedure TSimpleSocket.SendStringUTF8(const StrData: string);
begin
  SendStringA(UTF8Encode(StrData));
end;

end.
