unit uVideoRecorderDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi;

type

  TVideorecorderDriver = class(TCommonDriver)
  private
  public
    constructor Create; override;
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
  protected
    // Перегруженные абстрактные методы типа оборудования
    // Режим отображения окон
    procedure SetPanelMode(AMode: Integer); overload; virtual; abstract;
    function GetPanelMode: Integer; overload; virtual; abstract;
    // Включение-выключение окна
    procedure SetWindowEnabled(AIndex: Integer; AEnabled: Boolean); overload;
      virtual; abstract;
    function GetWindowEnabled(AIndex: Integer): Boolean; overload;
      virtual; abstract;
    // Воспроизведение видеопотока
    procedure SetPlayLiveVideo(AIndex: Integer; APlay: Boolean); overload;
      virtual; abstract;
    function GetPlayLiveVideo(AIndex: Integer): Boolean; overload;
      virtual; abstract;
    // Установка текста
    procedure SetText(AIndex: Integer; const AText: string); overload;
      virtual; abstract;
    function GetText(AIndex: Integer): string; overload; virtual; abstract;
    // Отображать текст
    procedure SetShowText(AIndex: Integer; AShow: Boolean); overload;
      virtual; abstract;
    function GetShowText(AIndex: Integer): Boolean; overload; virtual; abstract;
    // Установить канал
    procedure SetChannel(AIndex, AChannel: Integer); overload; virtual;
      abstract;
    function GetChannel(AIndex: Integer): Integer; overload; virtual; abstract;
    // Включить все окна
    procedure EnableWindowAll(AEnabled: Boolean); overload; virtual; abstract;
    // Включить воспроизведение для всех окон
    procedure PlayLiveAll(APlay: Boolean); overload; virtual; abstract;
    // Отобразить текст для всех окон
    procedure ShowTextAll(AShow: Boolean); overload; virtual; abstract;
  public
    // Экспортируемые методы типа оборудования
    // Режим отображения окон
    [ExportMethAttribute('УстановитьРежимПанели', 1)]
    function SetPanelMode(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('ПолучитьРежимПанели', 1)]
    function GetPanelMode(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Включение-выключение окна
    [ExportMethAttribute('УстановитьОкноВключено', 2)]
    function SetWindowEnabled(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('ПолучитьОкноВключено', 2)]
    function GetWindowEnabled(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Воспроизведение видеопотока
    [ExportMethAttribute('УстановитьВоспроизведениеПотока', 2)]
    function SetPlayLiveVideo(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('ПолучитьВоспроизведениеПотока', 2)]
    function GetPlayLiveVideo(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Установка текста
    [ExportMethAttribute('УстановитьТекст', 2)]
    function SetText(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('ПолучитьТекст', 2)]
    function GetText(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Отображать текст
    [ExportMethAttribute('УстановитьОтображатьТекст', 2)]
    function SetShowText(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('ПолучитьОтображатьТекст', 2)]
    function GetShowText(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Канал
    [ExportMethAttribute('УстановитьКанал', 2)]
    function SetChannel(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('ПолучитьКанал', 2)]
    function GetChannel(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Включить все окна
    [ExportMethAttribute('ВключитьОкноВсе', 1)]
    function EnableWindowAll(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Включить воспроизведение для всех окон
    [ExportMethAttribute('ВоспроизвестиПотокВсе', 1)]
    function PlayLiveAll(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Отображать текст для всех окон
    [ExportMethAttribute('ОтображатьТекстВсе', 1)]
    function ShowTextAll(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  end;

implementation

{ TVideorecorderDriver }

constructor TVideorecorderDriver.Create;
begin
  inherited;

end;

function TVideorecorderDriver.SetWindowEnabled(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
  LEnable: Boolean;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    LEnable := V8AsBool(@Params[2]);
    SetWindowEnabled(LIndex, LEnable);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.EnableWindowAll(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LEnable: Boolean;
begin
  try
    LEnable := V8AsBool(@Params[1]);
    EnableWindowAll(LEnable);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.SetPlayLiveVideo(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
  LPlay: Boolean;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    LPlay := V8AsBool(@Params[2]);
    SetPlayLiveVideo(LIndex, LPlay);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.SetShowText(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
  LShow: Boolean;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    LShow := V8AsBool(@Params[2]);
    SetShowText(LIndex, LShow);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.PlayLiveAll(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LPlay: Boolean;
begin
  try
    LPlay := V8AsBool(@Params[1]);
    PlayLiveAll(LPlay);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.SetChannel(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex, LChannel: Integer;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    LChannel := V8AsInt(@Params[2]);
    SetChannel(LIndex, LChannel);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.GetPlayLiveVideo(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    V8SetBool(@Params[2], GetPlayLiveVideo(LIndex));

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.GetChannel(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    V8SetInt(@Params[2], GetChannel(LIndex));

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.GetPanelMode(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    V8SetInt(@Params[1], GetPanelMode);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.SetPanelMode(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LMode: Integer;
begin
  try
    LMode := V8AsInt(@Params[1]);
    SetPanelMode(LMode);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.SetText(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
  LText: string;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    LText := V8AsWString(@Params[2]);
    SetText(LIndex, LText);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.GetShowText(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    V8SetBool(@Params[2], GetShowText(LIndex));

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.GetText(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    V8SetWString(@Params[2], GetText(LIndex));

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.GetWindowEnabled(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LIndex: Integer;
begin
  try
    LIndex := V8AsInt(@Params[1]);
    V8SetBool(@Params[2], GetWindowEnabled(LIndex));

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideorecorderDriver.ShowTextAll(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LShow: Boolean;
begin
  try
    LShow := V8AsBool(@Params[1]);
    ShowTextAll(LShow);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

class procedure TVideorecorderDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etVideorecorder;
end;

end.
