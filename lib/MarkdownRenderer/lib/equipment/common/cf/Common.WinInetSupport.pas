unit Common.WinInetSupport;

interface

uses System.Classes, Winapi.WinInet, Winapi.Windows, IdURI;

type
  // TStringArray = array of string;

  THTTPClient = class
  private
    FHeaders: TStrings;
    FGetBkHeaders: boolean;
    FBackHeaders: TStrings;  //< заголовки ответа сервера
    FUserAgent: string;
    FProxyUser: string;
    FProxyPassword: string;
    FPassword: string;
    FUser: string;
    FBoundary: string;
    FInData: TStrings;
    FCaching: boolean;
    // таймауты (в миллисекундах), если <0, значит, не задавать явно
    FConnectTimeout,
    FSendTimeout   ,
    FReceiveTimeout: integer;
  protected
    FStatusCode: Integer;
    FStatusMessage: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddHeader(const AName, AValue: string);
    procedure ClearHeaders;
    procedure AddPart (PartStrings: TStrings;  LastPart: Boolean = False;
                       FirstPart: Boolean = True);
    procedure ClearInData;

    procedure SendRequest(AUrl: string; InData, OutData: TMemoryStream;
      blnSSL: Boolean = False;  Deleting: boolean = False); overload;
    procedure SendRequest(AUrl, InData: string; out OutData: string;
      blnSSL: Boolean = False); overload;
    procedure SendRequest(AUrl: string; out OutData: string;
      blnSSL: Boolean = False); overload;

    property UserAgent: string read FUserAgent write FUserAgent;
    property Headers: TStrings read FHeaders write FHeaders;
    property GetBackHeaders: boolean  read FGetBkHeaders  write FGetBkHeaders;
    property BackHeaders: TStrings  read FBackHeaders;
    property StatusCode: Integer read FStatusCode;
    property StatusMessage: string read FStatusMessage;
    property ProxyUser: string read FProxyUser write FProxyUser;
    property ProxyPassword: string read FProxyPassword write FProxyPassword;
    property User: string read FUser write FUser;
    property Password: string read FPassword write FPassword;
    property InData: TStrings read FInData write FInData;
    property Boundary: string read FBoundary write FBoundary;
    property ConnectTimeout: integer read FConnectTimeout write FConnectTimeout;
    property SendTimeout   : integer read FSendTimeout    write FSendTimeout   ;
    property ReceiveTimeout: integer read FReceiveTimeout write FReceiveTimeout;
    property Caching: boolean read FCaching write FCaching;
  end;

const
  csDefUserAgent = 'Rarus HTTP Client';

procedure GetProxyData(var ProxyEnabled: Boolean; var ProxyServer: string;
  var ProxyPort: Integer);




implementation

uses
  System.SysUtils, Math;

function EncodeBase64(Value: string): string;
const
  b64alphabet
    : PChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  pad: PChar = '====';

  function EncodeChunk(const Chunk: string): string;
  var
    W: LongWord;
    I, N: Byte;
  begin
    N := Length(Chunk);
    W := 0;
    for I := 0 to N - 1 do
      W := W + Ord(Chunk[I + 1]) shl ((2 - I) * 8);
    Result := b64alphabet[(W shr 18) and $3F] + b64alphabet[(W shr 12) and $3F]
      + b64alphabet[(W shr 06) and $3F] + b64alphabet[(W shr 00) and $3F];
    if N <> 3 then
      Result := Copy(Result, 0, N + 1) + Copy(pad, 0, 3 - N);
    // add padding when out len isn't 24 bits
  end;

begin
  Result := '';
  while Length(Value) > 0 do
  begin
    Result := Result + EncodeChunk(Copy(Value, 0, 3));
    Delete(Value, 1, 3);
  end;
end;

procedure GetProxyData(var ProxyEnabled: Boolean; var ProxyServer: string;
  var ProxyPort: Integer);
var
  ProxyInfo: PInternetProxyInfo;
  Len: LongWord;
  I, j: Integer;
begin
  Len := 4096;
  ProxyEnabled := False;
  ProxyServer := '';
  ProxyPort := 0;

  GetMem(ProxyInfo, Len);
  try
    if InternetQueryOption(nil, INTERNET_OPTION_PROXY, ProxyInfo, Len) then
      if ProxyInfo^.dwAccessType = INTERNET_OPEN_TYPE_PROXY then
      begin
        ProxyEnabled := True;
        ProxyServer := ProxyInfo^.lpszProxy;
      end
  finally
    FreeMem(ProxyInfo);
  end;

  if ProxyEnabled and (ProxyServer <> '') then
  begin
    I := Pos('http=', ProxyServer);
    if (I > 0) then
    begin
      Delete(ProxyServer, 1, I + 4);
      j := Pos(';', ProxyServer);
      if (j > 0) then
        ProxyServer := Copy(ProxyServer, 1, j - 1);
    end;
    I := Pos(':', ProxyServer);
    if (I > 0) then
    begin
      ProxyPort := StrToIntDef(Copy(ProxyServer, I + 1,
        Length(ProxyServer) - I), 0);
      ProxyServer := Copy(ProxyServer, 1, I - 1)
    end
  end;
end;

function GetWinInetError(ErrorCode: Cardinal): string;
const
  winetdll = 'wininet.dll';
var
  Len: Integer;
  Buffer: PChar;
begin
  Len := FormatMessage(FORMAT_MESSAGE_FROM_HMODULE or
    FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ALLOCATE_BUFFER or
    FORMAT_MESSAGE_IGNORE_INSERTS or FORMAT_MESSAGE_ARGUMENT_ARRAY,
    Pointer(GetModuleHandle(winetdll)), ErrorCode, 0, @Buffer,
    SizeOf(Buffer), nil);
  try
    while (Len > 0) and
{$IFDEF UNICODE}(CharInSet(Buffer[Len - 1], [#0 .. #32, '.']))
{$ELSE}(Buffer[Len - 1] in [#0 .. #32, '.']) {$ENDIF} do
      Dec(Len);
    SetString(Result, Buffer, Len);
  finally
    LocalFree(HLOCAL(Buffer));
  end;
end;




{ TRarusHTTPClient }

constructor THTTPClient.Create;
begin
  FInData := TStringList.Create;
  FInData.LineBreak := #13#10;
  FHeaders := TStringList.Create;
  FHeaders.LineBreak := #13#10;
  FGetBkHeaders := False;
  FBackHeaders := TStringList.Create;
  FBackHeaders.LineBreak := #13#10;

  FUserAgent := csDefUserAgent;
  ClearHeaders;
  FProxyUser := '';
  FProxyPassword := '';
  FUser := '';
  FPassword := '';
  FConnectTimeout := -1;
  FSendTimeout    := -1;
  FReceiveTimeout := -1;
  FCaching := True;

  Randomize;
  FBoundary := IntToHex(Random(MaxInt), 8) + IntToHex(Random(MaxInt), 8);
end;

destructor THTTPClient.Destroy;
begin
  FHeaders.Free;
  FInData.Free;
  inherited;
end;



procedure THTTPClient.AddHeader(const AName, AValue: string);
var
  I: Integer;
begin
  for I := 0 to FHeaders.Count - 1 do
  begin
    if Pos(AName, FHeaders[I]) = 1 then
    begin
      FHeaders[I] := AName + ': ' + AValue;
      Exit;
    end;
  end;

  FHeaders.Add(AName + ': ' + AValue);
end;

procedure THTTPClient.AddPart (PartStrings: TStrings;  LastPart, FirstPart: Boolean);
var
  I: Integer;
begin
  if FirstPart then
    FInData.Add(#13#10'--' + FBoundary);

  if ( PartStrings <> nil ) then
    for I := 0 to PartStrings.Count - 1 do
      FInData.Add(PartStrings[I]);

  if LastPart then
    FInData.Add(#13#10'--' + FBoundary + '--');
end;

procedure THTTPClient.ClearHeaders;
begin
  FHeaders.Clear;
  FHeaders.Add('User-Agent: ' + FUserAgent);
end;

procedure THTTPClient.ClearInData;
begin
  FInData.Clear;
end;



procedure THTTPClient.SendRequest(AUrl: string; out OutData: string;
  blnSSL: Boolean);
begin
  SendRequest(AUrl, FInData.Text, OutData, blnSSL);
end;

procedure THTTPClient.SendRequest(AUrl, InData: string; out OutData: string;
  blnSSL: Boolean);
var
  InStream, OutStream: TStringStream;
begin
  InStream := TStringStream.Create(UTF8Encode(InData));
  OutStream := TStringStream.Create;
  try
    SendRequest(AUrl, InStream, OutStream, blnSSL);
  finally
    OutData := UTF8Decode(OutStream.DataString);
    InStream.Free;
    OutStream.Free;
  end;
end;

procedure THTTPClient.SendRequest(AUrl: string; InData, OutData: TMemoryStream;
  blnSSL, Deleting: Boolean);

  function GetHttpQueryInfo (aRequestH: HINTERNET;  aHTTP_QUERY: Cardinal;
                             var aInfoStr: string): boolean;
  var
    ErrCode, BufLen, Rsrved: Cardinal;

    function Exec (aBufP: pointer): boolean;
    begin
      Result := HttpQueryInfo (aRequestH, aHTTP_QUERY, aBufP, BufLen, Rsrved);
      if Result then ErrCode := ERROR_SUCCESS
                else ErrCode := GetLastError();
    end;

  begin
    aInfoStr := '';
    ErrCode  := ERROR_SUCCESS;
    BufLen   := 0;
    Rsrved   := 0;
    try
      if Exec (nil) or
         ( ErrCode <> ERROR_INSUFFICIENT_BUFFER ) then Exit;
      SetLength (aInfoStr, BufLen div SizeOf(Char));
      if not Exec (@aInfoStr[1]) then Exit;
      SetLength (aInfoStr, BufLen div SizeOf(Char));
    finally
      Result := ( aInfoStr <> '' );
      if ( ErrCode <> ERROR_SUCCESS ) then
        raise Exception.Create (GetWinInetError(ErrCode));
    end;
  end;

var
  aBuffer: array [0 .. 4096] of Byte;
  sMethod: WideString;
  BytesRead: Cardinal;
  pSession: HINTERNET;
  pConnection: HINTERNET;
  pRequest: HINTERNET;
  Port: Integer;
  flags: DWord;
  IdURI: TIdURI;
  lpdwReserved: DWord;
  lpdwBufferLength: DWord;
  strAuthorization: string;
  bkHeads: string;

  procedure SetInetOption (aOption: Cardinal;  aValue: integer);
  begin
    if ( aValue > 0 ) then
      InternetSetOption (pRequest, aOption, pointer(@aValue), SizeOf(aValue));
  end;


begin
  OutData.Clear;
  FBackHeaders.Clear;
  FStatusCode := -1;
  FStatusMessage := '';

  pSession := InternetOpen(nil, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);

  if Assigned(pSession) then
    try
      IdURI := TIdURI.Create(AUrl);
      if Length(IdURI.Port) = 0 then
      begin
        if blnSSL then
          Port := INTERNET_DEFAULT_HTTPS_PORT
        else
          Port := INTERNET_DEFAULT_HTTP_PORT;
      end
      else
        Port := StrToIntDef(IdURI.Port, INTERNET_DEFAULT_HTTP_PORT);

      pConnection := InternetConnect(pSession, PChar(IdURI.Host), Port, nil,
        nil, INTERNET_SERVICE_HTTP, 0, 1);

      if Assigned(pConnection) then
        try
          if Length(FProxyUser) > 0 then
          begin
            if not InternetSetOption(pConnection,
              INTERNET_OPTION_PROXY_USERNAME, PChar(ProxyUser),
              Length(ProxyUser) + 1) then
              RaiseLastOSError;
            if not InternetSetOption(pConnection,
              INTERNET_OPTION_PROXY_PASSWORD, PChar(ProxyPassword),
              Length(ProxyPassword) + 1) then
              RaiseLastOSError;
          end;

          if Deleting then
            sMethod := 'DELETE'
          else begin
            if (InData.Size = 0) then
              sMethod := 'GET'
            else
              sMethod := 'POST';
          end;

          if blnSSL then
            flags := INTERNET_FLAG_SECURE or INTERNET_FLAG_KEEP_CONNECTION
          else
            flags := INTERNET_SERVICE_HTTP;
          if not FCaching then
            flags := flags or INTERNET_FLAG_NO_CACHE_WRITE;

          pRequest := HTTPOpenRequest(pConnection, PWideChar(sMethod),
            PWideChar(IdURI.GetPathAndParams + #0), nil, nil, nil, flags, 1);

          if Assigned(pRequest) then
            try
              SetInetOption (INTERNET_OPTION_CONNECT_TIMEOUT, FConnectTimeout);
              SetInetOption (INTERNET_OPTION_SEND_TIMEOUT   , FSendTimeout   );
              SetInetOption (INTERNET_OPTION_RECEIVE_TIMEOUT, FReceiveTimeout);
              AddHeader('Host', IdURI.Host + ':' + IntToStr(Port));
              if Length(FUser) > 0 then
              begin
                strAuthorization := User + ':' + Password;
                AddHeader('Authorization',
                  'Basic ' + EncodeBase64(strAuthorization));
              end;
              if not HttpAddRequestHeaders(pRequest, PWideChar(FHeaders.Text),
                Length(FHeaders.Text), HTTP_ADDREQ_FLAG_ADD) then
                  RaiseLastOSError;

              if HTTPSendRequest(pRequest, nil, 0, InData.Memory, InData.Size)
              then
              begin
                // заголовки с сервера
                if FGetBkHeaders and
                   GetHttpQueryInfo (pRequest, HTTP_QUERY_RAW_HEADERS_CRLF, bkHeads)
                then
                  FBackHeaders.Text := bkHeads;

                lpdwBufferLength := SizeOf(FStatusCode);
                lpdwReserved := 0;
                if not HttpQueryInfo(pRequest, HTTP_QUERY_STATUS_CODE or
                  HTTP_QUERY_FLAG_NUMBER, @FStatusCode, lpdwBufferLength,
                  lpdwReserved) then
                  RaiseLastOSError;

                while InternetReadFile(pRequest, @aBuffer, SizeOf(aBuffer),
                  BytesRead) do
                begin
                  if (BytesRead = 0) then
                    Break;
                  OutData.Write(aBuffer, BytesRead);
                end;

                if not InRange (FStatusCode, 200, 299) then
                begin
                  if not GetHttpQueryInfo (pRequest, HTTP_QUERY_STATUS_TEXT, FStatusMessage) then
                    FStatusMessage := Format ('unknown error (%d)', [FStatusCode]);
                  raise Exception.Create(FStatusMessage);
                end;

                // aBuffer[0] := 0;
                // OutData.Write(aBuffer, 1);
              end
              else
                RaiseLastOSError;

            finally
              InternetCloseHandle(pRequest);
            end
          else
            raise Exception.Create(SysErrorMessage(GetLastError));
        finally
          InternetCloseHandle(pConnection);
        end
      else
        RaiseLastOSError;
    finally
      FreeAndNil(IdURI);
      InternetCloseHandle(pSession);
    end
  else
    RaiseLastOSError;
end;

end.

