unit uCommManager;

interface

uses Windows, Messages, SysUtils, SyncObjs, Classes;

const
  DefResponseTimeout = 1000;
  DefMaxCmdLen = 255;

  dcb_Binary = $00000001;
  dcb_ParityCheck = $00000002;
  dcb_OutxCtsFlow = $00000004;
  dcb_OutxDsrFlow = $00000008;
  dcb_DtrControlMask = $00000030;
  dcb_DtrControlDisable = $00000000;
  dcb_DtrControlEnable = $00000010;
  dcb_DtrControlHandshake = $00000020;
  dcb_DsrSensivity = $00000040;
  dcb_TXContinueOnXoff = $00000080;
  dcb_OutX = $00000100;
  dcb_InX = $00000200;
  dcb_ErrorChar = $00000400;
  dcb_NullStrip = $00000800;
  dcb_RtsControlMask = $00003000;
  dcb_RtsControlDisable = $00000000;
  dcb_RtsControlEnable = $00001000;
  dcb_RtsControlHandshake = $00002000;
  dcb_RtsControlToggle = $00003000;
  dcb_AbortOnError = $00004000;
  dcb_Reserveds = $FFFF8000;

  NUL: AnsiChar = #$00;
  SOH: AnsiChar = #$01;
  STX: AnsiChar = #$02;
  ETX: AnsiChar = #$03;
  EOT: AnsiChar = #$04;
  ENQ: AnsiChar = #$05;
  ACK: AnsiChar = #$06;
  BEL: AnsiChar = #$07;
  BS: AnsiChar = #$08;
  TAB: AnsiChar = #$09;
  LF: AnsiChar = #$0A;
  VT: AnsiChar = #$0B;
  FF: AnsiChar = #$0C;
  CR: AnsiChar = #$0D;
  SO: AnsiChar = #$0E;
  SI: AnsiChar = #$0F;
  DLE: AnsiChar = #$10;
  DC1: AnsiChar = #$11;
  DC2: AnsiChar = #$12;
  DC3: AnsiChar = #$13;
  DC4: AnsiChar = #$14;
  NAK: AnsiChar = #$15;
  SYN: AnsiChar = #$16;
  ETB: AnsiChar = #$17;
  CAN: AnsiChar = #$18;
  EM: AnsiChar = #$19;
  SUB: AnsiChar = #$1A;
  ESC: AnsiChar = #$1B;
  FS: AnsiChar = #$1C;
  GS: AnsiChar = #$1D;
  RS: AnsiChar = #$1E;
  US: AnsiChar = #$1F;

resourcestring
  S_OpenPortError = 'ќшибка открыти€ порта';
  S_WriteDataError = 'Ќе удалось записать данные в порт';
  S_BufferEmpty = 'ƒанные в буфере отсутствуют';
  S_PortNotOpened = 'ѕорт не открыт';

type
  TParity = (prNone, prOdd, prEven, prMark, prSpace);
  TControlDtr = (dtrDisable, dtrEnable, dtrHandshake);
  TControlRts = (rtsDisable, rtsEnable, rtsHandshake, rtsToggle);
  TBaudRate = (br110, br300, br600, br1200, br2400, br4800, br9600, br14400,
    br19200, br38400, br56000, br57600, br115200);
  TStopBits = (sbOneStopBit, sbOne5StopBits, sbTwoStopBits);

  TFlowControl = packed record
    FOutCtsFlow: Boolean;
    FOutDsrFlow: Boolean;
    FControlDtr: TControlDtr;
    FControlRts: TControlRts;
    FXonXoffOut: Boolean;
    FXonXoffIn: Boolean;
  end;

  { TComm }
  TComm = class
  private
    FEvtChar: AnsiChar;
    FXonLimit: Word;
    FXoffLimit: Word;
    procedure SetEvtChar(const Value: AnsiChar);
  protected
    FHandle: THandle;
    FOverlappedMode: Boolean;
    FReadOverlapped: TOverlapped; // параметры асинхронной операции чтени€
    FWriteOverlapped: TOverlapped; // параметры асинхронной операции записи
    FBaudRate: TBaudRate;
    FPortNumber: Integer;
    FTimeouts: TCommTimeouts;
    FParity: TParity;
    FFlowControl: TFlowControl;
    FAbortOnError: Boolean;
    FDataBits: Byte;
    FStopBits: TStopBits;
    FEndSymbol: AnsiString;
    FReadAfterEndSymbol: Byte;
    // —колько еще прочитать смволов после символа конца
  protected
    FExtResultDescription: string;
    procedure SetWin32Error;
    function GetOpened: Boolean;
    function CheckOpened: Boolean;
    function CreateHandle: Boolean;
    function UpdateTimeouts: Boolean;
    function UpdateDataControlBlock: Boolean;
    property Handle: THandle read FHandle;
    procedure SetBaudRate(Value: TBaudRate);
    procedure SetTimeouts(const Value: TCommTimeouts);
    procedure SetBaudRateAsInt(Value: Integer);
    function GetBaudRateAsInt: Integer;
    function GetCommStatus(out CommStat: TComStat): Boolean; overload;
    function GetCommStatus(out Errors: Cardinal; out CommStat: TComStat): Boolean; overload;
    function GetCommErrors(out Errors: Cardinal): Boolean;
    function GetWriteBufLen: Cardinal;
    function GetReadBufLen: Cardinal;
    function GetDSR: Boolean;
  public
    FDCBFlags: Integer;
    constructor Create;
    destructor Destroy; override;
  public
    function Open: Boolean;
    function Close: Boolean;
    function Purge(Abort: Boolean = True): Boolean;
    procedure SetCommDTR(Value: Boolean);
    procedure SetCommRTS(Value: Boolean);
    procedure SetMask;
    procedure StopEventWaiting;

    function ReadByte(var Value: Byte): Boolean; overload;
    function ReadByte(var Value: Byte; Timeout: Cardinal): Boolean; overload;
    function ReadChar(var Value: AnsiChar): Boolean; overload;
    function ReadChar(out Ch: AnsiChar; Timeout: Cardinal): Boolean; overload;
    function iReadByte(var Value: Byte): Integer;
    function ReadBytes(Buff: PByteArray; dwBuffSize: DWORD; out dwRead: DWORD;
      Timeout: Cardinal = 0): Boolean; overload;
    function ReadBytes(Count: DWORD; var Buff: array of Byte): Boolean;
      overload;
{$IF CompilerVersion > 19}
    function ReadBytes(var ABuff: TBytes; ACount: DWORD): Boolean; overload;
{$IFEND}
    function ReadString(Count: DWORD; out Buff: AnsiString): Boolean; overload;
    function ReadString(out Buff: AnsiString; Timeout: Cardinal = 0)
      : Boolean; overload;

    function ReadStr(out Data: AnsiString; EndSymb: AnsiChar; Timeout: Cardinal)
      : Integer; overload;
    function ReadStr(Count: DWORD; var Data: AnsiString;
      ControlLength: Boolean = False): Integer; overload;
    function ReadStr(Count: DWORD; var Data: AnsiString;
      const EndSymb: AnsiString): Integer; overload;
    function ReadStr(out Data: AnsiString; Timeout: Cardinal = 50)
      : Integer; overload;

    function WriteStr(const Data: AnsiString; SleepTime: Integer = 0): Boolean;
    function WriteByte(Value: Byte): Boolean;
    function WriteBytes(Buff: PByteArray; dwBuffSize: DWORD): Boolean; overload;
    function WriteBytes(Buff: array of Byte): Boolean; overload;
    function WriteChar(Value: AnsiChar): Boolean;

    function RunCmd(const InData: AnsiString; out OutData: AnsiString;
      MaxLen: Integer = DefMaxCmdLen; Timeout: Cardinal = DefResponseTimeout;
      CountAfterEnd: Byte = 0): Integer; overload;
    function RunCmd(const InData: AnsiString; out OutData: AnsiString;
      const EndSymb: AnsiString; MaxLen: Integer = DefMaxCmdLen;
      Timeout: Integer = DefResponseTimeout; CountAfterEnd: Byte = 0)
      : Integer; overload;
    function SendCmd(const Data: AnsiString): Integer;
  public
    property Opened: Boolean read GetOpened;
    property BaudRate: TBaudRate read FBaudRate write SetBaudRate;
    property BaudRateAsInt: Integer read GetBaudRateAsInt
      write SetBaudRateAsInt;
    property PortNumber: Integer read FPortNumber write FPortNumber;
    property Timeouts: TCommTimeouts read FTimeouts write SetTimeouts;
    property ExtResultDescription: string read FExtResultDescription
      write FExtResultDescription;
    property Parity: TParity read FParity write FParity;
    property FlowControl: TFlowControl read FFlowControl write FFlowControl;
    property DataBits: Byte read FDataBits write FDataBits;
    property StopBits: TStopBits read FStopBits write FStopBits;
    property EndSymbol: AnsiString read FEndSymbol write FEndSymbol;
    property OverlappedMode: Boolean read FOverlappedMode write FOverlappedMode;
    property EvtChar: AnsiChar read FEvtChar write SetEvtChar;
    property AbortOnError: Boolean read FAbortOnError write FAbortOnError;
    property XonLimit: Word read FXonLimit write FXonLimit;
    property XoffLimit: Word read FXoffLimit write FXoffLimit;
  end;

function BaudRateToInt(Value: TBaudRate): Integer;
function IntToBaudRate(Value: Integer): TBaudRate;

implementation

uses uEquipmentErrors;

function BaudRateToInt(Value: TBaudRate): Integer;
begin
  case Value of
    br110:
      Result := CBR_110;
    br300:
      Result := CBR_300;
    br600:
      Result := CBR_600;
    br1200:
      Result := CBR_1200;
    br2400:
      Result := CBR_2400;
    br4800:
      Result := CBR_4800;
    br9600:
      Result := CBR_9600;
    br14400:
      Result := CBR_14400;
    br19200:
      Result := CBR_19200;
    br38400:
      Result := CBR_38400;
    br56000:
      Result := CBR_56000;
    br57600:
      Result := CBR_57600;
    br115200:
      Result := CBR_115200;
  else
    Result := 0;
  end;
end;

function IntToBaudRate(Value: Integer): TBaudRate;
begin
  case Value of
    CBR_110:
      Result := br110;
    CBR_300:
      Result := br300;
    CBR_600:
      Result := br600;
    CBR_1200:
      Result := br1200;
    CBR_2400:
      Result := br2400;
    CBR_4800:
      Result := br4800;
    CBR_9600:
      Result := br9600;
    CBR_14400:
      Result := br14400;
    CBR_19200:
      Result := br19200;
    CBR_38400:
      Result := br38400;
    CBR_56000:
      Result := br56000;
    CBR_57600:
      Result := br57600;
    CBR_115200:
      Result := br115200;
  else
    Result := br9600;
  end;
end;

{ TComm }

constructor TComm.Create;
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FOverlappedMode := False;
  FEvtChar := #0;

  // Ќастройки порта по умолчанию
  FPortNumber := 1;
  FBaudRate := br9600;
  FParity := prNone;
  FDataBits := 8;
  FStopBits := sbOneStopBit;

  // SERIAL_ERROR_ABORT	Abort a transmit or receive operation if an error occurs
  FAbortOnError := False;
  FXonLimit := 256;
  FXoffLimit := 256;

  with FFlowControl do
  begin
    FOutCtsFlow := False;
    FOutDsrFlow := False;
    FControlDtr := dtrDisable;
    FControlRts := rtsDisable;
    FXonXoffOut := False;
    FXonXoffIn := False;
  end;

  // таймауты по умолчанию
  FTimeouts.ReadIntervalTimeout := 100;
  FTimeouts.ReadTotalTimeoutConstant := 100;
  FTimeouts.ReadTotalTimeoutMultiplier := 0;
  FTimeouts.WriteTotalTimeoutMultiplier := 50;
  FTimeouts.WriteTotalTimeoutConstant := 100;

  FDCBFlags := dcb_Binary;

  FEndSymbol := '';
  FReadAfterEndSymbol := 0;
end;

destructor TComm.Destroy;
begin
  Close;

  inherited Destroy;
end;

// function TComm.ClearResult: Boolean;
// begin
// Result := True;
/// /  ResultCode := S_OK;
// ExtResultDescription := '';
// end;

procedure TComm.SetWin32Error;
begin
  // ResultCode := ERR_Unknown;
  ExtResultDescription := SysErrorMessage(GetLastError);
end;

procedure TComm.StopEventWaiting;
begin
  if FOverlappedMode then
  begin
    SetCommMask(FHandle, 0);
    if FReadOverlapped.hEvent <> INVALID_HANDLE_VALUE then
    begin
      CloseHandle(FReadOverlapped.hEvent);
      FReadOverlapped.hEvent := INVALID_HANDLE_VALUE;
    end;
    if FWriteOverlapped.hEvent <> INVALID_HANDLE_VALUE then
    begin
      CloseHandle(FWriteOverlapped.hEvent);
      FWriteOverlapped.hEvent := INVALID_HANDLE_VALUE;
    end;
  end;
end;

function TComm.GetBaudRateAsInt: Integer;
begin
  case FBaudRate of
    br110:
      Result := CBR_110;
    br300:
      Result := CBR_300;
    br600:
      Result := CBR_600;
    br1200:
      Result := CBR_1200;
    br2400:
      Result := CBR_2400;
    br4800:
      Result := CBR_4800;
    br9600:
      Result := CBR_9600;
    br14400:
      Result := CBR_14400;
    br19200:
      Result := CBR_19200;
    br38400:
      Result := CBR_38400;
    br56000:
      Result := CBR_56000;
    br57600:
      Result := CBR_57600;
    br115200:
      Result := CBR_115200;
  else
    Result := 0;
  end;
end;

function TComm.GetCommErrors(out Errors: Cardinal): Boolean;
var
  CommStat: TComStat;
begin
  Result :=  GetCommStatus(Errors, CommStat);
end;

function TComm.GetCommStatus(out Errors: Cardinal;
  out CommStat: TComStat): Boolean;
begin
  ZeroMemory(@CommStat, SizeOf(TComStat));
  Result := ClearCommError(FHandle, Errors, @CommStat);
  if not Result then
    SetWin32Error;
end;

function TComm.GetCommStatus(out CommStat: TComStat): Boolean;
var
  Errors: Cardinal;
begin
  Result := GetCommStatus(Errors, CommStat);
end;

function TComm.GetDSR: Boolean;
var
  ModemStat: Cardinal;
begin
  Result := False;
  if GetCommModemStatus(FHandle, ModemStat) then
    Result := (ModemStat and MS_DSR_ON) <> 0
end;

function TComm.GetOpened: Boolean;
begin
  Result := FHandle <> INVALID_HANDLE_VALUE;
end;

function TComm.GetReadBufLen: Cardinal;
var
  ComStat: TComStat;
begin
  Result := 0;
  if GetCommStatus(ComStat) then
    Result := ComStat.cbInQue;
end;

function TComm.GetWriteBufLen: Cardinal;
var
  ComStat: TComStat;
begin
  Result := 0;
  if GetCommStatus(ComStat) then
    Result := ComStat.cbOutQue;
end;

function TComm.iReadByte(var Value: Byte): Integer;
begin
  if ReadByte(Value) then
    Result := 0
  else
  begin
    Result := ERR_ReadingPort;
    ExtResultDescription := S_ERR_ReadingPort + '. ' +
      SysErrorMessage(GetLastError);
  end;
end;

function TComm.CreateHandle: Boolean;
var
  DeviceName: string;
  dwFlagsAndAttributes: DWORD;
begin
  if FOverlappedMode then
    dwFlagsAndAttributes := FILE_FLAG_OVERLAPPED
  else
    dwFlagsAndAttributes := 0;

  DeviceName := '\\.\COM' + IntToStr(PortNumber);
  FHandle := CreateFile(PCHAR(DeviceName), GENERIC_READ or GENERIC_WRITE, 0,
    nil, OPEN_EXISTING, dwFlagsAndAttributes, 0);

  Result := FHandle <> INVALID_HANDLE_VALUE;
  if not Result then
    ExtResultDescription := S_OpenPortError + '. ' +
      SysErrorMessage(GetLastError);
end;

function TComm.Open: Boolean;
begin
  // CorrectParams;

  // ClearResult;
  Result := True;
  if not Opened then
  begin
    Result := CreateHandle and SetupComm(FHandle, 32768, 32768) and Purge and
      UpdateDataControlBlock and UpdateTimeouts;

    if Result and FOverlappedMode then
    begin
      FillChar(FReadOverlapped, SizeOf(TOverlapped), 0);
      FillChar(FWriteOverlapped, SizeOf(TOverlapped), 0);
      // инициализируем структуру TOverlapped
      FReadOverlapped.hEvent := CreateEvent(nil, True, False, nil);
      FWriteOverlapped.hEvent := CreateEvent(nil, True, False, nil);
      SetMask;
    end;

    if not Result then
      SetWin32Error;
  end;
end;

function TComm.Close: Boolean;
begin
  Result := True;
  if Opened then
  begin
    StopEventWaiting;

    SetCommDTR(False);
    Purge;
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
end;

function TComm.CheckOpened: Boolean;
begin
  Result := Opened;
  if not Result then
    Result := Open;
end;

function TComm.WriteByte(Value: Byte): Boolean;
var
  WriteCount: DWORD;
begin
  Result := CheckOpened;

  if Result then
  begin
    Result := WriteFile(FHandle, Value, 1, WriteCount, nil);
    if not Result then
    begin
      SetWin32Error;
      Exit;
    end;
    Result := WriteCount = 1;
    if not Result then
      FExtResultDescription := S_WriteDataError;
  end;
end;

function TComm.WriteBytes(Buff: array of Byte): Boolean;
begin
  Result := WriteBytes(@Buff, Length(Buff));
end;

function TComm.WriteBytes(Buff: PByteArray; dwBuffSize: DWORD): Boolean;
var
  lpOverlapped: POverlapped;
  lpNumberOfBytesWritten: DWORD;
begin
  Result := False;
  if not Opened then
  begin
    FExtResultDescription := S_PortNotOpened;
    Exit;
  end;

  lpOverlapped := nil;

  if FOverlappedMode then
  begin
    lpOverlapped := @FWriteOverlapped;
  end;

  Result := WriteFile(FHandle, Buff[0], dwBuffSize, lpNumberOfBytesWritten,
    lpOverlapped);
  if not Result then
    Result := FOverlappedMode and (GetLastError = ERROR_IO_PENDING);

  if not Result then
  begin
    SetWin32Error;
    Exit;
  end;
end;

function TComm.WriteChar(Value: AnsiChar): Boolean;
begin
  Result := WriteByte(Ord(Value));
end;

function TComm.WriteStr(const Data: AnsiString; SleepTime: Integer = 0)
  : Boolean;
var
  WriteCount: Integer;
begin
  if Length(Data) = 0 then
  begin
    Result := True;
    Exit;
  end;

  Result := CheckOpened;

  if Result then
  begin
    Result := WriteFile(FHandle, Data[1], Length(Data), DWORD(WriteCount), nil);
    if not Result then
    begin
      SetWin32Error;
      Exit;
    end;
    Result := WriteCount = Length(Data);
    if not Result then
      FExtResultDescription := S_WriteDataError;

    if Result and (SleepTime > 0) then
      Sleep(SleepTime);
  end;
end;

function TComm.ReadStr(Count: DWORD; var Data: AnsiString;
  ControlLength: Boolean): Integer;
var
  ReadCount: DWORD;
begin
  SetLength(Data, Count);
  Result := ERR_Unknown;
  if ReadFile(FHandle, Data[1], Count, ReadCount, nil) then
  begin
    SetLength(Data, ReadCount);
    if (not ControlLength) or (ReadCount = Count) then
      Result := S_OK
  end
  else
    SetWin32Error;
end;

function TComm.RunCmd(const InData: AnsiString; out OutData: AnsiString;
  MaxLen: Integer; Timeout: Cardinal; CountAfterEnd: Byte): Integer;
var
  Answ: AnsiString;
  EndTime: Cardinal;
begin
  OutData := '';
  EndTime := GetTickCount + Timeout;

  Result := ERR_DeviceNoResponse;
  if not WriteStr(InData) then
    Exit;

  while GetTickCount < EndTime do
  begin
    ReadStr(MaxLen, Answ);
    if Length(Answ) > 0 then
    begin
      OutData := OutData + Answ;
      if Length(EndSymbol) > 0 then
      begin
        if (CountAfterEnd = 0) and (Pos(EndSymbol, Answ) > 0) then
          Break
        else if (Pos(EndSymbol, OutData) + CountAfterEnd) = Length(OutData) then
          Break;
      end;
    end;
    Sleep(10);
  end;

  if (MaxLen = 0) or (Length(OutData) > 0) then
    Result := S_OK;
end;

function TComm.ReadByte(var Value: Byte): Boolean;
var
  Count: DWORD;
begin
  Count := 0;

  Result := ReadFile(FHandle, Value, 1, Count, nil);
  if not Result then
    SetWin32Error
  else if Count = 0 then
  begin
    Result := False;
    FExtResultDescription := S_ERR_DeviceNoResponse;
  end;
end;

function TComm.ReadByte(var Value: Byte; Timeout: Cardinal): Boolean;
var
  EndTime: Cardinal;
begin
  Result := False;
  EndTime := GetTickCount + Timeout;
  while GetReadBufLen = 0 do
  begin
    if GetTickCount > EndTime then
    begin
      FExtResultDescription := S_ERR_ReadingPort;
      Exit;
    end;
    Sleep(5);
  end;
  Result := ReadByte(Value);
end;

{$IF CompilerVersion > 19}

function TComm.ReadBytes(var ABuff: TBytes; ACount: DWORD): Boolean;
var
  LCount: DWORD;
begin
  SetLength(ABuff, ACount);
  if ACount = 0 then
    Exit(True);

  Result := ReadFile(FHandle, ABuff[0], ACount, LCount, nil);

  if Result then
  begin
    Result := LCount = ACount;
    if not Result then
    begin
      if LCount = 0 then
        FExtResultDescription := S_ERR_DeviceNoResponse
      else
        FExtResultDescription := S_ERR_Protocol;
    end;
  end
  else
    SetWin32Error;
end;
{$IFEND}

function TComm.ReadBytes(Buff: PByteArray; dwBuffSize: DWORD; out dwRead: DWORD;
  Timeout: Cardinal): Boolean;
var
  _ComStat: TComStat; // состо€ние порта
  dwError: Cardinal;
  dwMask, nNumberOfBytesToRead: DWORD;
  dwMilliseconds: DWORD;
  lpOverlapped: POverlapped;
begin
  Result := False;
  if not Opened then
  begin
    FExtResultDescription := S_PortNotOpened;
    Exit;
  end;

  lpOverlapped := nil;

  if FOverlappedMode then
  begin
    lpOverlapped := @FReadOverlapped;

    if Timeout > 0 then
      dwMilliseconds := Timeout
    else
      dwMilliseconds := INFINITE;

    Result := WaitCommEvent(FHandle, dwMask, @FReadOverlapped);
    if not Result then
    begin
      Result := GetLastError = ERROR_IO_PENDING;
      if Result then
        WaitForSingleObject(FReadOverlapped.hEvent, dwMilliseconds);
    end;

    if not Result then
    begin
      SetWin32Error;
      Exit;
    end;
  end;

  ClearCommError(FHandle, dwError, @_ComStat); // считываем состо€ние порта
  nNumberOfBytesToRead := _ComStat.cbInQue;
  // считываем число байт дл€ чтени€ из структуры

  if nNumberOfBytesToRead = 0 then
  begin
    FExtResultDescription := S_BufferEmpty;
    Exit;
  end
  else if nNumberOfBytesToRead > dwBuffSize then
    nNumberOfBytesToRead := dwBuffSize;

  Result := ReadFile(FHandle, Buff[0], nNumberOfBytesToRead, dwRead,
    lpOverlapped);
  if not Result then
    SetWin32Error;
end;

function TComm.ReadBytes(Count: DWORD; var Buff: array of Byte): Boolean;
var
  ReadCount: DWORD;
begin
  Result := False;

  if ReadFile(FHandle, Buff[0], Count, ReadCount, nil) then
  begin
    Result := ReadCount = Count;
    if not Result then
      FExtResultDescription := S_ERR_Protocol;
  end
  else
    SetWin32Error;
end;

function TComm.ReadChar(out Ch: AnsiChar; Timeout: Cardinal): Boolean;
begin
  Result := ReadByte(Byte(Ch), Timeout);
end;

function TComm.ReadChar(var Value: AnsiChar): Boolean;
begin
  Result := ReadByte(Byte(Value));
end;

function TComm.ReadStr(out Data: AnsiString; EndSymb: AnsiChar;
  Timeout: Cardinal): Integer;
var
  EndTime, ReadCount: Cardinal;
  P: Integer;
  Buf: array [0 .. MAXBYTE] of AnsiChar;
begin
  Result := ERR_DeviceNoResponse;
  Data := '';
  EndTime := GetTickCount + Timeout;

  while GetTickCount <= EndTime do
  begin
    if ReadFile(FHandle, Buf[0], MAXBYTE, ReadCount, nil) and (ReadCount > 0)
    then
    begin
      Data := Data + AnsiString(Copy(Buf, 0, ReadCount));
      P := Pos(EndSymb, Data);
      if (P > 0) and (P = Length(Data)) then
      begin
        Result := 0;
        Exit;
      end;
    end;
    Sleep(5);
  end;

  if Length(Data) > 0 then
    Result := ERR_Protocol;
end;

function TComm.ReadStr(Count: DWORD; var Data: AnsiString;
  const EndSymb: AnsiString): Integer;
begin
  FEndSymbol := EndSymb;
  Result := ReadStr(Count, Data);
  if Result = S_OK then
    if not Pos(Data, EndSymb) > 0 then
      Result := ERR_Protocol;
end;

function TComm.UpdateTimeouts: Boolean;
begin
  Result := CheckOpened;
  if Result then
  begin
    Result := SetCommTimeOuts(FHandle, FTimeouts);
    if not Result then
      SetWin32Error;
  end;
end;

function TComm.UpdateDataControlBlock: Boolean;
var
  DCB: TDCB;
begin
  Result := True;
  if Opened then
  begin
    Result := GetCommState(FHandle, DCB);
    if Result then
    begin
      DCB.DCBlength := SizeOf(DCB);
      DCB.XonChar := #17;
      DCB.XoffChar := #19;
      DCB.XonLim := FXonLimit;
      DCB.XoffLim := FXoffLimit;

      DCB.Flags := dcb_Binary; // or dcb_Null;
      if FParity <> prNone then
        DCB.Flags := DCB.Flags or dcb_ParityCheck;

      if FAbortOnError then // SERIAL_ERROR_ABORT
        DCB.Flags := DCB.Flags or dcb_AbortOnError;

      with FFlowControl do
      begin
        if FOutCtsFlow then
          DCB.Flags := DCB.Flags or dcb_OutxCtsFlow;
        if FOutDsrFlow then
          DCB.Flags := DCB.Flags or dcb_OutxDsrFlow;
        case FControlDtr of
          dtrDisable:
            DCB.Flags := DCB.Flags or dcb_DtrControlDisable;
          dtrEnable:
            DCB.Flags := DCB.Flags or dcb_DtrControlEnable;
          dtrHandshake:
            DCB.Flags := DCB.Flags or dcb_DtrControlHandshake;
        end;
        case FControlRts of
          rtsDisable:
            DCB.Flags := DCB.Flags or dcb_RtsControlDisable;
          rtsEnable:
            DCB.Flags := DCB.Flags or dcb_RtsControlEnable;
          rtsHandshake:
            DCB.Flags := DCB.Flags or dcb_RtsControlHandshake;
          rtsToggle:
            DCB.Flags := DCB.Flags or dcb_RtsControlToggle;
        end;
        if FXonXoffOut then
          DCB.Flags := DCB.Flags or dcb_OutX;
        if FXonXoffIn then
          DCB.Flags := DCB.Flags or dcb_InX;
      end;

      case FParity of
        prNone:
          DCB.Parity := NOPARITY;
        prOdd:
          DCB.Parity := ODDPARITY;
        prEven:
          DCB.Parity := EVENPARITY;
        prMark:
          DCB.Parity := MARKPARITY;
        prSpace:
          DCB.Parity := SPACEPARITY;
      end;

      case FStopBits of
        sbOneStopBit:
          DCB.StopBits := ONESTOPBIT;
        sbOne5StopBits:
          DCB.StopBits := ONE5STOPBITS;
        sbTwoStopBits:
          DCB.StopBits := TWOSTOPBITS;
      end;

      case FBaudRate of
        br110:
          DCB.BaudRate := CBR_110;
        br300:
          DCB.BaudRate := CBR_300;
        br600:
          DCB.BaudRate := CBR_600;
        br1200:
          DCB.BaudRate := CBR_1200;
        br2400:
          DCB.BaudRate := CBR_2400;
        br4800:
          DCB.BaudRate := CBR_4800;
        br9600:
          DCB.BaudRate := CBR_9600;
        br14400:
          DCB.BaudRate := CBR_14400;
        br19200:
          DCB.BaudRate := CBR_19200;
        br38400:
          DCB.BaudRate := CBR_38400;
        br56000:
          DCB.BaudRate := CBR_56000;
        br57600:
          DCB.BaudRate := CBR_57600;
        br115200:
          DCB.BaudRate := CBR_115200;
      end;

      DCB.EvtChar := FEvtChar;

      DCB.ByteSize := FDataBits;
      Result := SetCommState(FHandle, DCB);
    end;
    if not Result then
      SetWin32Error;
  end;
end;

function TComm.SendCmd(const Data: AnsiString): Integer;
begin
  if WriteStr(Data) then
    Result := S_OK
  else
    Result := ERR_Unknown;
end;

procedure TComm.SetBaudRate(Value: TBaudRate);
begin
  if Value <> BaudRate then
  begin
    FBaudRate := Value;
    UpdateDataControlBlock;
  end;
end;

procedure TComm.SetBaudRateAsInt(Value: Integer);
begin
  case Value of
    CBR_110:
      FBaudRate := br110;
    CBR_300:
      FBaudRate := br300;
    CBR_600:
      FBaudRate := br600;
    CBR_1200:
      FBaudRate := br1200;
    CBR_2400:
      FBaudRate := br2400;
    CBR_4800:
      FBaudRate := br4800;
    CBR_9600:
      FBaudRate := br9600;
    CBR_14400:
      FBaudRate := br14400;
    CBR_19200:
      FBaudRate := br19200;
    CBR_38400:
      FBaudRate := br38400;
    CBR_56000:
      FBaudRate := br56000;
    CBR_57600:
      FBaudRate := br57600;
    CBR_115200:
      FBaudRate := br115200;
  end;
end;

procedure TComm.SetCommDTR(Value: Boolean);
var
  DTRLevel: Cardinal;
begin
  if not CheckOpened then
    Exit;

  if Value then
    DTRLevel := SETDTR
  else
    DTRLevel := CLRDTR;

  EscapeCommFunction(Handle, DTRLevel);
end;

procedure TComm.SetCommRTS(Value: Boolean);
var
  RTSLevel: Cardinal;
begin
  if not CheckOpened then
    Exit;

  if Value then
    RTSLevel := SETRTS
  else
    RTSLevel := CLRRTS;

  EscapeCommFunction(Handle, RTSLevel);
end;

procedure TComm.SetEvtChar(const Value: AnsiChar);
begin
  FEvtChar := Value;
  if not Opened then
    Exit;

  // SetMask;
end;

procedure TComm.SetMask;
begin
  if FEvtChar = #0 then
    SetCommMask(Handle, EV_RXCHAR) // любой байт
  else
    SetCommMask(Handle, EV_RXFLAG);
end;

procedure TComm.SetTimeouts(const Value: TCommTimeouts);
begin
  FTimeouts := Value;
  UpdateTimeouts;
end;

function TComm.Purge(Abort: Boolean): Boolean;
var
  Flags: DWORD;
begin
  Result := CheckOpened;
  if Result then
  begin
    Flags := PURGE_RXCLEAR or PURGE_TXCLEAR;
    if Abort then
      Flags := Flags or PURGE_RXABORT + PURGE_TXABORT;
    Result := PurgeComm(Handle, Flags);
    if not Result then
      SetWin32Error;
  end;
end;

function TComm.RunCmd(const InData: AnsiString; out OutData: AnsiString;
  const EndSymb: AnsiString; MaxLen, Timeout: Integer;
  CountAfterEnd: Byte): Integer;
begin
  FEndSymbol := EndSymb;
  Result := RunCmd(InData, OutData, MaxLen, Timeout, CountAfterEnd);
  if Result = S_OK then
    if not(Pos(EndSymb, OutData) > 0) then
      Result := ERR_Protocol;
end;

function TComm.ReadStr(out Data: AnsiString; Timeout: Cardinal): Integer;
var
  EndTime, ReadCount: Cardinal;
  Buf: array [0 .. MAXBYTE] of AnsiChar;
  ComStat: TComStat;
  Errors: Cardinal;
begin
  Result := ERR_DeviceNoResponse;
  Data := '';
  EndTime := GetTickCount + Timeout;

  while GetTickCount <= EndTime do
  begin
    if ClearCommError(FHandle, Errors, @ComStat) then
    begin
      if ComStat.cbInQue > 0 then
      begin
        if ReadFile(FHandle, Buf[0], MAXBYTE, ReadCount, nil) and (ReadCount > 0)
        then
        begin
          SetLength(Data, ReadCount);
          Move(Buf[0], Data[1], ReadCount);
          Result := 0;
          Exit;
        end;
      end;
    end;
    Sleep(5);
  end;
end;

function TComm.ReadString(out Buff: AnsiString; Timeout: Cardinal): Boolean;
var
  ReadCount: DWORD;
  _ComStat: TComStat; // состо€ние порта
  dwError: Cardinal;
  dwRead, dwMask: DWORD;
  dwMilliseconds: DWORD;
begin
  Result := False;

  if FOverlappedMode then
  begin
    if Timeout > 0 then
      dwMilliseconds := Timeout
    else
      dwMilliseconds := INFINITE;

    Result := WaitCommEvent(FHandle, dwMask, @FReadOverlapped);
    if not Result then
    begin
      Result := GetLastError = ERROR_IO_PENDING;
      if Result then
        WaitForSingleObject(FReadOverlapped.hEvent, dwMilliseconds);
    end;

    if not Result then
    begin
      SetWin32Error;
      Exit;
    end;
  end;

  ClearCommError(FHandle, dwError, @_ComStat); // считываем состо€ние порта
  dwRead := _ComStat.cbInQue; // считываем число байт дл€ чтени€ из структуры

  if dwRead = 0 then
  begin
    FExtResultDescription := S_BufferEmpty;
    Exit;
  end;

  SetLength(Buff, dwRead);

  Result := ReadFile(FHandle, Buff[1], dwRead, ReadCount, @FReadOverlapped);
  if Result and (ReadCount < dwRead) then
    SetLength(Buff, ReadCount);

  if not Result then
    SetWin32Error;
end;

function TComm.ReadString(Count: DWORD; out Buff: AnsiString): Boolean;
var
  ReadCount: DWORD;
begin
  SetLength(Buff, Count);

  Result := ReadFile(FHandle, Buff[1], Count, ReadCount, nil);
  SetLength(Buff, ReadCount);
  if not Result then
    SetWin32Error;
end;

end.
