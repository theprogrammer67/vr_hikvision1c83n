////////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера видеокамеры для ревизии интерфейса (версии требований 1С) 2.4
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. STOI 2019
//

unit uVideocameraDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi;

type

  TVideocameraDriver = class(TCommonDriver)
  private
    FPhotoFileName: string;
    FUseContour: Boolean;
    FVideoCompressorFilter: string;
    FVideoCaptureDevice: string;
    FPhotoQuality: Integer;
    FVideoFileName: string;
  public
    constructor Create; override;
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
  protected
    // Перегруженные абстрактные методы типа оборудования
    // Захват видео
    procedure StartVideoCapture(APhotoMode: Boolean; const AFileName: string;
      AUseContour: Boolean); overload; virtual; abstract;
    // Захват видео и запись
    procedure StartVideoRecord(AShowPreview: Boolean; const AFileName: string);
      overload; virtual; abstract;
    // Останов захвата
    procedure StopVideo; overload; virtual; abstract;
    // Захват видео и создание снимка
    procedure MakePhoto(const AFileName: string); overload; virtual; abstract;
  public
    // Экспортируемые методы типа оборудования
    // Захват видео
    [ExportMethAttribute('СтартВидеоЗахвата', 3)]
    function StartVideoCapture(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Захват видео и запись
    [ExportMethAttribute('СтартВидеоЗаписи', 2)]
    function StartVideoRecord(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Останов захвата
    [ExportMethAttribute('СтопВидео', 0)]
    function StopVideo(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Захват видео и создание снимка
    [ExportMethAttribute('СделатьФотоснимок', 1)]
    function MakePhoto(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  public
    // Экспортируемые параметры
    [ExportPropAttribute('ИмяФайлаФото', 'Имя Файла фотоснимка', '', False)]
    property PhotoFileName: string read FPhotoFileName write FPhotoFileName;
    [ExportPropAttribute('ИмяФайлаВидео', 'Имя Файла видеозаписи', '', False)]
    property VideoFileName: string read FVideoFileName write FVideoFileName;
    [ExportPropAttribute('УстройствоВидеозахвата', 'Устройство видеозахвата',
      '', False)]
    property VideoCaptureDevice: string read FVideoCaptureDevice
      write FVideoCaptureDevice;
    [ExportPropAttribute('ФильтрВидеосжатия', 'Фильтр видеосжатия', '', False)]
    property VideoCompressorFilter: string read FVideoCompressorFilter
      write FVideoCompressorFilter;
    [ExportPropAttribute('КачествоФото', 'Качество фотоснимка', '50', False)]
    property PhotoQuality: Integer read FPhotoQuality write FPhotoQuality;
//    [ExportPropAttribute('ИспользоватьКонтур', 'Использовать контур',
//      'False', False)]
//    property UseContour: Boolean read FUseContour write FUseContour;
  end;

implementation

{ TVideocameraDriver }

constructor TVideocameraDriver.Create;
begin
  inherited;

  FPhotoFileName := '';
  FVideoFileName := '';
  FVideoCaptureDevice := '';
  FVideoCompressorFilter := '';
  FPhotoQuality := 50;
  FUseContour := True;
end;

function TVideocameraDriver.MakePhoto(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LFileName: string;
begin
  try
    LFileName := V8AsWString(@Params[1]);
    MakePhoto(LFileName);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideocameraDriver.StartVideoCapture(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LPhotoMode: Boolean;
  LFileName: string;
  LUseContour: Boolean;
begin
  try
    LPhotoMode := V8AsBool(@Params[1]);
    LFileName := V8AsWString(@Params[2]);
    LUseContour := V8AsBool(@Params[3]);
    StartVideoCapture(LPhotoMode, LFileName, LUseContour);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideocameraDriver.StartVideoRecord(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LShowPreview: Boolean;
  LFileName: string;
begin
  try
    LShowPreview := V8AsBool(@Params[1]);
    LFileName := V8AsWString(@Params[2]);
    StartVideoRecord(LShowPreview, LFileName);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TVideocameraDriver.StopVideo(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    StopVideo;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

class procedure TVideocameraDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etVideocamera;
end;

end.
