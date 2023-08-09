unit uDriverVideoWindow;

interface

uses System.SysUtils, uCustomDriver, uVideoPanel, uVideoWindow, uDriverCommon,
  uAlphaWindow;

type
  TDriverVideoWindow = class(TCustomDriver)
  private
    FWnidowIndex: Integer;
  private
    function GetVideoPanel: TVideoPanel;
    function GetVideoWindow: TVideoWindow;
  private
    property VideoPanel: TVideoPanel read GetVideoPanel;
    property VideoWindow: TVideoWindow read GetVideoWindow;
  private
    procedure SetWindowIndex(const Value: Integer);
    function GetChannel: Integer;
    function GetEnabled: Boolean;
    procedure SetChannel(const Value: Integer);
    procedure SetEnabled(const Value: Boolean);
    function GetShowText: Boolean;
    function GetText: string;
    procedure SetShowText(const Value: Boolean);
    procedure SetText(const Value: string);
    function GetPlayLiveVideo: Boolean;
    function GetTextPanelBrightness: Integer;
    function GetTextPanelColorScheme: Integer;
    function GetTextPanelFontSize: Integer;
    function GetTextPanelHeight: Integer;
    function GetTextPanelMargin: Integer;
    function GetTextPanelPosition: Integer;
    function GetTextPanelTransparency: Integer;
    function GetTextPanelTransparentBg: Boolean;
    function GetTextPanelWidth: Integer;
    procedure SetPlayLiveVideo(const Value: Boolean);
    procedure SetTextPanelBrightness(const Value: Integer);
    procedure SetTextPanelColorScheme(const Value: Integer);
    procedure SetTextPanelFontSize(const Value: Integer);
    procedure SetTextPanelHeight(const Value: Integer);
    procedure SetTextPanelMargin(const Value: Integer);
    procedure SetTextPanelPosition(const Value: Integer);
    procedure SetTextPanelTransparency(const Value: Integer);
    procedure SetTextPanelTransparentBg(const Value: Boolean);
    procedure SetTextPanelWidth(const Value: Integer);
  public
    constructor Create; override;
  public
    // Индекс окна
    [ExportPropAttribute('ИндексОкна', 'Индекс окна', '-1', False)]
    property WindowIndex: Integer read FWnidowIndex write SetWindowIndex;
    // Включено
    [ExportPropAttribute('Включено', 'Включено', 'False', False)]
    property Enabled: Boolean read GetEnabled write SetEnabled;
    // Номер канала
    [ExportPropAttribute('Канал', 'Номер канала', '-1', False)]
    property Channel: Integer read GetChannel write SetChannel;
    // Отбражение текста
    [ExportPropAttribute('ОтображатьТекст', 'Отображать текст', 'False', False)]
    property ShowText: Boolean read GetShowText write SetShowText;
    // Текст
    [ExportPropAttribute('Текст', 'Текст', '', False)]
    property wText: string read GetText write SetText;
    // Воспроизведение потка
    [ExportPropAttribute('ВоспроизведениеПотока', 'Окно воспроизводит поток',
      'False', False)]
    property PlayLiveVideo: Boolean read GetPlayLiveVideo
      write SetPlayLiveVideo;
    // Цветовая схема
    [ExportPropAttribute('ЦветоваяСхемаПанелиТекста',
      'Цветовая схема панели текста', '0', False)]
    property TextPanelColorScheme: Integer read GetTextPanelColorScheme
      write SetTextPanelColorScheme;
    // Яркость панели текста
    [ExportPropAttribute('ЯркостьПанелиТекста', 'Яркость панели текста',
      '-50', False)]
    property WindowTextPanelBrightness: Integer read GetTextPanelBrightness
      write SetTextPanelBrightness;
    // Прозрачность панели текста
    [ExportPropAttribute('ПрозрачностьПанелиТекста',
      'Прозрачность панели текста', '50', False)]
    property TextPanelTransparency: Integer read GetTextPanelTransparency
      write SetTextPanelTransparency;
    // Прозрачный фон панели текста
    [ExportPropAttribute('ПрозрачныйФонПанелиТекста',
      'Прозрачный фон панели текста окна', 'False', False)]
    property TextPanelTransparentBg: Boolean read GetTextPanelTransparentBg
      write SetTextPanelTransparentBg;
    // Позиция панели текста
    [ExportPropAttribute('ПозицияПанелиТекста', 'Позиция панели текста',
      '0', False)]
    property TextPanelPosition: Integer read GetTextPanelPosition
      write SetTextPanelPosition;
    // Высота панели текста
    [ExportPropAttribute('ВысотаПанелиТекста', 'Позиция панели текста',
      '50', False)]
    property TextPanelHeight: Integer read GetTextPanelHeight
      write SetTextPanelHeight;
    // Ширина панели текста
    [ExportPropAttribute('ШиринаПанелиТекста', 'Ширина панели текста окна',
      '50', False)]
    property TextPanelWidth: Integer read GetTextPanelWidth
      write SetTextPanelWidth;
    // Граница панели текста
    [ExportPropAttribute('ГраницаПанелиТекста', 'Граница панели текста',
      '5', False)]
    property TextPanelMargin: Integer read GetTextPanelMargin
      write SetTextPanelMargin;
    // Размер щрифта панели текста
    [ExportPropAttribute('РазмерШрифтаПанелиТекста',
      'Размер шрифта панели текста', '12', False)]
    property TextPanelFontSize: Integer read GetTextPanelFontSize
      write SetTextPanelFontSize;
  end;

implementation

{ TDriverVideoWindow }

constructor TDriverVideoWindow.Create;
begin
  inherited;
  FWnidowIndex := -1;
end;

function TDriverVideoWindow.GetChannel: Integer;
begin
  Result := VideoWindow.Channel;
end;

function TDriverVideoWindow.GetEnabled: Boolean;
begin
  Result := VideoWindow.Used;
end;

function TDriverVideoWindow.GetPlayLiveVideo: Boolean;
begin
  Result := VideoWindow.IsPlaying;
end;

function TDriverVideoWindow.GetShowText: Boolean;
begin
  Result := VideoWindow.TextPanel.Used;
end;

function TDriverVideoWindow.GetText: string;
begin
  Result := VideoWindow.TextPanel.Text;
end;

function TDriverVideoWindow.GetTextPanelBrightness: Integer;
begin
  Result := VideoWindow.TextPanel.Brightness;
end;

function TDriverVideoWindow.GetTextPanelColorScheme: Integer;
begin
  Result := Ord(VideoWindow.TextPanel.ColorScheme);
end;

function TDriverVideoWindow.GetTextPanelFontSize: Integer;
begin
  Result := VideoWindow.TextPanel.FontSize;
end;

function TDriverVideoWindow.GetTextPanelHeight: Integer;
begin
  Result := VideoWindow.TextPanel.HeightRelative;
end;

function TDriverVideoWindow.GetTextPanelMargin: Integer;
begin
  Result := VideoWindow.TextPanel.Margin;
end;

function TDriverVideoWindow.GetTextPanelPosition: Integer;
begin
  Result := Ord(VideoWindow.TextPanel.Position);
end;

function TDriverVideoWindow.GetTextPanelTransparency: Integer;
begin
  Result := VideoWindow.TextPanel.Transparency;
end;

function TDriverVideoWindow.GetTextPanelTransparentBg: Boolean;
begin
  Result := VideoWindow.TextPanel.TransparentBg;
end;

function TDriverVideoWindow.GetTextPanelWidth: Integer;
begin
  Result := VideoWindow.TextPanel.WidthRelative;
end;

function TDriverVideoWindow.GetVideoPanel: TVideoPanel;
begin
  if not Assigned(TVideoPanel.Obj) then
    raise Exception.Create(RsErrDeviceDisabled);
  Result := TVideoPanel.Obj;
end;

function TDriverVideoWindow.GetVideoWindow: TVideoWindow;
begin
  TVideoPanel.CheckWindowIndex(FWnidowIndex);
  Result := VideoPanel.VideoWindows[FWnidowIndex];
end;

procedure TDriverVideoWindow.SetChannel(const Value: Integer);
begin
  VideoWindow.Channel := Value;
end;

procedure TDriverVideoWindow.SetEnabled(const Value: Boolean);
begin
  VideoWindow.Used := Value;
end;

procedure TDriverVideoWindow.SetPlayLiveVideo(const Value: Boolean);
begin
  if Value then
    VideoWindow.PlayLiveVideo
  else
    VideoWindow.StopLiveVideo;
end;

procedure TDriverVideoWindow.SetShowText(const Value: Boolean);
begin
  VideoWindow.TextPanel.Used := Value;
end;

procedure TDriverVideoWindow.SetText(const Value: string);
begin
  VideoWindow.TextPanel.Text := Value;
end;

procedure TDriverVideoWindow.SetTextPanelBrightness(const Value: Integer);
begin
  CheckPercentValue(Value, True);
  VideoWindow.TextPanel.Brightness := Value;
end;

procedure TDriverVideoWindow.SetTextPanelColorScheme(const Value: Integer);
begin
  CheckColorShceme(Value);
  VideoWindow.TextPanel.ColorScheme := TColorScheme(Value);
end;

procedure TDriverVideoWindow.SetTextPanelFontSize(const Value: Integer);
begin
  VideoWindow.TextPanel.FontSize := Value;
end;

procedure TDriverVideoWindow.SetTextPanelHeight(const Value: Integer);
begin
  CheckPercentValue(Value, False);
  VideoWindow.TextPanel.HeightRelative := Value;
end;

procedure TDriverVideoWindow.SetTextPanelMargin(const Value: Integer);
begin
  VideoWindow.TextPanel.Margin := Value;
end;

procedure TDriverVideoWindow.SetTextPanelPosition(const Value: Integer);
begin
  CheckTextPanelPosition(Value);
  VideoWindow.TextPanel.Position := TWindowPosition(Value);
end;

procedure TDriverVideoWindow.SetTextPanelTransparency(const Value: Integer);
begin
  CheckPercentValue(Value, False);
  VideoWindow.TextPanel.Transparency := Value;
end;

procedure TDriverVideoWindow.SetTextPanelTransparentBg(const Value: Boolean);
begin
  VideoWindow.TextPanel.TransparentBg := Value;
end;

procedure TDriverVideoWindow.SetTextPanelWidth(const Value: Integer);
begin
  CheckPercentValue(Value, False);
  VideoWindow.TextPanel.WidthRelative := Value;
end;

procedure TDriverVideoWindow.SetWindowIndex(const Value: Integer);
begin
  TVideoPanel.CheckWindowIndex(Value);
  FWnidowIndex := Value;
end;

initialization

// Обязательная регистрация класса
TDriverVideoWindow.RegisterClass(TDriverVideoWindow, 'VideoWindow');

end.
