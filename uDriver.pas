/// /////////////////////////////////////////////////////////////////////////////
//
// Драйвер видеорегистратора HIKVISION
// Драйверы 1С:БПО Native API
// 1С-Рарус, Отдел системных разработок. STOI 2019
//
unit uDriver;

interface

uses Winapi.Windows, System.SysUtils, uCommonDriver, uCustomDriver, v8napi,
  uVideoRecorderDriver, uVideoPanel, uVideoDevice, uAlphaWindow, uVideoWindow,
  uDriverCommon;

resourcestring
  RsDriverName = 'Драйвер видеорегистратора HIKVISION';
  RsDriverDescription =
    'Драйвер видеорегистратора HIKVISION 1С:Совместимо для 1С:БПО NativeAPI';

const
  FILE_NAME = 'vr_hikvision1c83n';
  DEF_PARENTWINDOW_CLASS = 'WebViewWindowClass';

type
  TDriver = class(TVideorecorderDriver)
  private
    FDevice: TVideoDevice;
    FParentWindowClass: string;
    FPanelMode: Integer;
    FServerPort: Integer;
    FServerPassword: string;
    FServerAddress: string;
    FServerLogin: string;
  private
    procedure UpdateDeviceParams;
    function GetParentWndHandle: HWND;
    procedure DoLoseParentWindow(Sender: TObject);
    procedure CheckDeviceEnabled;
    procedure CheckWindowIndex(AValue: Integer);
    procedure CheckPanelMode(AValue: Integer);
    function GetSelectedWindow(ARaiseErrors: Boolean): Integer; overload;
    procedure DoSelectWindow(AIndex: Integer);
    procedure DoCustomEvent(AIndex: Integer);
  private
    function GetTextPanelColorScheme(AIndex: Integer): Integer;
    procedure SetTextPanelColorScheme(AIndex: Integer; AValue: Integer);
    function GetTextPanelBrightness(AIndex: Integer): Integer;
    procedure SetTextPanelBrightness(AIndex: Integer; AValue: Integer);
    function GetTextPanelTransparency(AIndex: Integer): Integer;
    procedure SetTextPanelTransparency(AIndex: Integer; AValue: Integer);
    function GetTextPanelTransparentBg(AIndex: Integer): Boolean;
    procedure SetTextPanelTransparentBg(AIndex: Integer; AValue: Boolean);
    procedure SetTextPanelPosition(AIndex: Integer; AValue: Integer);
    function GetTextPanelPosition(AIndex: Integer): Integer;
    function GetTextPanelHeight(AIndex: Integer): Integer;
    function GetTextPanelMargin(AIndex: Integer): Integer;
    function GetTextPanelWidth(AIndex: Integer): Integer;
    function GetTextPanelFontSize(AIndex: Integer): Integer;
    procedure SetTextPanelHeight(AIndex: Integer; AValue: Integer);
    procedure SetTextPanelMargin(AIndex: Integer; AValue: Integer);
    procedure SetTextPanelWidth(AIndex: Integer; AValue: Integer);
    procedure SetTextPanelFontSize(AIndex: Integer; AValue: Integer);
  private // Чтение/установка свойств
    function GetSelectedWindow: Integer; overload;
    procedure SetSelectedWindow(AValue: Integer); overload;
    function GetWindowEnabled: Boolean; overload;
    function GetWindowChannel: Integer;
    function GetWindowShowText: Boolean;
    function GetWindowText: string;
    procedure SetWindowEnabled(Value: Boolean); overload;
    procedure SetWindowChannel(const Value: Integer);
    procedure SetWindowShowText(const Value: Boolean);
    procedure SetWindowText(const Value: string);
    function GetWindowPlayLiveVideo: Boolean;
    procedure SetWindowPlayLiveVideo(Value: Boolean);
    function GetWindowTextPanelColorScheme: Integer;
    procedure SetWindowTextPanelColorScheme(const Value: Integer);
    function GetWindowTextPanelBrightness: Integer;
    procedure SetWindowTextPanelBrightness(const Value: Integer);
    function GetWindowTextPanelTransparency: Integer;
    procedure SetWindowTextPanelTransparency(const Value: Integer);
    function GetWindowTextPanelTransparentBg: Boolean;
    procedure SetWindowTextPanelTransparentBg(const Value: Boolean);
    procedure SetWindowTextPanelPosition(const Value: Integer);
    function GetWindowTextPanelPosition: Integer;
    function GetWindowTextPanelHeight: Integer;
    function GetWindowTextPanelMargin: Integer;
    function GetWindowTextPanelWidth: Integer;
    procedure SetWindowTextPanelHeight(const Value: Integer);
    procedure SetWindowTextPanelMargin(const Value: Integer);
    procedure SetWindowTextPanelWidth(const Value: Integer);
    function GetDefTextPanelBrightness: Integer;
    function GetDefTextPanelColorScheme: Integer;
    function GetDefTextPanelMargin: Integer;
    function GetDefTextPanelPosition: Integer;
    function GetDefTextPanelTransparency: Integer;
    function GetDefTextPanelTransparentBg: Boolean;
    function GetDefTextPanelWidth: Integer;
    function GetDefwTextPanelHeight: Integer;
    procedure SetDefTextPanelBrightness(const Value: Integer);
    procedure SetDefTextPanelColorScheme(const Value: Integer);
    procedure SetDefTextPanelHeight(const Value: Integer);
    procedure SetDefTextPanelMargin(const Value: Integer);
    procedure SetDefTextPanelPosition(const Value: Integer);
    procedure SetDefTextPanelTransparency(const Value: Integer);
    procedure SetDefTextPanelTransparentBg(const Value: Boolean);
    procedure SetDefTextPanelWidth(const Value: Integer);
    function GetDefFontSize: Integer;
    procedure SetDefFontSize(const Value: Integer);
    function GetWindowTextPanelFontSize: Integer;
    procedure SetWindowTextPanelFontSize(const Value: Integer);
    function GetDefCaptureDir: string;
    procedure SetDefCaptureDir(const Value: string);
  public
    constructor Create; override;
    destructor Destroy; override;
  public
    // Реализация методов включения/выключения устройства
    procedure Open; override;
    procedure Close; override;
  public
    // Реализация методов типа оборудования
    // Режим отображения окон
    procedure SetPanelMode(AMode: Integer); override;
    function GetPanelMode: Integer; override;
    // Включение-выключение окна
    procedure SetWindowEnabled(AIndex: Integer; AEnabled: Boolean);
      overload; override;
    function GetWindowEnabled(AIndex: Integer): Boolean;
      overload; override;
    // Воспроизведение видеопотока
    procedure SetPlayLiveVideo(AIndex: Integer; APlay: Boolean); override;
    function GetPlayLiveVideo(AIndex: Integer): Boolean; override;
    // Текст
    procedure SetText(AIndex: Integer; const AText: string); override;
    function GetText(AIndex: Integer): string; override;
    // Отображать текст
    procedure SetShowText(AIndex: Integer; AShow: Boolean); override;
    function GetShowText(AIndex: Integer): Boolean; override;
    // Канал
    procedure SetChannel(AIndex, AChannel: Integer); override;
    function GetChannel(AIndex: Integer): Integer; override;
    // Включить все окна
    procedure EnableWindowAll(AEnabled: Boolean); override;
    // Включить воспроизведение для всех окон
    procedure PlayLiveAll(APlay: Boolean); override;
    // Отобразить текст для всех окон
    procedure ShowTextAll(AShow: Boolean); override;
  public
    // Нестандартные экспортируемые методы
    // Параметры окна
    [ExportMethAttribute('ПолучитьПараметрыОкна', 14)]
    function GetWindowParams(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('УстановитьПараметрыОкна', 14)]
    function SetWindowParams(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Текущее окно
    [ExportMethAttribute('ПолучитьТекущееОкно', 1)]
    function GetSelectedWindow(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('УстановитьТекущееОкно', 1)]
    function SetSelectedWindow(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  public
    // Экспортируемые параметры основные
    // Класс родительского окна
    [ExportPropAttribute('КлассРодительскогоОкна', 'Класс родительского окна',
      DEF_PARENTWINDOW_CLASS, False)]
    property ParentWindowClass: string read FParentWindowClass
      write FParentWindowClass;
    // Режим панели
    [ExportPropAttribute('РежимПанели', 'Режим видеопанели', '0', False)]
    property PanelMode: Integer read FPanelMode write SetPanelMode;
    // Адрес сервера
    [ExportPropAttribute('АдресСервера', 'Адрес сервера', '', False)]
    property ServerAddress: string read FServerAddress write FServerAddress;
    // Порт
    [ExportPropAttribute('ПортСервера', 'Порт сервера', '8000', False)]
    property ServerPort: Integer read FServerPort write FServerPort;
    // Логин
    [ExportPropAttribute('ЛогинСервера', 'Имя пользователя', '', False)]
    property ServerLogin: string read FServerLogin write FServerLogin;
    // Пароль
    [ExportPropAttribute('ПарольСервера', 'Пароль пользователя', '', False)]
    property ServerPassword: string read FServerPassword write FServerPassword;
    // Размер щрифта
    [ExportPropAttribute('РазмерШрифта', 'Размер шрифта', '12', False)]
    property DefFontSize: Integer read GetDefFontSize write SetDefFontSize;
    // Каталог для сохранения фото/видео
    [ExportPropAttribute('КаталогФотоВидео', 'Каталог для сохранения фото/видео', '', False)]
    property DefCaptureDir: string read GetDefCaptureDir write SetDefCaptureDir;
  public
    // Экспортируемые параметры времени выполнения
    // Текущее окно
    [ExportPropAttribute('ТекущееОкно', 'Текущее окно', '-1', False)]
    property SelectedWindow: Integer read GetSelectedWindow
      write SetSelectedWindow;
    // Текущее окно включено
    [ExportPropAttribute('ОкноВключено', 'Текущее окно включено',
      'False', False)]
    property WindowEnabled: Boolean read GetWindowEnabled
      write SetWindowEnabled;
    // Текущее окно, номер канала
    [ExportPropAttribute('ОкноКанал', 'Номер канала окна', '-1', False)]
    property WindowChannel: Integer read GetWindowChannel
      write SetWindowChannel;
    // Текущее окно, отбражение текста
    [ExportPropAttribute('ОкноОтображатьТекст', 'Отображать текст в окне',
      'False', False)]
    property WindowShowText: Boolean read GetWindowShowText
      write SetWindowShowText;
    // Текущее окно, текст
    [ExportPropAttribute('ОкноТекст', 'Текст окна', '', False)]
    property WindowText: string read GetWindowText write SetWindowText;
    // Текущее окно, воспроизведение потка
    [ExportPropAttribute('ОкноВоспроизведениеПотока',
      'Окно воспроизводит поток', 'False', False)]
    property WindowPlayLiveVideo: Boolean read GetWindowPlayLiveVideo
      write SetWindowPlayLiveVideo;
    // Текущее окно, цветовая схема
    [ExportPropAttribute('ОкноЦветоваяСхемаПанелиТекста',
      'Цветовая схема панели текста окна', '0', False)]
    property WindowTextPanelColorScheme: Integer
      read GetWindowTextPanelColorScheme write SetWindowTextPanelColorScheme;
    // Текущее окно, яркость панели текста
    [ExportPropAttribute('ОкноЯркостьПанелиТекста',
      'Яркость панели текста окна', '-50', False)]
    property WindowTextPanelBrightness: Integer
      read GetWindowTextPanelBrightness write SetWindowTextPanelBrightness;
    // Текущее окно, прозрачность панели текста
    [ExportPropAttribute('ОкноПрозрачностьПанелиТекста',
      'Прозрачность панели текста окна', '50', False)]
    property WindowTextPanelTransparency: Integer
      read GetWindowTextPanelTransparency write SetWindowTextPanelTransparency;
    // Текущее окно, прозрачный фон панели текста
    [ExportPropAttribute('ОкноПрозрачныйФонПанелиТекста',
      'Прозрачный фон панели текста окна', 'False', False)]
    property WindowTextPanelTransparentBg: Boolean
      read GetWindowTextPanelTransparentBg
      write SetWindowTextPanelTransparentBg;
    // Текущее окно, позиция панели текста
    [ExportPropAttribute('ОкноПозицияПанелиТекста',
      'Позиция панели текста окна', '0', False)]
    property WindowTextPanelPosition: Integer read GetWindowTextPanelPosition
      write SetWindowTextPanelPosition;
    // Текущее окно, высота панели текста
    [ExportPropAttribute('ОкноВысотаПанелиТекста', 'Позиция панели текста окна',
      '50', False)]
    property WindowTextPanelHeight: Integer read GetWindowTextPanelHeight
      write SetWindowTextPanelHeight;
    // Текущее окно, ширина панели текста
    [ExportPropAttribute('ОкноВысотаПанелиТекста', 'Ширина панели текста окна',
      '50', False)]
    property WindowTextPanelWidth: Integer read GetWindowTextPanelWidth
      write SetWindowTextPanelWidth;
    // Текущее окно, граница панели текста
    [ExportPropAttribute('ОкноГраницаПанелиТекста',
      'Граница панели текста окна', '5', False)]
    property WindowTextPanelMargin: Integer read GetWindowTextPanelMargin
      write SetWindowTextPanelMargin;
    // Текущее окно, размер щрифта панели текста
    [ExportPropAttribute('ОкноРазмерШрифтаПанелиТекста', 'Размер шрифта панели текста окна', '12', False)]
    property WindowTextPanelFontSize: Integer read GetWindowTextPanelFontSize write SetWindowTextPanelFontSize;
  public // Значения свойств панели текста по-умолчанию
    // Цветовая схема по-умолчанию
    [ExportPropAttribute('ЦветоваяСхемаПанелиТекста',
      'Цветовая схема панели текста окна', '0', False)]
    property DefTextPanelColorScheme: Integer
      read GetDefTextPanelColorScheme write SetDefTextPanelColorScheme;
    // Яркость панели текста по-умолчанию
    [ExportPropAttribute('ЯркостьПанелиТекста',
      'Яркость панели текста окна', '-50', False)]
    property DefTextPanelBrightness: Integer
      read GetDefTextPanelBrightness write SetDefTextPanelBrightness;
    // Прозрачность панели текста по-умолчанию
    [ExportPropAttribute('ПрозрачностьПанелиТекста',
      'Прозрачность панели текста окна', '50', False)]
    property DefTextPanelTransparency: Integer
      read GetDefTextPanelTransparency write SetDefTextPanelTransparency;
    // Прозрачный фон панели текста по-умолчанию
    [ExportPropAttribute('ПрозрачныйФонПанелиТекста',
      'Прозрачный фон панели текста окна', 'False', False)]
    property DefTextPanelTransparentBg: Boolean
      read GetDefTextPanelTransparentBg
      write SetDefTextPanelTransparentBg;
    // Позиция панели текста по-умолчанию
    [ExportPropAttribute('ПозицияПанелиТекста',
      'Позиция панели текста окна', '0', False)]
    property DefTextPanelPosition: Integer read GetDefTextPanelPosition
      write SetDefTextPanelPosition;
    // Высота по-умолчанию
    [ExportPropAttribute('ВысотаПанелиТекста', 'Позиция панели текста окна',
      '50', False)]
    property DefTextPanelHeight: Integer read GetDefwTextPanelHeight
      write SetDefTextPanelHeight;
    // Ширина по-умолчанию
    [ExportPropAttribute('ШиринаПанелиТекста', 'Ширина панели текста окна',
      '50', False)]
    property DefTextPanelWidth: Integer read GetDefTextPanelWidth
      write SetDefTextPanelWidth;
    // Граница по-умолчанию
    [ExportPropAttribute('ГраницаПанелиТекста',
      'Граница панели текста окна', '5', False)]
    property DefTextPanelMargin: Integer read GetDefTextPanelMargin
      write SetDefTextPanelMargin;
  end;

implementation

uses System.Math;

resourcestring
  RsErrMain1CWindowNotFound = 'Главное окно 1С:Предприятие не найдено!';
  RsErrParentWindowNotFound = 'Окно с классом %s не найдено!';
  RsErrPanelModeOutOfRange = 'Режим панели вне диапазона';
  RsErrNoSelectedWindow = 'Не выбрано ни одно окно';

function FindChildWindow(AParent: HWND; const AClass: string): HWND;
var
  LBuff: array [0 .. MAX_PATH - 1] of Char;
  LClassName: string;
  LStrLength: Integer;
  LChildWnd, LChildAfter: HWND;
begin
  if not IsWindowVisible(AParent) then
    Exit(0);

  LChildAfter := 0;
  repeat
    Result := FindWindowEx(AParent, LChildAfter, nil, nil);
    if Result <> 0 then
    begin
      if (IsWindowVisible(Result)) and (not(IsIconic(Result))) then
      begin
        LStrLength := GetClassName(Result, LBuff, MAX_PATH);
        SetString(LClassName, PChar(@LBuff[0]), LStrLength);
        if AClass = LClassName then
          Exit; // Нашли

        // Рекурсия
        LChildWnd := FindChildWindow(Result, AClass);
        if LChildWnd <> 0 then
          Exit(LChildWnd); // Нашли
      end;
    end;

    LChildAfter := Result;
  until Result = 0;
end;

{ TDriver }

procedure TDriver.CheckDeviceEnabled;
begin
  if not FDevice.Enabled then
    raise Exception.Create(RsErrDeviceDisabled);
end;

procedure TDriver.CheckPanelMode(AValue: Integer);
begin
  if not(AValue in [Ord(Low(TPanelMode)) .. Ord(High(TPanelMode))]) then
    raise Exception.Create(RsErrPanelModeOutOfRange);
end;

procedure TDriver.CheckWindowIndex(AValue: Integer);
begin
  CheckDeviceEnabled;
  TVideoPanel.CheckWindowIndex(AValue);
end;

procedure TDriver.Close;
begin
  inherited;
  if Assigned(FDevice) then
    FDevice.Disable;
end;

constructor TDriver.Create;
begin
  inherited;
  FDevice := TVideoDevice.Create;
end;

destructor TDriver.Destroy;
begin
  FreeAndNil(FDevice);
  inherited;
end;

procedure TDriver.DoCustomEvent(AIndex: Integer);
begin
  v8.ExternalEvent(PWideChar(TEquipmentType.Name[DriverInfo.EquipmentType]),
    'CustomEvent', PWideChar(IntToStr(AIndex)));
end;

procedure TDriver.DoLoseParentWindow(Sender: TObject);
begin
  FDevice.Disable;
end;

procedure TDriver.DoSelectWindow(AIndex: Integer);
begin
  v8.ExternalEvent(PWideChar(TEquipmentType.Name[DriverInfo.EquipmentType]),
    'SelectWindow', PWideChar(IntToStr(AIndex)));
end;

procedure TDriver.SetWindowChannel(const Value: Integer);
begin
  SetChannel(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowTextPanelBrightness(const Value: Integer);
begin
  SetTextPanelBrightness(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowTextPanelColorScheme(const Value: Integer);
begin
  SetTextPanelColorScheme(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowTextPanelHeight(const Value: Integer);
begin
  SetTextPanelHeight(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowTextPanelMargin(const Value: Integer);
begin
  SetTextPanelMargin(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowTextPanelPosition(const Value: Integer);
begin
  SetTextPanelPosition(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowTextPanelTransparency(const Value: Integer);
begin
  SetTextPanelTransparency(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowTextPanelTransparentBg(const Value: Boolean);
begin
  SetTextPanelTransparentBg(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowTextPanelWidth(const Value: Integer);
begin
  SetTextPanelWidth(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowEnabled(AIndex: Integer; AEnabled: Boolean);
begin
  CheckDeviceEnabled;
  CheckWindowIndex(AIndex);
  FDevice.VideoPanel.VideoWindows[AIndex].Used := AEnabled;
end;

procedure TDriver.SetWindowTextPanelFontSize(const Value: Integer);
begin
  SetTextPanelFontSize(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowEnabled(Value: Boolean);
begin
  SetWindowEnabled(GetSelectedWindow(True), Value);
end;

function TDriver.SetWindowParams(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
begin
  try
    LIndex := V8AsInt(@Params[1]);

    SetWindowEnabled(LIndex, V8AsBool(@Params[2]));
    SetChannel(LIndex, V8AsInt(@Params[3]));
    SetShowText(LIndex, V8AsBool(@Params[4]));
    SetText(LIndex, V8AsWString(@Params[5]));
    SetTextPanelColorScheme(LIndex, V8AsInt(@Params[6]));
    SetTextPanelBrightness(LIndex, V8AsInt(@Params[7]));
    SetTextPanelTransparency(LIndex, V8AsInt(@Params[8]));
    SetTextPanelTransparentBg(LIndex, V8AsBool(@Params[9]));
    SetTextPanelPosition(LIndex, V8AsInt(@Params[10]));
    SetTextPanelWidth(LIndex, V8AsInt(@Params[11]));
    SetTextPanelHeight(LIndex, V8AsInt(@Params[12]));
    SetTextPanelMargin(LIndex, V8AsInt(@Params[13]));
    SetTextPanelFontSize(LIndex, V8AsInt(@Params[14]));

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

procedure TDriver.SetWindowPlayLiveVideo(Value: Boolean);
begin
  SetPlayLiveVideo(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowShowText(const Value: Boolean);
begin
  SetShowText(GetSelectedWindow(True), Value);
end;

procedure TDriver.SetWindowText(const Value: string);
begin
  SetText(GetSelectedWindow(True), Value);
end;

procedure TDriver.EnableWindowAll(AEnabled: Boolean);
begin
  CheckDeviceEnabled;
  FDevice.VideoPanel.EnableAll(AEnabled);
end;

function TDriver.GetDefCaptureDir: string;
begin
  Result := TVideoPanel.DefCaptureDir;
end;

function TDriver.GetChannel(AIndex: Integer): Integer;
begin
  CheckDeviceEnabled;
  CheckWindowIndex(AIndex);
  Result := FDevice.VideoPanel.VideoWindows[AIndex].Channel;
end;

function TDriver.GetDefFontSize: Integer;
begin
  Result := TVideoPanel.DefFontSize;
end;

function TDriver.GetDefTextPanelBrightness: Integer;
begin
  Result := TAlphaWindow.DefBrightness;
end;

function TDriver.GetDefTextPanelColorScheme: Integer;
begin
  Result := Ord(TAlphaWindow.DefColorScheme);
end;

function TDriver.GetDefTextPanelMargin: Integer;
begin
  Result := TAlphaWindow.DefMargin;
end;

function TDriver.GetDefTextPanelPosition: Integer;
begin
  Result := Ord(TAlphaWindow.DefPosition);
end;

function TDriver.GetDefTextPanelTransparency: Integer;
begin
  Result := TAlphaWindow.DefTransparency;
end;

function TDriver.GetDefTextPanelTransparentBg: Boolean;
begin
  Result := TAlphaWindow.DefTransparentBg;
end;

function TDriver.GetDefTextPanelWidth: Integer;
begin
  Result := TAlphaWindow.DefWidthRelative;
end;

function TDriver.GetDefwTextPanelHeight: Integer;
begin
  Result := TAlphaWindow.DefHeightRelative;
end;

function TDriver.GetPanelMode: Integer;
begin
  CheckDeviceEnabled;
  Result := Ord(FDevice.VideoPanel.PanelMode);
end;

function TDriver.GetParentWndHandle: HWND;
begin
  Result := GetActiveWindow;
  if Result = 0 then
    raise Exception.Create(RsErrMain1CWindowNotFound);

  Result := FindChildWindow(Result, FParentWindowClass);
  if Result = 0 then
    raise Exception.CreateFmt(RsErrParentWindowNotFound, [FParentWindowClass]);
end;

function TDriver.GetPlayLiveVideo(AIndex: Integer): Boolean;
begin
  CheckDeviceEnabled;
  CheckWindowIndex(AIndex);
  Result := FDevice.VideoPanel.VideoWindows[AIndex].IsPlaying;
end;

function TDriver.GetSelectedWindow(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
begin
  try
    CheckDeviceEnabled;
    V8SetInt(@Params[1], FDevice.VideoPanel.ItemIndex);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TDriver.GetSelectedWindow(ARaiseErrors: Boolean): Integer;
begin
  try
    CheckDeviceEnabled;
  except
    if ARaiseErrors then
      raise
    else
      Exit(-1);
  end;

  Result := FDevice.VideoPanel.ItemIndex;
  if (Result < 0) and ARaiseErrors then
    raise Exception.Create(RsErrNoSelectedWindow);
end;

function TDriver.GetSelectedWindow: Integer;
begin
  Result := GetSelectedWindow(False);
end;

function TDriver.GetShowText(AIndex: Integer): Boolean;
begin
  CheckWindowIndex(AIndex);
  Result := FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Used;
end;

function TDriver.GetText(AIndex: Integer): string;
begin
  CheckWindowIndex(AIndex);
  Result := FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Text;
end;

function TDriver.GetTextPanelBrightness(AIndex: Integer): Integer;
begin
  CheckDeviceEnabled;
  Result := FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Brightness;
end;

function TDriver.GetTextPanelColorScheme(AIndex: Integer): Integer;
begin
  CheckDeviceEnabled;
  Result := Ord(FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.ColorScheme);
end;

function TDriver.GetTextPanelFontSize(AIndex: Integer): Integer;
begin
  CheckDeviceEnabled;
  Result := FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.FontSize;
end;

function TDriver.GetTextPanelHeight(AIndex: Integer): Integer;
begin
  CheckDeviceEnabled;
  Result := FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Height;
end;

function TDriver.GetTextPanelMargin(AIndex: Integer): Integer;
begin
  CheckDeviceEnabled;
  Result := FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Margin;
end;

function TDriver.GetTextPanelPosition(AIndex: Integer): Integer;
begin
  CheckDeviceEnabled;
  Result := Ord(FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Position);
end;

function TDriver.GetTextPanelTransparency(AIndex: Integer): Integer;
begin
  CheckDeviceEnabled;
  Result := FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Transparency;
end;

function TDriver.GetTextPanelTransparentBg(AIndex: Integer): Boolean;
begin
  CheckDeviceEnabled;
  Result := FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.TransparentBg;
end;

function TDriver.GetTextPanelWidth(AIndex: Integer): Integer;
begin
  CheckDeviceEnabled;
  Result := FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Width;
end;

function TDriver.GetWindowChannel: Integer;
begin
  Result := GetChannel(GetSelectedWindow(True));
end;

function TDriver.GetWindowTextPanelBrightness: Integer;
begin
  Result := GetTextPanelBrightness(GetSelectedWindow(True));
end;

function TDriver.GetWindowTextPanelColorScheme: Integer;
begin
  Result := GetTextPanelColorScheme(GetSelectedWindow(True));
end;

function TDriver.GetWindowTextPanelHeight: Integer;
begin
  Result := GetTextPanelHeight(GetSelectedWindow(True));
end;

function TDriver.GetWindowTextPanelMargin: Integer;
begin
  Result := GetTextPanelMargin(GetSelectedWindow(True));
end;

function TDriver.GetWindowTextPanelPosition: Integer;
begin
  Result := GetTextPanelPosition(GetSelectedWindow(True));
end;

function TDriver.GetWindowTextPanelTransparency: Integer;
begin
  Result := GetTextPanelTransparency(GetSelectedWindow(True));
end;

function TDriver.GetWindowTextPanelTransparentBg: Boolean;
begin
  Result := GetTextPanelTransparentBg(GetSelectedWindow(True));
end;

function TDriver.GetWindowTextPanelWidth: Integer;
begin
  Result := GetTextPanelWidth(GetSelectedWindow(True));
end;

function TDriver.GetWindowEnabled(AIndex: Integer): Boolean;
begin
  CheckDeviceEnabled;
  CheckWindowIndex(AIndex);
  Result := FDevice.VideoPanel.VideoWindows[AIndex].Used;
end;

function TDriver.GetWindowTextPanelFontSize: Integer;
begin
  Result := GetTextPanelFontSize(GetSelectedWindow(True));
end;

function TDriver.GetWindowEnabled: Boolean;
begin
  Result := GetWindowEnabled(GetSelectedWindow(True));
end;

function TDriver.GetWindowParams(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
begin
  try
    LIndex := V8AsInt(@Params[1]);

    V8SetBool(@Params[2], GetWindowEnabled(LIndex));
    V8SetInt(@Params[3], GetChannel(LIndex));
    V8SetBool(@Params[4], GetShowText(LIndex));
    V8SetWString(@Params[5], GetText(LIndex));
    V8SetInt(@Params[6], GetTextPanelColorScheme(LIndex));
    V8SetInt(@Params[7], GetTextPanelBrightness(LIndex));
    V8SetInt(@Params[8], GetTextPanelTransparency(LIndex));
    V8SetBool(@Params[9], GetTextPanelTransparentBg(LIndex));
    V8SetInt(@Params[10], GetTextPanelPosition(LIndex));
    V8SetInt(@Params[11], GetTextPanelWidth(LIndex));
    V8SetInt(@Params[12], GetTextPanelHeight(LIndex));
    V8SetInt(@Params[13], GetTextPanelMargin(LIndex));
    V8SetInt(@Params[14], GetTextPanelFontSize(LIndex));

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TDriver.GetWindowPlayLiveVideo: Boolean;
begin
  Result := GetPlayLiveVideo(GetSelectedWindow(True));
end;

function TDriver.GetWindowShowText: Boolean;
begin
  Result := GetShowText(GetSelectedWindow(True));
end;

function TDriver.GetWindowText: string;
begin
  Result := GetText(GetSelectedWindow(True));
end;

procedure TDriver.Open;
begin
  inherited;
  UpdateDeviceParams;
  FDevice.Enable;
  FDevice.VideoPanel.OnSelectWindow := DoSelectWindow;
  FDevice.VideoPanel.OnCustomEvent := DoCustomEvent;
end;

procedure TDriver.SetPanelMode(AMode: Integer);
begin
  CheckPanelMode(AMode);
  FPanelMode := AMode;
  if Assigned(FDevice.VideoPanel) then
    FDevice.VideoPanel.PanelMode := TPanelMode(AMode);
end;

procedure TDriver.SetPlayLiveVideo(AIndex: Integer; APlay: Boolean);
begin
  CheckDeviceEnabled;
  CheckWindowIndex(AIndex);
  if APlay then
    FDevice.VideoPanel.VideoWindows[AIndex].PlayLiveVideo
  else
    FDevice.VideoPanel.VideoWindows[AIndex].StopLiveVideo;
end;

procedure TDriver.PlayLiveAll(APlay: Boolean);
begin
  CheckDeviceEnabled;
  FDevice.VideoPanel.PlayAll(APlay);
end;

procedure TDriver.SetDefCaptureDir(const Value: string);
begin
  TVideoPanel.DefCaptureDir := Value;
end;

procedure TDriver.SetChannel(AIndex, AChannel: Integer);
begin
  CheckDeviceEnabled;
  CheckWindowIndex(AIndex);
  FDevice.VideoPanel.VideoWindows[AIndex].Channel := AChannel;
end;

procedure TDriver.SetDefFontSize(const Value: Integer);
begin
  TVideoPanel.DefFontSize := Value;
end;

procedure TDriver.SetDefTextPanelBrightness(const Value: Integer);
begin
  CheckPercentValue(Value, True);
  TAlphaWindow.DefBrightness := Value;
end;

procedure TDriver.SetDefTextPanelColorScheme(const Value: Integer);
begin
  CheckColorShceme(Value);
  TAlphaWindow.DefColorScheme := TColorScheme(Value);
end;

procedure TDriver.SetDefTextPanelHeight(const Value: Integer);
begin
  CheckPercentValue(Value, False);
  TAlphaWindow.DefHeightRelative := Value;
end;

procedure TDriver.SetDefTextPanelMargin(const Value: Integer);
begin
  TAlphaWindow.DefMargin := Value;
end;

procedure TDriver.SetDefTextPanelPosition(const Value: Integer);
begin
  CheckTextPanelPosition(Value);
  TAlphaWindow.DefPosition := TWindowPosition(Value);
end;

procedure TDriver.SetDefTextPanelTransparency(const Value: Integer);
begin
  CheckPercentValue(Value, False);
  TAlphaWindow.DefTransparency := Value;
end;

procedure TDriver.SetDefTextPanelTransparentBg(const Value: Boolean);
begin
  TAlphaWindow.DefTransparentBg := Value;
end;

procedure TDriver.SetDefTextPanelWidth(const Value: Integer);
begin
  CheckPercentValue(Value, False);
  TAlphaWindow.DefWidthRelative := Value;
end;

procedure TDriver.SetText(AIndex: Integer; const AText: string);
begin
  CheckDeviceEnabled;
  CheckWindowIndex(AIndex);
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Text := AText;
end;

procedure TDriver.SetTextPanelBrightness(AIndex, AValue: Integer);
begin
  CheckDeviceEnabled;
  CheckPercentValue(AValue, True);
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Brightness := AValue;
end;

procedure TDriver.SetTextPanelColorScheme(AIndex, AValue: Integer);
begin
  CheckDeviceEnabled;
  CheckColorShceme(AValue);
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.ColorScheme :=
    TColorScheme(AValue);
end;

procedure TDriver.SetTextPanelFontSize(AIndex, AValue: Integer);
begin
  CheckDeviceEnabled;
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.FontSize := AValue;
end;

procedure TDriver.SetTextPanelHeight(AIndex, AValue: Integer);
begin
  CheckDeviceEnabled;
  CheckPercentValue(AValue, False);
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Height := AValue;
end;

procedure TDriver.SetTextPanelMargin(AIndex, AValue: Integer);
begin
  CheckDeviceEnabled;
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Margin := AValue;
end;

procedure TDriver.SetTextPanelPosition(AIndex, AValue: Integer);
begin
  CheckDeviceEnabled;
  CheckTextPanelPosition(AValue);
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Position :=
    TWindowPosition(AValue);
end;

procedure TDriver.SetTextPanelTransparency(AIndex, AValue: Integer);
begin
  CheckDeviceEnabled;
  CheckPercentValue(AValue, False);
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Transparency := AValue;
end;

procedure TDriver.SetTextPanelTransparentBg(AIndex: Integer; AValue: Boolean);
begin
  CheckDeviceEnabled;
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.TransparentBg := AValue;
end;

procedure TDriver.SetTextPanelWidth(AIndex, AValue: Integer);
begin
  CheckDeviceEnabled;
  CheckPercentValue(AValue, False);
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Width := AValue;
end;

function TDriver.SetSelectedWindow(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
begin
  try
    SetSelectedWindow(V8AsInt(@Params[1]));

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

procedure TDriver.SetSelectedWindow(AValue: Integer);
begin
  CheckDeviceEnabled;
  CheckWindowIndex(AValue);
  FDevice.VideoPanel.ItemIndex := AValue;
end;

procedure TDriver.SetShowText(AIndex: Integer; AShow: Boolean);
begin
  CheckDeviceEnabled;
  CheckWindowIndex(AIndex);
  FDevice.VideoPanel.VideoWindows[AIndex].TextPanel.Used := AShow;
end;

procedure TDriver.ShowTextAll(AShow: Boolean);
begin
  CheckDeviceEnabled;
  FDevice.VideoPanel.ShowOverlayTextAll(AShow);
end;

procedure TDriver.UpdateDeviceParams;
begin
  FDevice.ParentWnd := GetParentWndHandle;
  FDevice.PanelMode := TPanelMode(FPanelMode);
  FDevice.Address := FServerAddress;
  FDevice.Port := FServerPort;
  FDevice.Login := FServerLogin;
  FDevice.Password := FServerPassword;
  FDevice.OnLoseParentWindow := DoLoseParentWindow;
end;

initialization

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
// Обязательная регистрация класса
// ProgID будет иметь вид "Addin.FILE_NAME.FILE_NAME"
// Лог бедет сохраняться в %CSIDL_COMMON_APPDATA%\FILE_NAME
TDriver.RegisterDriver(TDriver, FILE_NAME, RsDriverName, RsDriverDescription);

end.
