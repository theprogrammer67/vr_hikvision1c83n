unit Common.HTTPClient;

interface

uses System.Classes, Winapi.WinInet, Winapi.Windows,
  System.Generics.Collections, IdURI, XSuperObject, System.SysUtils;

const
  csDefUserAgent = 'Rarus HTTP Client';
  CRLF = #13#10;
  cHTTPVersion = 'HTTP/1.1';

type
{$SCOPEDENUMS ON}
  THTTPMethod = (GET, HEAD, POST, PUT, PATH, DELETE, TRACE, CONNECT);
{$SCOPEDENUMS OFF}

type
  EHTTPError = class(Exception);
  EHTTPStatusError = class(EHTTPError);

type
  THttpRequest = class
  private
    FHTTPMethod: THTTPMethod;
    FParams: TStrings;
    FHeaders: TStrings;
    FJsonBody: ISuperObject;
    FIncludedRequests: TObjectList<THttpRequest>;
    FBoundary: string;
    FStringBody: string;
    FIdURI: TIdURI;
    FStreamBody: TMemoryStream;
    FBinaryResponseContent: Boolean;

    function GetHeader(const Name: string): string;
    procedure SetHeader(const Name, Value: string);
    function GetParam(const Name: string): string;
    procedure SetParam(const Name, Value: string);
    function GetHost: string;
    function GetPath: string;
    function GetPort: DWORD;
    procedure SetHost(const Value: string);
    procedure SetPath(const Value: string);
    procedure SetPort(const Value: DWORD);
    function EncodeParams: string;
    function GetProtocol: string;
    procedure SetProtocol(const Value: string);
    function GetDocument: string;
    procedure SetDocument(const Value: string);
    procedure AddMandatoryHeaders;
    procedure AddPart(var aRequest: string;
      const ContentType, PartBody: string);
    function GetUri: string;
    procedure SetUri(const Value: string);
    function GetHostAndPort: string;
    function GetHeadersText: string;
  protected
    procedure Prepare; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Clear; virtual;
    procedure AddRequest(aRequest: THttpRequest); overload;
    function AddRequest: THttpRequest; overload;
    function AddRequest(const APath: string; AMetod: THTTPMethod): THttpRequest;
      overload; virtual;
    function ToString(Included: Boolean = False; OnlyBody: Boolean = False)
      : string; reintroduce;

    property HTTPMethod: THTTPMethod read FHTTPMethod write FHTTPMethod;
    property Header[const Name: string]: string read GetHeader write SetHeader;
    property HeadersText: string read GetHeadersText;
    property Param[const Name: string]: string read GetParam write SetParam;
    property Boundary: string read FBoundary write FBoundary;
    property Host: string read GetHost write SetHost;
    property Port: DWORD read GetPort write SetPort;
    property PATH: string read GetPath write SetPath;
    property Document: string read GetDocument write SetDocument;
    property Protocol: string read GetProtocol write SetProtocol;
    property URI: string read GetUri write SetUri;
    property BinaryResponseContent: Boolean read FBinaryResponseContent
      write FBinaryResponseContent;

    property JsonBody: ISuperObject read FJsonBody write FJsonBody;
    property StringBody: string read FStringBody write FStringBody;
    property StreamBody: TMemoryStream read FStreamBody write FStreamBody;
  end;

  THttpResponse = class
  private
    FStatusCode: Integer;
    FStatusMessage: string;
    FHeaders: TStrings;
    FIncludedResponses: TObjectList<THttpResponse>;
    FStringBody: string;
    FJsonBody: ISuperObject;
    FStreamBody: TMemoryStream;
    // FEncoding: TEncoding;
    function GetContentType: string;
    function GetHeader(const Name: string): string;
    procedure SetHeader(const Name, Value: string);
    // procedure SetHeaders(const HeadersText: string);
    procedure ParseResponseBody;
    function GetStatusOK: Boolean;
    function GetHeadersText: string;
  public
    function GetPart(PartNum: Integer;
      out PartContentType, PartText: string): Boolean;
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure FromString(const StringData: string);
    function ToString: string; override;

    property StatusCode: Integer read FStatusCode write FStatusCode;
    property StatusOK: Boolean read GetStatusOK;
    property StatusMessage: string read FStatusMessage write FStatusMessage;
    property IncludedResponses: TObjectList<THttpResponse>
      read FIncludedResponses;
    property ContentType: string read GetContentType;
    // property Headers: TStrings read FHeaders;
    property Header[const Name: string]: string read GetHeader write SetHeader;
    property HeadersText: string read GetHeadersText;

    property JsonBody: ISuperObject read FJsonBody write FJsonBody;
    property StringBody: string read FStringBody write FStringBody;
    property StreamBody: TMemoryStream read FStreamBody write FStreamBody;
    // property Encoding: TEncoding read FEncoding write SetEncoding;
  end;

  THttpClient = class(THttpRequest)
  private
    FPassword: string;
    FUser: string;
    FHttpResponse: THttpResponse;
    FProxyPassword: string;
    FProxyUser: string;
    FEncoding: TEncoding;
    FLogEnabled: Boolean;
    FLogDirectory: string;
    FSendTimeout: Integer;
    FReceiveTimeout: Integer;
    FConnectTimeout: Integer;
    FGenerateStatusExceptions: Boolean;
  private
    procedure StringToStream(const S: string; AStream: TMemoryStream);
    function StreamToString(AStream: TMemoryStream): string;
    procedure LogRequest;
    procedure SetTimeouts(pConnection: HINTERNET);
  public
    constructor Create; override;
    destructor Destroy; override;
  public
    procedure Clear; override;
  public
    procedure SendRequest(blnSSL: Boolean = False); overload;
    procedure SendRequest(const ASource: string; out AResponseContent: string;
      blnSSL: Boolean = False); overload;
    procedure SendRequest(out AResponseContent: string;
      blnSSL: Boolean = False); overload;
    procedure SendRequest(ASource, AResponseContent: TMemoryStream;
      blnSSL: Boolean = False); overload;
  public
    property HTTPResponse: THttpResponse read FHttpResponse;
    property User: string read FUser write FUser;
    property Password: string read FPassword write FPassword;
    property ProxyUser: string read FProxyUser write FProxyUser;
    property ProxyPassword: string read FProxyPassword write FProxyPassword;
    property Encoding: TEncoding read FEncoding write FEncoding;
  public
    property ConnectTimeout: Integer read FConnectTimeout write FConnectTimeout;
    property SendTimeout: Integer read FSendTimeout write FSendTimeout;
    property ReceiveTimeout: Integer read FReceiveTimeout write FReceiveTimeout;
    property LogEnabled: Boolean read FLogEnabled write FLogEnabled;
    property LogDirectory: string read FLogDirectory write FLogDirectory;
    property GenerateStatusExceptions: Boolean read FGenerateStatusExceptions
      write FGenerateStatusExceptions;
  end;

procedure GetProxyData(var ProxyEnabled: Boolean; var ProxyServer: string;
  var ProxyPort: Integer);

const
  MimeContentStream = 'application/octet-stream';

  BinaryContents: array [0 .. 0] of string = (MimeContentStream);

implementation

uses System.TypInfo, System.StrUtils;

resourcestring
  rsErrIncorrectResponse = 'Некорректный ответ сервера';
  rsErrorCode = 'код ошибки';

function IsBinaryMimeType(const AType: string): Boolean;
var
  I: Integer;
begin
  for I := Low(BinaryContents) to High(BinaryContents) do
  begin
    Result := SameText(AType, BinaryContents[I]);
    if Result then
      Exit;
  end;
end;

function GetModuleFileNameStr: string;
var
  Buffer: array [0 .. MAX_PATH] of Char;
begin
  FillChar(Buffer, MAX_PATH, #0);
  GetModuleFileName(hInstance, Buffer, MAX_PATH);
  Result := Buffer;
end;

function GetModuleDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFileDir(GetModuleFileNameStr));
end;

function GetHeaderValue(const Header: string): string;
var
  P: Integer;
begin
  P := Pos(': ', Header);
  if P = 0 then
    Exit('');

  Result := Copy(Header, P + 2, Length(Header) - P - 3);
end;

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
    DELETE(Value, 1, 3);
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

  Result := Result + ' (' + rsErrorCode + '=' + IntToStr(ErrorCode) + ')';
end;

procedure RaiseLastWinInetError;
begin
  raise EHTTPError.Create(GetWinInetError(GetLastError));
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
        ProxyServer := string(ProxyInfo^.lpszProxy);
      end
  finally
    FreeMem(ProxyInfo);
  end;

  if ProxyEnabled and (ProxyServer <> '') then
  begin
    I := Pos('http=', ProxyServer);
    if (I > 0) then
    begin
      DELETE(ProxyServer, 1, I + 4);
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

{ THttpRequest }

procedure THttpRequest.AddMandatoryHeaders;
begin
  // FHeaders.Values['User-Agent'] := csDefUserAgent;
  FHeaders.Values['Host'] := GetHostAndPort;
  if FIncludedRequests.Count > 0 then
    FHeaders.Values['Content-Type'] := 'multipart/mixed; boundary="' +
      FBoundary + '"'
  else if FJsonBody <> nil then
    FHeaders.Values['Content-Type'] := 'application/json; charset=utf-8';
end;

procedure THttpRequest.AddPart(var aRequest: string;
  const ContentType, PartBody: string);
begin
  aRequest := aRequest + '--' + FBoundary + CRLF + 'Content-Type: ' +
    ContentType + CRLF + CRLF + PartBody;
end;

function THttpRequest.AddRequest(const APath: string; AMetod: THTTPMethod)
  : THttpRequest;
begin
  Result := AddRequest;
  Result.PATH := APath;
  Result.HTTPMethod := AMetod;
end;

function THttpRequest.AddRequest: THttpRequest;
begin
  Result := THttpRequest.Create;
  AddRequest(Result);
end;

procedure THttpRequest.AddRequest(aRequest: THttpRequest);
begin
  if Length(aRequest.Host) = 0 then
    aRequest.Host := Host;
  if aRequest.Port = 0 then
    aRequest.Port := Port;

  FIncludedRequests.Add(aRequest);
end;

procedure THttpRequest.Clear;
begin
  FHTTPMethod := THTTPMethod.GET;
  FJsonBody := nil;
  FBoundary := IntToHex(Random(MaxInt), 8) + IntToHex(Random(MaxInt), 8);
  FIncludedRequests.Clear;
  FHeaders.Clear;
  FParams.Clear;
  // FIdURI.URI := '';
  // FIdURI.Protocol := 'http';
  FStringBody := '';
  FStreamBody.Clear;
end;

constructor THttpRequest.Create;
begin
  FIncludedRequests := TObjectList<THttpRequest>.Create;
  FHeaders := TStringList.Create;
  FHeaders.LineBreak := CRLF;
  FParams := TStringList.Create;
  FParams.LineBreak := CRLF;
  FIdURI := TIdURI.Create;
  FStreamBody := TMemoryStream.Create;
  FBinaryResponseContent := False;

  Randomize;
  Clear;
end;

destructor THttpRequest.Destroy;
begin
  FStreamBody.Free;
  FIdURI.Free;
  FParams.Free;
  FIncludedRequests.Free;
  inherited;
end;

function THttpRequest.EncodeParams: string;
var
  I: Integer;
begin
  Result := '';

  for I := 0 to FParams.Count - 1 do
  begin
    if Length(Result) > 0 then
      Result := Result + '&';
    Result := Result + TIdURI.ParamsEncode(FParams.Names[I] + '=' +
      FParams.ValueFromIndex[I]);
  end;

  if Length(Result) > 0 then
    Result := '?' + Result;
end;

function THttpRequest.GetDocument: string;
begin
  Document := FIdURI.Document;
end;

function THttpRequest.GetHeader(const Name: string): string;
begin
  Result := FHeaders.Values[Name];
end;

function THttpRequest.GetHeadersText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FHeaders.Count - 1 do
    Result := Result + FHeaders.Names[I] + ': ' + FHeaders.ValueFromIndex[I] +
      sLineBreak;
end;

function THttpRequest.GetHost: string;
begin
  Result := FIdURI.Host;
end;

function THttpRequest.GetHostAndPort: string;
begin
  Result := FIdURI.Host;
  if Length(FIdURI.Port) > 0 then
    Result := Result + ':' + FIdURI.Port;
end;

function THttpRequest.GetParam(const Name: string): string;
begin
  Result := FParams.Values[Name];
end;

function THttpRequest.GetPath: string;
begin
  Result := FIdURI.PATH;
end;

function THttpRequest.GetPort: DWORD;
begin
  Result := StrToIntDef(FIdURI.Port, 0);
end;

function THttpRequest.GetProtocol: string;
begin
  Result := FIdURI.Protocol;
end;

function THttpRequest.GetUri: string;
begin
  Result := FIdURI.GetFullURI;
end;

procedure THttpRequest.Prepare;
begin
  AddMandatoryHeaders;
end;

procedure THttpRequest.SetDocument(const Value: string);
begin
  FIdURI.Document := Value;
end;

procedure THttpRequest.SetHeader(const Name, Value: string);
begin
  FHeaders.Values[Name] := Value;
end;

procedure THttpRequest.SetHost(const Value: string);
begin
  FIdURI.Host := Value;
end;

procedure THttpRequest.SetParam(const Name, Value: string);
begin
  FParams.Values[Name] := Value;
end;

procedure THttpRequest.SetPath(const Value: string);
begin
  FIdURI.PATH := Value;
end;

procedure THttpRequest.SetPort(const Value: DWORD);
begin
  if Value = 0 then
    FIdURI.Port := ''
  else
    FIdURI.Port := IntToStr(Value);
end;

procedure THttpRequest.SetProtocol(const Value: string);
begin
  FIdURI.Protocol := Value;
end;

procedure THttpRequest.SetUri(const Value: string);
begin
  FIdURI.URI := Value;
end;

function THttpRequest.ToString(Included: Boolean; OnlyBody: Boolean): string;
var
  // I: Integer;
  LURI: string;
  Request: THttpRequest;
begin
  // Заголовки
  if not OnlyBody then
  begin
    Prepare;

    if Included then
      LURI := FIdURI.PATH + FIdURI.Document
    else
      LURI := FIdURI.URI;

    Result := GetEnumName(TypeInfo(THTTPMethod), Ord(FHTTPMethod)) + ' ' + LURI
      + EncodeParams + ' ' + cHTTPVersion + CRLF;

    // for I := 0 to FHeaders.Count - 1 do
    // Result := Result + FHeaders.Names[I] + ': ' + FHeaders.ValueFromIndex
    // [I] + CRLF;
    Result := Result + HeadersText;

    Result := Result + CRLF;
  end;

  // Тело
  if Length(FStringBody) > 0 then
    Result := Result + FStringBody
  else if FJsonBody <> nil then
    Result := Result + FJsonBody.AsJSON
  else if FIncludedRequests.Count > 0 then
  begin
    for Request in FIncludedRequests do
      AddPart(Result, 'application/http; msgtype=request',
        Request.ToString(True));

    Result := Result + CRLF + '--' + FBoundary + '--';
  end;

  Result := Result + CRLF;
end;

{ THttpClient }

procedure THttpClient.SendRequest(blnSSL: Boolean = False);
begin
  if FStreamBody.Size = 0 then
    StringToStream(ToString(False, True), FStreamBody);

  try
    SendRequest(FStreamBody, FHttpResponse.FStreamBody, blnSSL);
  finally
    StreamBody.Clear;
  end;
end;

procedure THttpClient.Clear;
begin
  inherited;
  if Assigned(HTTPResponse) then
    HTTPResponse.Clear;
end;

constructor THttpClient.Create;
begin
  inherited;
  FHttpResponse := THttpResponse.Create;
  FUser := '';
  FPassword := '';
  FProxyUser := '';
  FProxyPassword := '';
  FEncoding := TEncoding.UTF8;
  FLogEnabled := False;
  FLogDirectory := '';
  FConnectTimeout := -1;
  FSendTimeout := -1;
  FReceiveTimeout := -1;
  FGenerateStatusExceptions := True;
end;

destructor THttpClient.Destroy;
begin
  FreeAndNil(FHeaders);
  FreeAndNil(FHttpResponse);
  inherited;
end;

procedure THttpClient.LogRequest;
var
  LLogDir: string;
  LLogStream: TStringStream;
begin
  if not LogEnabled then
    Exit;

  if FLogDirectory = '' then
    LLogDir := GetModuleDirectory
  else
    LLogDir := IncludeTrailingPathDelimiter(FLogDirectory);

  LLogStream := TStringStream.Create(ToString(False, False), Encoding);
  try
    LLogStream.SaveToFile(LLogDir + 'request.txt');
  finally
    LLogStream.Free;
  end;

  LLogStream := TStringStream.Create(FHttpResponse.ToString, Encoding);
  try
    LLogStream.SaveToFile(LLogDir + 'response.txt');
  finally
    LLogStream.Free;
  end;
end;

procedure THttpClient.SendRequest(const ASource: string;
  out AResponseContent: string; blnSSL: Boolean);
begin
  try
    FStreamBody.Clear;
    FStringBody := ASource;
    SendRequest(blnSSL);
  finally
    AResponseContent := HTTPResponse.StringBody;
  end;
end;

procedure THttpClient.SendRequest(out AResponseContent: string;
  blnSSL: Boolean);
begin
  try
    SendRequest;
  finally
    AResponseContent := HTTPResponse.StringBody;
  end;
end;

procedure THttpClient.SendRequest(ASource, AResponseContent: TMemoryStream;
  blnSSL: Boolean);
var
  aBuffer: array [0 .. 4096] of Byte;
  sMethod: WideString;
  BytesRead: Cardinal;
  pSession: HINTERNET;
  pConnection: HINTERNET;
  pRequest: HINTERNET;
  LPort: Integer;
  flags: DWORD;
  lpdwReserved: DWORD;
  lpdwBufferLength: DWORD;
  ErrorCode: Cardinal;
  LHeaders: string;

  function GetResponseTextValue(dwInfoLevel: DWORD): string;
  begin
    Result := '';
    lpdwBufferLength := 0;
    lpdwReserved := 0;

    if not HttpQueryInfo(pRequest, dwInfoLevel, nil, lpdwBufferLength,
      lpdwReserved) then
    begin
      ErrorCode := GetLastError;
      if ErrorCode <> ERROR_INSUFFICIENT_BUFFER then
        raise Exception.Create(GetWinInetError(ErrorCode));

      SetLength(Result, lpdwBufferLength div SizeOf(Char));
      if not HttpQueryInfo(pRequest, dwInfoLevel, @Result[1], lpdwBufferLength,
        lpdwReserved) then
        RaiseLastWinInetError;
    end;
  end;

begin
  Prepare;
  AResponseContent.Clear;
  FHttpResponse.FStatusCode := -1;
  FHttpResponse.FStatusMessage := '';

  pSession := InternetOpen(nil, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(pSession) then
    try
      if Port = 0 then
      begin
        if blnSSL then
          LPort := INTERNET_DEFAULT_HTTPS_PORT
        else
          LPort := INTERNET_DEFAULT_HTTP_PORT;
      end
      else
        LPort := Port;

      pConnection := InternetConnect(pSession, PChar(Host), LPort, nil, nil,
        INTERNET_SERVICE_HTTP, 0, 1);

      if Assigned(pConnection) then
        try
          SetTimeouts(pConnection);

          if Length(FProxyUser) > 0 then
          begin
            if not InternetSetOption(pConnection,
              INTERNET_OPTION_PROXY_USERNAME, PChar(ProxyUser),
              Length(ProxyUser) + 1) then
              RaiseLastWinInetError;
            if not InternetSetOption(pConnection,
              INTERNET_OPTION_PROXY_PASSWORD, PChar(ProxyPassword),
              Length(ProxyPassword) + 1) then
              RaiseLastWinInetError;
          end;

          sMethod := GetEnumName(TypeInfo(THTTPMethod), Ord(FHTTPMethod));

          if blnSSL then
            flags := INTERNET_FLAG_SECURE or INTERNET_FLAG_KEEP_CONNECTION
          else
            flags := INTERNET_SERVICE_HTTP;

          pRequest := HTTPOpenRequest(pConnection, PWideChar(sMethod),
            PWideChar(FIdURI.PATH + FIdURI.Document + EncodeParams + #0), nil,
            nil, nil, flags, 1);

          if Assigned(pRequest) then
            try
              // Добавим заголовки
              FHeaders.Values['Host'] := GetHostAndPort;
              if Length(FUser) > 0 then
                Header['Authorization'] := 'Basic ' +
                  EncodeBase64(User + ':' + Password);
              LHeaders := HeadersText;
              if not HttpAddRequestHeaders(pRequest, PWideChar(LHeaders),
                Length(LHeaders), HTTP_ADDREQ_FLAG_ADD) then
                RaiseLastWinInetError;

              // Отправка запроса
              if HTTPSendRequest(pRequest, nil, 0, ASource.Memory, ASource.Size)
              then
              begin
                lpdwBufferLength := SizeOf(FHttpResponse.FStatusCode);
                lpdwReserved := 0;
                if not HttpQueryInfo(pRequest, HTTP_QUERY_STATUS_CODE or
                  HTTP_QUERY_FLAG_NUMBER, @FHttpResponse.FStatusCode,
                  lpdwBufferLength, lpdwReserved) then
                  RaiseLastWinInetError;

                while InternetReadFile(pRequest, @aBuffer, SizeOf(aBuffer),
                  BytesRead) do
                begin
                  if (BytesRead = 0) then
                    Break;

                  AResponseContent.Write(aBuffer, BytesRead);
                end;

                // Распарсим заголовки
                HTTPResponse.FromString
                  (GetResponseTextValue(HTTP_QUERY_RAW_HEADERS_CRLF));

                // Генерируем исключение, если код статуса говорит об ошибке
                if (not FHttpResponse.StatusOK) and (FGenerateStatusExceptions)
                then
                  raise EHTTPStatusError.Create
                    (IntToStr(FHttpResponse.StatusCode) + ' - ' +
                    FHttpResponse.FStatusMessage);
              end
              else
                RaiseLastWinInetError;
            finally
              InternetCloseHandle(pRequest);
            end
          else
            raise Exception.Create(SysErrorMessage(GetLastError));
        finally
          InternetCloseHandle(pConnection);
        end
      else
        RaiseLastWinInetError;
    finally
      InternetCloseHandle(pSession);
      if (not FBinaryResponseContent) and
        (not IsBinaryMimeType(FHttpResponse.ContentType)) then
      begin
        FHttpResponse.FStringBody := StreamToString(AResponseContent);
        FHttpResponse.ParseResponseBody;
      end
      else
        FHttpResponse.FStringBody := '';
      LogRequest;
    end
  else
    RaiseLastWinInetError;
end;

procedure THttpClient.SetTimeouts(pConnection: HINTERNET);
begin
  if FConnectTimeout > 0 then
  begin
    if not InternetSetOption(pConnection, INTERNET_OPTION_CONNECT_TIMEOUT,
      Pointer(@FConnectTimeout), SizeOf(FConnectTimeout)) then
      RaiseLastWinInetError;
  end;
  if FSendTimeout > 0 then
  begin
    if not InternetSetOption(pConnection, INTERNET_OPTION_SEND_TIMEOUT,
      Pointer(@FSendTimeout), SizeOf(FSendTimeout)) then
      RaiseLastWinInetError;
  end;
  if FReceiveTimeout > 0 then
  begin
    if not InternetSetOption(pConnection, INTERNET_OPTION_RECEIVE_TIMEOUT,
      Pointer(@FReceiveTimeout), SizeOf(FReceiveTimeout)) then
      RaiseLastWinInetError;
  end;
end;

function THttpClient.StreamToString(AStream: TMemoryStream): string;
var
  Bytes: TBytes;
begin
  if (AStream = nil) or (AStream.Size = 0) then
    Exit('');

  SetLength(Bytes, AStream.Size);
  AStream.Position := 0;
  AStream.Read(Bytes, AStream.Size);
  Result := FEncoding.GetString(Bytes);
end;

procedure THttpClient.StringToStream(const S: string; AStream: TMemoryStream);
var
  Bytes: TBytes;
begin
  if AStream = nil then
    Exit;

  AStream.Clear;
  Bytes := Encoding.GetBytes(S);
  AStream.Write(Bytes, Length(Bytes));
end;

{ THttpResponse }

procedure THttpResponse.Clear;
begin
  FStatusCode := -1;
  FStatusMessage := '';
  FJsonBody := nil;
  FIncludedResponses.Clear;
  FHeaders.Clear;
  FStreamBody.Clear;
end;

constructor THttpResponse.Create;
begin
  inherited;
  FIncludedResponses := TObjectList<THttpResponse>.Create;
  FHeaders := TStringList.Create;
  FHeaders.LineBreak := CRLF;
  FStreamBody := TMemoryStream.Create;
  Clear;
end;

destructor THttpResponse.Destroy;
begin
  FHeaders.Free;
  FIncludedResponses.Free;
  FStreamBody.Free;
  inherited;
end;

procedure THttpResponse.FromString(const StringData: string);
var
  Strings: TStrings;
  P, I, Sp1, Sp2: Integer;
  LHeaders: Boolean;
begin
  FStringBody := '';
  Strings := TStringList.Create;
  Strings.LineBreak := CRLF;
  try
    Strings.Text := StringData;
    LHeaders := True;
    for I := 0 to Strings.Count - 1 do
    begin
      if I = 0 then // Статус
      begin
        Sp1 := PosEx(' ', Strings[I]);
        Sp2 := PosEx(' ', Strings[I], Sp1 + 1);
        if (Sp1 = 0) or (Sp2 = 0) then
          raise Exception.Create(rsErrIncorrectResponse);

        FStatusCode := StrToIntDef(Copy(Strings[I], Sp1 + 1, Sp2 - Sp1 - 1), 1);
        FStatusMessage := Copy(Strings[I], Sp2 + 1, Length(Strings[I]) - Sp2);
      end
      else if LHeaders and (Length(Strings[I]) = 0) then
        LHeaders := False // Конец заголовков
      else if LHeaders then
      begin // Строка заголовка
        P := Pos(': ', Strings[I]);
        if P > 0 then
          Header[LeftStr(Strings[I], P - 1)] :=
            RightStr(Strings[I], Length(Strings[I]) - P - 1);
      end
      else
      begin
        if Length(StringBody) > 0 then
          StringBody := StringBody + CRLF;
        StringBody := StringBody + Strings[I];
      end;
    end;
  finally
    Strings.Free;
  end;

  ParseResponseBody;
end;

function THttpResponse.GetContentType: string;
begin
  Result := Header['Content-Type'];
end;

function THttpResponse.GetHeader(const Name: string): string;
begin
  Result := FHeaders.Values[Name];
end;

function THttpResponse.GetHeadersText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FHeaders.Count - 1 do
    Result := Result + FHeaders.Names[I] + ': ' + FHeaders.ValueFromIndex[I] +
      sLineBreak;
end;

function THttpResponse.GetPart(PartNum: Integer;
  out PartContentType, PartText: string): Boolean;
var
  LStrings: TStrings;
  I, LPartNum: Integer;
begin
  LStrings := TStringList.Create;
  try
    LStrings.LineBreak := CRLF;
    LStrings.Text := FStringBody;
    LPartNum := 0;
    I := 0;
    PartText := '';
    Result := False;

    while I < LStrings.Count do
    begin
      if Result then
      begin
        if LeftStr(LStrings[I], 2) = '--' then
          Break
        else
        begin
          if Length(PartText) > 0 then
            PartText := PartText + CRLF;
          PartText := PartText + LStrings[I];
        end;
      end
      else
      begin
        if (LeftStr(LStrings[I], 2) = '--') and
          (RightStr(LStrings[I], 2) <> '--') then
        begin
          if LPartNum = PartNum then
          begin
            Result := True;
            Inc(I);
            if I >= LStrings.Count then
              raise Exception.Create(rsErrIncorrectResponse);

            if Pos('Content-Type: ', LStrings[I]) <> 1 then
              raise Exception.Create(rsErrIncorrectResponse);

            PartContentType := GetHeaderValue(LStrings[I]);

            Inc(I);
            if I >= LStrings.Count then
              raise Exception.Create(rsErrIncorrectResponse);
          end
          else
            Inc(LPartNum);
        end;
      end;

      Inc(I);
    end;
  finally
    LStrings.Free;
  end;
end;

function THttpResponse.GetStatusOK: Boolean;
begin
  Result := ((FStatusCode > 199) and (FStatusCode < 300));
end;

procedure THttpResponse.ParseResponseBody;
var
  LContentType, PartText, PartContentType: string;
  PartNum: Integer;
  IncludedResponse: THttpResponse;
begin
  if FStringBody = '' then
    Exit;

  LContentType := ContentType;

  if Pos('multipart/mixed', LContentType) = 1 then
  begin
    PartNum := 0;
    while GetPart(PartNum, PartContentType, PartText) do
    begin // Поддерживаем только batch ответы в multipart/mixed
      if Pos('application/http; msgtype=response', PartContentType) = 1 then
      begin
        IncludedResponse := THttpResponse.Create;
        IncludedResponse.FromString(PartText);

        IncludedResponses.Add(IncludedResponse);
      end;
      Inc(PartNum);
    end;
  end
  else if Pos('application/http', LContentType) = 1 then
  begin
    FromString(FStringBody);
  end
  else if Pos('application/json', LContentType) = 1 then
  begin
    try
      FJsonBody := SO(FStringBody);
    except
      raise Exception.Create(rsErrIncorrectResponse + sLineBreak +
        Exception(ExceptObject).Message);
    end;
  end;
end;

procedure THttpResponse.SetHeader(const Name, Value: string);
begin
  FHeaders.Values[Name] := Value;
end;

// procedure THttpResponse.SetHeaders(const HeadersText: string);
// var
// Strings: TStrings;
// LHeader: string;
// P: Integer;
// begin
// FHeaders.Clear;
// Strings := TStringList.Create;
// try
// Strings.LineBreak := CRLF;
// Strings.Text := HeadersText;
//
// for LHeader in Strings do
// begin
// P := Pos(': ', LHeader);
// if P > 0 then
// Header[LeftStr(LHeader, P - 1)] :=
// RightStr(LHeader, Length(LHeader) - P - 1);
// end;
// finally
// Strings.Free;
// end;
// end;

function THttpResponse.ToString: string;
begin
  Result := HeadersText + sLineBreak + FStringBody;
end;

end.
