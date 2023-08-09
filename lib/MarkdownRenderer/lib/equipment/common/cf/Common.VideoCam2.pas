unit Common.VideoCam2;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, Winapi.DirectShow9,
  Winapi.ActiveX, Vcl.Controls, Vcl.Graphics, Winapi.Messages;

const
  { Filter Graph message identifier. }
  WM_GRAPHNOTIFY = WM_APP + 1;
  RunningMutexName = '{45426824-AEB7-4037-804B-2770CB35D9A3}';

type
  TOnDSEvent = procedure(Event, Param1, Param2: Integer) of object;

  // DirectShow Exception class
  EDirectShowException = class(Exception)
    ErrorCode: Integer;
  end;

  TWorkMode = (wmPreview, wmRecord, wmPreviewAndRecord);
  TFiltersProc = procedure(AVideoInputFilter, AVideoCompressFilter: IBaseFilter)
    of object;

  TVideoCam = class
  private
    FRunningMutex: THandle; // Видеозахват запущен
    FHandle: THandle; // to capture events
    // All Events Code
    FOnDSEvent: TOnDSEvent;

    FMediaControl: IMediaControl;
    FSampleGrabber: ISampleGrabber;
    FVideoInputFilter: IBaseFilter;
    FVideoCompressFilter: IBaseFilter;

    FGraphEditID: Integer;

    FVideoInputDisplayName: string;
    FVideoCompressDisplayName: string;
    FWorkMode: TWorkMode;
    FCaptureFileName: string;
    FUseVMR: Boolean;
    FHideVideoWindow: Boolean;
    FWindowAspectRatio: Double;
    FLastErrorCode: Integer;
    FOnBeforeStop: TFiltersProc;
  private
    procedure SetPreviewWnd(const Value: TWinControl);
    function CheckState(AState: TFilterState): Boolean;
    function GetRunning: Boolean;
    function GetPaused: Boolean;
    procedure HandleEvents;
    procedure WndProc(var Msg: TMessage);
    procedure DoEvent(Event, Param1, Param2: Integer);
    function SaveError(AExceptObject: TObject): Boolean;
    function CheckRunning: Boolean;
    procedure GetVideoCaptureDeviceResolution(ACaptureGraphBuilder
      : ICaptureGraphBuilder2; AVideoInputFilter: IBaseFilter;
      out AWidth, AHeight: Integer); overload;
    procedure SetWindowsAspectRatio;
  protected
    FOnBeforeStart: TFiltersProc;

    FLastErrorDescription: string;
    FPreviewWnd: TWinControl;

    FVideoWindow: IVideoWindow;
    FVMRMixerBitmap: IVMRMixerBitmap9;
    FGraphBuilder: IGraphBuilder;
    FCaptureGraphBuilder: ICaptureGraphBuilder2;
    FMediaEventEx: IMediaEventEx;

    function GetFilter(const DisplayName: string; BindCtx: IBindCtx)
      : IBaseFilter;
    function GetVideoCompressorFilter(BindCtx: IBindCtx): IBaseFilter;
    function GetVideoInputFilter(BindCtx: IBindCtx): IBaseFilter;
  public
    constructor Create;
    destructor Destroy; override;
  public
    function CheckVideoInput: Boolean;
    function Start: Boolean;
    procedure Stop;
    procedure Pause;
  public
    { This method read the buffer received in the OnBuffer event and paint the bitmap. }
    function GetBitmap(Bitmap: TBitmap; Buffer: Pointer; BufferLen: Integer)
      : Boolean; overload;
    { This method read the current buffer from the Sample Grabber Filter and paint the bitmap. }
    function GetBitmap(Bitmap: TBitmap): Boolean; overload;
    procedure UpdateVideoWindow;
    procedure GetVideoCaptureDeviceResolution(out AWidth,
      AHeight: Integer); overload;
  public
    property VMRMixerBitmap: IVMRMixerBitmap9 read FVMRMixerBitmap;
    property LastErrorDescription: string read FLastErrorDescription
      write FLastErrorDescription;
    property LastErrorCode: Integer read FLastErrorCode write FLastErrorCode;
    property VideoInputDisplayName: string read FVideoInputDisplayName
      write FVideoInputDisplayName;
    property VideoCompressDisplayName: string read FVideoCompressDisplayName
      write FVideoCompressDisplayName;
    property WorkMode: TWorkMode read FWorkMode write FWorkMode;
    property PreviewWnd: TWinControl read FPreviewWnd write SetPreviewWnd;
    property CaptureFileName: string read FCaptureFileName
      write FCaptureFileName;
    property UseVMR: Boolean read FUseVMR write FUseVMR;
    property Running: Boolean read GetRunning;
    property Paused: Boolean read GetPaused;
    property WindowAspectRatio: Double read FWindowAspectRatio;
    property HideVideoWindow: Boolean read FHideVideoWindow
      write FHideVideoWindow;
    property OnDSEvent: TOnDSEvent read FOnDSEvent write FOnDSEvent;
    property OnBeforeStart: TFiltersProc read FOnBeforeStart
      write FOnBeforeStart;
    property OnBeforeStop: TFiltersProc read FOnBeforeStop write FOnBeforeStop;
  end;

function CheckDSError(hr: HRESULT): HRESULT;

resourcestring
  rsWinidowNotDefined = 'Окно просмотра не задано';
  rsFileNameEmpty = 'Имя файла для записи не задано';
  rsGrabberNotFond = 'Фильтр граббинга не найден';
  rsBitmapNotAssigned = 'Не задан bitmap';
  rsBufferError = 'Нулевой размер буфера';
  rsMediaTypeError = 'Неверный тип медиаданных';
  rsUnsupportedFormat = 'Формат не поддерживается';
  rsDIBPtrError = 'DIBPtr не определен';
  rsAnotherProgrammRunning = 'Видеозахват уже используется другим приложением';

implementation

uses System.Win.ComObj, Winapi.MMSystem;

// ----------------------------------------------------------------------------
// Enable Graphedit to connect with your filter graph
// ----------------------------------------------------------------------------
function AddGraphToRot(Graph: IFilterGraph; out ID: Integer): HRESULT;
var
  Moniker: IMoniker;
  ROT: IRunningObjectTable;
  wsz: UnicodeString;
  // martin begin
{$IFDEF FPC}
  lwID: DWORD;
{$ENDIF}
  // martin end
begin
  result := GetRunningObjectTable(0, ROT);
  if (result <> S_OK) then
    exit;
  wsz := format('FilterGraph %p pid %x',
    [Pointer(Graph), GetCurrentProcessId()]);
  result := CreateItemMoniker('!', PWideChar(wsz), Moniker);
  if (result <> S_OK) then
    exit;
{$IFDEF FPC}
  // martin begin - fpc qnat a uint (DWORD) as ID
  result := ROT.Register(0, Graph, Moniker, lwID);
  ID := Integer(lwID);
  // martin end
{$ELSE}
  result := ROT.Register(0, Graph, Moniker, ID);
{$ENDIF}
  Moniker := nil;
end;

function RemoveGraphFromRot(ID: Integer): HRESULT;
var
  ROT: IRunningObjectTable;
begin
  result := GetRunningObjectTable(0, ROT);
  if (result <> S_OK) then
    exit;
  result := ROT.Revoke(ID);
  ROT := nil;
end;

function GetDIBLineSize(BitCount, Width: Integer): Integer;
begin
  if BitCount = 15 then
    BitCount := 16;
  result := ((BitCount * Width + 31) div 32) * 4;
end;

procedure FreeMediaType(mt: PAMMediaType);
begin
  if (mt^.cbFormat <> 0) then
  begin
    CoTaskMemFree(mt^.pbFormat);
    // Strictly unnecessary but tidier
    mt^.cbFormat := 0;
    mt^.pbFormat := nil;
  end;
  if (mt^.pUnk <> nil) then
    mt^.pUnk := nil;
end;

function GetErrorString(hr: HRESULT): string;
var
  Buffer: array [0 .. 254] of char;
begin
  AMGetErrorText(hr, @Buffer, 255);
  result := Buffer;
end;

function CheckDSError(hr: HRESULT): HRESULT;
var
  Excep: EDirectShowException;
begin
  result := hr;
  if Failed(hr) then
  begin
    Excep := EDirectShowException.Create
      (format(GetErrorString(hr) + ' ($%x).', [hr]));
    Excep.ErrorCode := hr;
    raise Excep;
  end;
end;

{ TVideoCam }

function TVideoCam.CheckRunning: Boolean;
begin
  // FRunningMutex := CreateMutex(nil, True, RunningMutexName);
  // if GetLastError = ERROR_ALREADY_EXISTS then
  // begin
  // ReleaseMutex(FRunningMutex);
  // FLastErrorDescription := rsAnotherProgrammRunning;
  // exit(False);
  // end;

  exit(True);
end;

function TVideoCam.CheckState(AState: TFilterState): Boolean;
var
  pfs: TFilterState;
begin
  result := False;
  if FMediaControl = nil then
    exit;

  if FMediaControl.GetState(5000, pfs) <> 0 then
    exit;

  result := pfs = AState;
end;

function TVideoCam.CheckVideoInput: Boolean;
var
  VideoInputFilter: IBaseFilter;
  BindCtx: IBindCtx;
begin
  result := True;
  try
    OleCheck(CreateBindCtx(0, BindCtx));
    // Создаем фильтр видеокамеры
    VideoInputFilter := GetVideoInputFilter(BindCtx);
  except
    result := SaveError(ExceptObject);
  end;
end;

constructor TVideoCam.Create;
begin
  FRunningMutex := INVALID_HANDLE_VALUE;
  FHandle := AllocateHWnd(WndProc);
  FLastErrorCode := 0;
  FLastErrorDescription := '';
  FVideoInputDisplayName := '';
  FVideoCompressDisplayName := '';
  FCaptureFileName := '';
  FWorkMode := wmPreview;
  FMediaControl := nil;
  FGraphEditID := 0;
  FUseVMR := True;
  FWindowAspectRatio := 0;
  FHideVideoWindow := False;
  CoInitialize(nil); // инициализировать OLE COM
  Stop;
end;

function TVideoCam.SaveError(AExceptObject: TObject): Boolean;
begin
  if AExceptObject is EDirectShowException then
    FLastErrorCode := EDirectShowException(AExceptObject).ErrorCode
  else
    FLastErrorCode := -1;
  FLastErrorDescription := Exception(AExceptObject).Message;
  result := False;
end;

procedure TVideoCam.SetPreviewWnd(const Value: TWinControl);
begin
  FPreviewWnd := Value;
end;

procedure TVideoCam.SetWindowsAspectRatio;
var
  LWidth, LHeight: Integer;
begin
  // CheckDSError(FVideoWindow.GetMaxIdealImageSize(LWidth, LHeight));

  GetVideoCaptureDeviceResolution(FCaptureGraphBuilder, FVideoInputFilter,
    LWidth, LHeight);

  if (LHeight <> 0) and (LWidth <> 0) then
    FWindowAspectRatio := LWidth / LHeight
  else
    FWindowAspectRatio := 0;
end;

function TVideoCam.Start: Boolean;
var
  Mux: IBaseFilter;
  Sink: IFileSinkFilter;
  SampleGrabberFilter: IBaseFilter;
  VMRFilter: IBaseFilter;
  MediaType: AM_MEDIA_TYPE;
  BindCtx: IBindCtx;
  VMRFilterConfig: IVMRFilterConfig;
begin
  FLastErrorDescription := '';
  result := True;
  Stop;

  try
    // Проверим, не запущен ли другой экземаляр?
    if not CheckRunning then
      exit(False);

    // Создаем объект для графа фильтров
    OleCheck(CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER,
      IID_IGraphBuilder, FGraphBuilder));
    AddGraphToRot(IFilterGraph(FGraphBuilder), FGraphEditID);
    // Создаем объект для графа захвата
    OleCheck(CoCreateInstance(CLSID_CaptureGraphBuilder2, nil,
      CLSCTX_INPROC_SERVER, IID_ICaptureGraphBuilder2, FCaptureGraphBuilder));
    // Задаем граф фильтров
    CheckDSError(FCaptureGraphBuilder.SetFiltergraph(FGraphBuilder));

    // События
    OleCheck(FGraphBuilder.QueryInterface(IMediaEventEx, FMediaEventEx));
    FMediaEventEx.SetNotifyFlags(0); // enable events notification
    FMediaEventEx.SetNotifyWindow(FHandle, WM_GRAPHNOTIFY,
      ULONG(FMediaEventEx));

    OleCheck(CreateBindCtx(0, BindCtx));
    // Создаем фильтр видеокамеры
    FVideoInputFilter := GetVideoInputFilter(BindCtx);
    CheckDSError(FGraphBuilder.AddFilter(FVideoInputFilter,
      'VideoInputFilter'));
    // Создаем фильтр компрессора
    if FWorkMode in [wmRecord, wmPreviewAndRecord] then
    begin
      FVideoCompressFilter := GetVideoCompressorFilter(BindCtx);
      CheckDSError(FGraphBuilder.AddFilter(FVideoCompressFilter,
        'VideoCompressFilter'));
    end;
    BindCtx := nil;

    // Запись
    if FWorkMode in [wmRecord, wmPreviewAndRecord] then
    begin
      if Length(FCaptureFileName) = 0 then
        raise Exception.Create(rsFileNameEmpty);

      // Создаем файл для записи данных из графа
      CheckDSError(FCaptureGraphBuilder.SetOutputFileName(MEDIASUBTYPE_Avi,
        PWideChar(FCaptureFileName), Mux, Sink));
      // строим граф фильтров для захвата изображения
      CheckDSError(FCaptureGraphBuilder.RenderStream(@PIN_CATEGORY_CAPTURE,
        @MEDIATYPE_Video, FVideoInputFilter, FVideoCompressFilter, Mux));
    end;

    // Просмотр
    if FWorkMode in [wmPreview, wmPreviewAndRecord] then
    begin
      if (not HideVideoWindow) and (FPreviewWnd = nil) then
        raise Exception.Create(rsWinidowNotDefined);

      FVMRMixerBitmap := nil;
      VMRFilter := nil;
      if FUseVMR then
      begin
        // Фильтр VMR для наложения картинки
        OleCheck(CoCreateInstance(CLSID_VideoMixingRenderer9, nil,
          CLSCTX_INPROC_SERVER, IID_IBaseFilter, VMRFilter));
        CheckDSError(FGraphBuilder.AddFilter(VMRFilter, 'VMR'));
        CheckDSError(VMRFilter.QueryInterface(IID_IVMRFilterConfig9,
          VMRFilterConfig));
        VMRFilterConfig.SetNumberOfStreams(4);
        OleCheck(VMRFilter.QueryInterface(IID_IVMRMixerBitmap9,
          FVMRMixerBitmap));
      end;

      // Граббинг
      OleCheck(CoCreateInstance(CLSID_SampleGrabber, NIL, CLSCTX_INPROC_SERVER,
        IID_IBaseFilter, SampleGrabberFilter));
      CheckDSError(FGraphBuilder.AddFilter(SampleGrabberFilter,
        'SampleGrabber'));
      OleCheck(SampleGrabberFilter.QueryInterface(IID_ISampleGrabber,
        FSampleGrabber));
      // обнуляем память
      ZeroMemory(@MediaType, sizeof(AM_MEDIA_TYPE));
      // Устанавливаем формат данных для фильтра перехвата
      with MediaType do
      begin
        majortype := MEDIATYPE_Video;
        subtype := MEDIASUBTYPE_RGB24;
        formattype := FORMAT_VideoInfo;
      end;
      FSampleGrabber.SetMediaType(MediaType);
      // Данные будут записаны в буфер в том виде, в котором они
      // проходят через фильтр
      FSampleGrabber.SetBufferSamples(True);
      // Граф не будет остановлен для получения кадра
      FSampleGrabber.SetOneShot(False);

      // строим граф для вывода изображения
      CheckDSError(FCaptureGraphBuilder.RenderStream(@PIN_CATEGORY_PREVIEW, nil,
        FVideoInputFilter, SampleGrabberFilter, VMRFilter));

      // Получаем интерфейс управления окном видео
      OleCheck(FGraphBuilder.QueryInterface(IID_IVideoWindow, FVideoWindow));
      if not HideVideoWindow then
      begin
        // Задаем стиль окна вывода
        CheckDSError(FVideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS));
        // Накладываем окно вывода на  Panel1
        CheckDSError(FVideoWindow.put_Owner(FPreviewWnd.Handle));
        // Задаем размеры окна во всю панель
        UpdateVideoWindow;
        // показываем окно
        CheckDSError(FVideoWindow.put_Visible(True));
      end
      else
      begin
        // Делаем окно скрытым
        CheckDSError(FVideoWindow.put_WindowStyle(SW_HIDE));
        CheckDSError(FVideoWindow.put_AutoShow(False));
        CheckDSError(FVideoWindow.put_Width(1));
        CheckDSError(FVideoWindow.put_Height(1));
      end;
    end;

    if Assigned(FOnBeforeStart) then
      FOnBeforeStart(FVideoInputFilter, FVideoCompressFilter);

    // Запускаем...
    // Запрашиваем интерфейс управления графом
    OleCheck(FGraphBuilder.QueryInterface(IID_IMediaControl, FMediaControl));
    // Запускаем отображение просмотра с вебкамер
    CheckDSError(FMediaControl.Run());
    // Получаем соотношение сторон окна
    SetWindowsAspectRatio;
  except
    result := SaveError(ExceptObject);
    if not result then
      Stop;
  end;
end;

procedure TVideoCam.Stop;
begin
  if Assigned(FOnBeforeStop) then
    FOnBeforeStop(FVideoInputFilter, FVideoCompressFilter);

  if FMediaControl <> nil then
    FMediaControl.StopWhenReady;

  if FGraphEditID <> 0 then
  begin
    RemoveGraphFromRot(FGraphEditID);
    FGraphEditID := 0;
  end;

  FVideoInputFilter := nil;
  FVideoCompressFilter := nil;
  FMediaEventEx := nil;
  FVMRMixerBitmap := nil;
  FSampleGrabber := nil;
  FVideoWindow := nil;
  FMediaControl := nil;
  FCaptureGraphBuilder := nil;
  FGraphBuilder := nil;

  CloseHandle(FRunningMutex);
  FRunningMutex := INVALID_HANDLE_VALUE;
end;

procedure TVideoCam.UpdateVideoWindow;
var
  VideoRect: TRect;
begin
  if (FPreviewWnd = nil) or (FVideoWindow = nil) then
    exit;

  VideoRect := FPreviewWnd.ClientRect;
  CheckDSError(FVideoWindow.SetWindowPosition(VideoRect.Left, VideoRect.Top,
    VideoRect.Right - VideoRect.Left, VideoRect.Bottom - VideoRect.Top));
end;

procedure TVideoCam.WndProc(var Msg: TMessage);
begin
  with Msg do
    if Msg = WM_GRAPHNOTIFY then
      // try
      HandleEvents
      // except
      // Application.HandleException(self);
      // end
    else
      result := DefWindowProc(FHandle, Msg, wParam, lParam);
end;

destructor TVideoCam.Destroy;
begin
  Stop;
  DeallocateHWnd(FHandle);
  CoUninitialize;
  inherited;
end;

procedure TVideoCam.DoEvent(Event, Param1, Param2: Integer);
begin
  if Assigned(FOnDSEvent) then
    FOnDSEvent(Event, Param1, Param2);
end;

function TVideoCam.GetBitmap(Bitmap: TBitmap; Buffer: Pointer;
  BufferLen: Integer): Boolean;
var
  // hr: HRESULT;
  BIHeaderPtr: PBitmapInfoHeader;
  MediaType: TAMMediaType;
  BitmapHandle: HBitmap;
  DIBPtr: Pointer;
  DIBSize: LongInt;
begin
  result := True;
  FLastErrorDescription := '';

  try
    if not Assigned(FSampleGrabber) then
      raise Exception.Create(rsGrabberNotFond);
    if not Assigned(Bitmap) then
      raise Exception.Create(rsBitmapNotAssigned);
    if Assigned(Buffer) and (BufferLen = 0) then
      raise Exception.Create(rsBufferError);

    CheckDSError(FSampleGrabber.GetConnectedMediaType(MediaType));
    try
      if IsEqualGUID(MediaType.majortype, MEDIATYPE_Video) then
      begin
        BIHeaderPtr := Nil;
        if IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo) then
        begin
          if MediaType.cbFormat = sizeof(TVideoInfoHeader) then // check size
            BIHeaderPtr := @(PVIDEOINFOHEADER(MediaType.pbFormat)^.bmiHeader);
        end
        else if IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo2) then
        begin
          if MediaType.cbFormat = sizeof(TVideoInfoHeader2) then // check size
            BIHeaderPtr := @(PVideoInfoHeader2(MediaType.pbFormat)^.bmiHeader);
        end;
        // check, whether format is supported by TSampleGrabber
        if not Assigned(BIHeaderPtr) then
          raise Exception.Create(rsUnsupportedFormat);

        BitmapHandle := CreateDIBSection(0, PBitmapInfo(BIHeaderPtr)^,
          DIB_RGB_COLORS, DIBPtr, 0, 0);
        if BitmapHandle <> 0 then
        begin
          try
            if DIBPtr = nil then
              raise Exception.Create(rsDIBPtrError);
            // get DIB size
            DIBSize := BIHeaderPtr^.biSizeImage;
            if DIBSize = 0 then
            begin
              with BIHeaderPtr^ do
                DIBSize := GetDIBLineSize(biBitCount, biWidth) * biHeight
                  * biPlanes;
            end;
            // copy DIB
            if not Assigned(Buffer) then
            begin
              // get buffer size
              BufferLen := 0;
              CheckDSError(FSampleGrabber.GetCurrentBuffer(BufferLen, nil));
              if BufferLen <= 0 then
                raise Exception.Create(rsBufferError);
              // copy buffer to DIB
              if BufferLen > DIBSize then // copy Min(BufferLen, DIBSize)
                BufferLen := DIBSize;
              CheckDSError(FSampleGrabber.GetCurrentBuffer(BufferLen, DIBPtr));
            end
            else
            begin
              if BufferLen > DIBSize then // copy Min(BufferLen, DIBSize)
                BufferLen := DIBSize;
              Move(Buffer^, DIBPtr^, BufferLen);
            end;
            Bitmap.Handle := BitmapHandle;
          finally
            if Bitmap.Handle <> BitmapHandle then
              // preserve for any changes in Graphics.pas
              DeleteObject(BitmapHandle);
          end;
        end
        else
          RaiseLastOSError;
      end
      else
        raise Exception.Create(rsMediaTypeError);
    finally
      FreeMediaType(@MediaType);
    end;
  except
    result := SaveError(ExceptObject);
  end;
end;

function TVideoCam.GetBitmap(Bitmap: TBitmap): Boolean;
begin
  result := GetBitmap(Bitmap, nil, 0);
end;

function TVideoCam.GetFilter(const DisplayName: string; BindCtx: IBindCtx)
  : IBaseFilter;
var
  chEaten: Integer;
  Moniker: IMoniker;
begin
  // Создаем фильтр
  OleCheck(MkParseDisplayName(BindCtx, PWideChar(DisplayName), chEaten,
    Moniker));
  OleCheck(Moniker.BindToObject(BindCtx, nil, IID_IBaseFilter, result));
end;

function TVideoCam.GetPaused: Boolean;
begin
  result := CheckState(State_Paused);
end;

function TVideoCam.GetRunning: Boolean;
begin
  result := CheckState(State_Running);
end;

procedure TVideoCam.GetVideoCaptureDeviceResolution(out AWidth,
  AHeight: Integer);
var
  LGraphBuilder: IGraphBuilder;
  LCaptureGraphBuilder: ICaptureGraphBuilder2;
  LVideoInputFilter: IBaseFilter;
  LBindCtx: IBindCtx;
begin
  OleCheck(CreateBindCtx(0, LBindCtx));
  // Создаем объект для графа фильтров
  OleCheck(CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER,
    IID_IGraphBuilder, LGraphBuilder));
  // Создаем объект для графа захвата
  OleCheck(CoCreateInstance(CLSID_CaptureGraphBuilder2, nil,
    CLSCTX_INPROC_SERVER, IID_ICaptureGraphBuilder2, LCaptureGraphBuilder));
  // Задаем граф фильтров
  CheckDSError(LCaptureGraphBuilder.SetFiltergraph(LGraphBuilder));
  // Добавим фильтр видеозахвата
  LVideoInputFilter := GetVideoInputFilter(LBindCtx);
  CheckDSError(LGraphBuilder.AddFilter(LVideoInputFilter, 'VideoInputFilter'));

  GetVideoCaptureDeviceResolution(LCaptureGraphBuilder, LVideoInputFilter,
    AWidth, AHeight);
end;

procedure TVideoCam.GetVideoCaptureDeviceResolution(ACaptureGraphBuilder
  : ICaptureGraphBuilder2; AVideoInputFilter: IBaseFilter;
  out AWidth, AHeight: Integer);
var
  LStreamConfig: IAMStreamConfig;
  LMediaType: PAMMediaType;
  LVideoHeader: PVIDEOINFOHEADER;
begin
  // Получаем интерфейс конфигурации
  CheckDSError(ACaptureGraphBuilder.FindInterface(@PIN_CATEGORY_CAPTURE, nil,
    AVideoInputFilter, IID_IAMStreamConfig, LStreamConfig));

  LStreamConfig.GetFormat(LMediaType);
  LVideoHeader := LMediaType.pbFormat;
  AWidth := LVideoHeader.bmiHeader.biWidth;
  AHeight := LVideoHeader.bmiHeader.biHeight;
end;

function TVideoCam.GetVideoCompressorFilter(BindCtx: IBindCtx): IBaseFilter;
begin
  result := GetFilter(FVideoCompressDisplayName, BindCtx);
end;

function TVideoCam.GetVideoInputFilter(BindCtx: IBindCtx): IBaseFilter;
begin
  result := GetFilter(FVideoInputDisplayName, BindCtx);
end;

procedure TVideoCam.HandleEvents;
var
  hr: HRESULT;
  Event: Integer;
{$IF CompilerVersion >= 24.0}
  Param1, Param2: NativeInt;
{$ELSE}
  Param1, Param2: Integer;
{$IFEND}
begin
  if Assigned(FMediaEventEx) then
  begin
    // if you got compiler error on FMediaEventEx.GetEvent with XE7 or newer then
    // delete or remove from search path folder "DSPack\src\DirectX9"
    hr := FMediaEventEx.GetEvent(Event, Param1, Param2, 0);
    while (hr = S_OK) do
    begin
      DoEvent(Event, Param1, Param2);
      FMediaEventEx.FreeEventParams(Event, Param1, Param2);
      hr := FMediaEventEx.GetEvent(Event, Param1, Param2, 0);
    end;
  end;
end;

procedure TVideoCam.Pause;
begin
  if FMediaControl = nil then
    exit;

  if Running then
    FMediaControl.Pause
  else
    FMediaControl.Run;
end;

end.
