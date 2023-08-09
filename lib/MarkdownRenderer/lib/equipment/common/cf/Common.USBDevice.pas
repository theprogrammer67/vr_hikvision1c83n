unit Common.USBDevice;

interface

uses Winapi.Windows, JvSetupApi, Hid, System.SysUtils;

type
  TOnLogging = procedure(const Caption, Msg: string) of object;

  TUSBDevice = class
  private
    FHandle: THandle;
    FProductName: string;
    FVendorName: string;

    FVid, FPid: Integer;

    FOnLogging: TOnLogging;
    FCapabilities: HIDP_CAPS;
    procedure GetDeviceCapabilities;
    function GetProductName: string;
    function GetVendorName: string;
  protected
    FLastErrorDescription: string;
    procedure Logging(const Caption, Msg: string);
    procedure SetLastError;
    function Open(Ind: UInt32; out Count: Integer; GetCount: Boolean)
      : Boolean; overload;
  public
    constructor Create;
    destructor Destroy; override;

    function Open(Ind: Integer): Boolean; overload;
    function GetDevicesCount: Integer;
    function ReadData(Data: PByteArray): Boolean;
    function WriteData(Data: PByteArray): Boolean;
    function SetFeature(Data: PByteArray): Boolean;
    procedure Close;

    property ProductName: string read GetProductName;
    property VendorName: string read GetVendorName;

    property LastErrorDescription: string read FLastErrorDescription;
    property OnLogging: TOnLogging read FOnLogging write FOnLogging;

    property VID: Integer read FVid write FVid;
    property PID: Integer read FPid write FPid;
  end;

const
  T1: Cardinal = 15000;
  T2: Cardinal = 2000;

resourcestring
  ERR_DeviceNotFound = 'Устройство не подключено';
  ERR_WriteUnknown = 'Неизвестная ошибка при записи данных';
  ERR_ReadUnknown = 'Неизвестная ошибка при чтении данных';
  // ERR_Unknown = 'Неизвестная ошибка';

implementation

function BytesToHex(Data: PByteArray; Size: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Size - 1 do
  begin
    if Length(Result) > 0 then
      Result := Result + ' ';
    Result := Result + IntToHex(Data[I], 2);
  end;
end;

{ TOmronUSBDev }

procedure TUSBDevice.GetDeviceCapabilities;
var
  PreparsedData: PHIDPPreparsedData;
begin
  HidD_GetPreparsedData(FHandle, PreparsedData);
  HidP_GetCaps(PreparsedData, FCapabilities);
  HidD_FreePreparsedData(PreparsedData);
end;

function TUSBDevice.GetDevicesCount: Integer;
var
  DevCount: Integer;
begin
  Open(0, DevCount, True);
  Result := DevCount;
end;

function TUSBDevice.GetProductName: string;
var
  Buffer: array [0 .. 253] of WideChar;
begin
  if FProductName = '' then
  begin
    if FHandle = INVALID_HANDLE_VALUE then
      Exit('');

    FillChar(Buffer, SizeOf(Buffer), #0);
    if HidD_GetProductString(FHandle, Buffer, SizeOf(Buffer)) then
      FProductName := Buffer;
  end;
  Result := FProductName;
end;

function TUSBDevice.GetVendorName: string;
var
  Buffer: array [0 .. 253] of WideChar;
begin
  if FVendorName = '' then
  begin
    if FHandle = INVALID_HANDLE_VALUE then
      Exit('');

    FillChar(Buffer, SizeOf(Buffer), #0);
    if HidD_GetManufacturerString(FHandle, Buffer, SizeOf(Buffer)) then
      FVendorName := Buffer;
  end;
  Result := FVendorName;
end;

procedure TUSBDevice.Logging(const Caption, Msg: string);
begin
  if Assigned(FOnLogging) then
    FOnLogging(Caption, Msg);
end;

function TUSBDevice.Open(Ind: Integer): Boolean;
var
  DevCount: Integer;
begin
  FLastErrorDescription := '';
  FProductName := '';
  FVendorName := '';

  Result := Open(Ind, DevCount, False);
  if not Result then
    FLastErrorDescription := ERR_DeviceNotFound
  else
end;

function TUSBDevice.ReadData(Data: PByteArray): Boolean;
var
  BytesRead: DWORD;
  Buf: array [0 .. 8] of Byte;
  hEventObject: THandle;
  HIDOverlapped: TOverlapped;
begin
  FLastErrorDescription := '';
  Result := FHandle <> INVALID_HANDLE_VALUE;

  if Result then
  begin
    hEventObject := CreateEvent(nil, False, True, '');
    HIDOverlapped.hEvent := hEventObject;
    HIDOverlapped.Offset := 0;
    HIDOverlapped.OffsetHigh := 0;

    Logging('ReadFile', 'Begin');
    Result := ReadFile(FHandle, Buf, FCapabilities.InputReportByteLength,
      BytesRead, @HIDOverlapped);
    if GetLastError = Error_IO_Pending then
    begin
      if WaitForSingleObject(HIDOverlapped.hEvent, T2) = WAIT_OBJECT_0 then
      begin
        Result := GetOverlappedResult(FHandle, HIDOverlapped, BytesRead, False);
        if not Result then
          SetLastError;
      end
      else
      begin
        SetLastError;
        CancelIo(FHandle);
      end;
    end
    else
      SetLastError;

    CloseHandle(HIDOverlapped.hEvent);
    Logging('ReadFile', 'End: '#9 + BytesToHex(@Buf, SizeOf(Buf)));

    if Result then
      MoveMemory(Data, @Buf[1], 8);
    if (not Result) and (Length(FLastErrorDescription) = 0) then
      FLastErrorDescription := ERR_ReadUnknown;
  end
  else
    FLastErrorDescription := ERR_DeviceNotFound;
end;

function TUSBDevice.SetFeature(Data: PByteArray): Boolean;
begin
  FLastErrorDescription := '';
  Result := FHandle <> INVALID_HANDLE_VALUE;

  if Result then
  begin
    Logging('HidD_SetFeature', 'Begin: '#9 + BytesToHex(Data,
      FCapabilities.FeatureReportByteLength));
    Result := HidD_SetFeature(FHandle, Data^,
      FCapabilities.FeatureReportByteLength);
    Logging('HidD_SetFeature', 'End');

    if not Result then
      SetLastError;
  end
  else
    FLastErrorDescription := ERR_DeviceNotFound;
end;

procedure TUSBDevice.SetLastError;
begin
  FLastErrorDescription := SysErrorMessage(GetLastError);
end;

function TUSBDevice.WriteData(Data: PByteArray): Boolean;
var
  BytesWritten: DWORD;
  Buf: array [0 .. 8] of Byte;
  hEventObject: THandle;
  HIDOverlapped: TOverlapped;
begin
  FLastErrorDescription := '';
  Result := FHandle <> INVALID_HANDLE_VALUE;

  if Result then
  begin
    Buf[0] := $00;
    MoveMemory(@Buf[1], Data, 8);

    hEventObject := CreateEvent(nil, False, True, '');
    HIDOverlapped.hEvent := hEventObject;
    HIDOverlapped.Offset := 0;
    HIDOverlapped.OffsetHigh := 0;

    Logging('WriteFile', 'Begin: '#9 + BytesToHex(@Buf, SizeOf(Buf)));
    Result := WriteFile(FHandle, Buf, FCapabilities.OutputReportByteLength,
      BytesWritten, @HIDOverlapped);

    if not Result then
    begin
      if GetLastError = Error_IO_Pending then
      begin
        if WaitForSingleObject(HIDOverlapped.hEvent, T2) = WAIT_OBJECT_0 then
        begin
          Result := GetOverlappedResult(FHandle, HIDOverlapped,
            BytesWritten, False);
          if not Result then
            SetLastError;
        end
        else
        begin
          SetLastError;
          CancelIo(FHandle);
        end;
      end
      else
        SetLastError;
    end;

    CloseHandle(HIDOverlapped.hEvent);
    Logging('WriteFile', 'End');

    if (not Result) and (Length(FLastErrorDescription) = 0) then
      FLastErrorDescription := ERR_WriteUnknown;
  end
  else
    FLastErrorDescription := ERR_DeviceNotFound;
end;

procedure TUSBDevice.Close;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
end;

constructor TUSBDevice.Create;
begin
  FHandle := INVALID_HANDLE_VALUE;
  FProductName := '';
  FVendorName := '';
  FVid := 0;
  FPid := 0;
end;

destructor TUSBDevice.Destroy;
begin
  Close;
  inherited;
end;

function TUSBDevice.Open(Ind: UInt32; out Count: Integer;
  GetCount: Boolean): Boolean;
var
  Attributes: HIDD_ATTRIBUTES;
  devInfoData: SP_DEVICE_INTERFACE_DATA;
  LastDevice: Boolean;
  MemberIndex: Integer;
  HidGuid: TGUID;
  DevInfo: HDEVINFO;
  Len: DWORD;
  detailData: PSPDeviceInterfaceDetailData;
  Required: DWORD;
  MyDeviceDetected: Boolean;
  MyDevicePathName: string;
begin
  LastDevice := False;
  MemberIndex := 0;
  Count := 0;
  MyDeviceDetected := False;

  HidD_GetHidGuid(HidGuid);
  DevInfo := SetupDiGetClassDevs(@HidGuid, nil, 0, DIGCF_PRESENT or
    DIGCF_INTERFACEDEVICE);

  devInfoData.cbSize := SizeOf(devInfoData);

  repeat
    Result := SetupDiEnumDeviceInterfaces(DevInfo, nil, HidGuid, MemberIndex,
      devInfoData);

    if Result then
    begin
      SetupDiGetDeviceInterfaceDetail(DevInfo, @devInfoData, nil, 0, Len, nil);
      if (Len <> 0) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) then
      begin
        detailData := AllocMem(Len);
        detailData.cbSize := SizeOf(SP_DEVICE_INTERFACE_DETAIL_DATA);
      end
      else
      begin
        SetLastError;
        Exit(False);
      end;

      try
        if not SetupDiGetDeviceInterfaceDetail(DevInfo, @devInfoData,
          detailData, Len, Required, nil) then
        begin
          SetLastError;
          Exit(False);
        end;

        FHandle := CreateFile(detailData.DevicePath, GENERIC_READ or
          GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
          OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);

        ZeroMemory(@Attributes,SizeOf(Attributes));
        Attributes.Size := SizeOf(Attributes);
        HidD_GetAttributes(FHandle, Attributes);
        MyDeviceDetected := False;

        if (Attributes.VendorID = FVid) and (Attributes.ProductID = FPid) then
        begin
          if GetCount then
          begin
            Inc(Count);
            Close;
          end
          else
          begin
            MyDeviceDetected := True;
            MyDevicePathName := StrPas(PChar(@detailData.DevicePath));
            GetDeviceCapabilities;
            Break;
          end;
        end
        else
        begin
          Close;
        end;
      finally
        FreeMem(detailData);
      end;
    end
    else
      LastDevice := True;

    Inc(MemberIndex);
  until LastDevice;

  SetupDiDestroyDeviceInfoList(DevInfo);

  if GetCount then
    Result := Count > 0
  else
    Result := MyDeviceDetected;

  if not Result then
    FLastErrorDescription := ERR_DeviceNotFound;
end;

initialization

LoadHid;
LoadSetupApi;

finalization

UnloadSetupApi;
UnloadHid;

end.
