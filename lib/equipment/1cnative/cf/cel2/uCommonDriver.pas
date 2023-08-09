/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера ТО для ревизии интерфейса (версии требований 1С) 2.4
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. STOI 2019
//

unit uCommonDriver;

interface

uses uCustomDriver, v8napi, System.SysUtils, Xml.XMLDoc, Xml.XMLIntf,
  System.Classes, Winapi.Windows, System.Rtti, System.Variants, uMarkdownRenderer;

const
  INTERFACE_REVISION = 2004;
  RESOURCENAME_PARAMS = 'Parameters';
  DEF_DOWNLOADURL = 'https://rarus.ru/';
  DEF_HELPFILENAME = 'help';

const
  ERR_ACTIONNOTFOUND = 'Action not found';

type
  TEquipmentType = class
  public type
    TValue = (etScanner, etMCR, etFR, etReceiptPrinter, etLabelPrinter,
      etCustomerDisplay, etDataCollectionTerminal, etAcquiringTerminal, etScale,
      etPrintingScale, etRFIDReader, etECR, etVideocamera, etVideorecorder, etUnknown);
  protected
    class function GetName(AValue: TEquipmentType.TValue): string; static;
  public
    class property Name[Index: TEquipmentType.TValue]: string read GetName;
  end;

  TDriverInfo = packed record
    Name: string;
    Description: string;
    EquipmentType: TEquipmentType.TValue;
    InterfaceRevision: Integer;
    IntegrationLibrary: Boolean;
    MainDriverInstalled: Boolean;
    DownloadURL: string;
    procedure Clear;
  end;

  PDriverInfo = ^TDriverInfo;

  TCommonDriver = class(TCustomDriver)
  private
    FEnabled: Boolean;
  public
    class var DriverInfo: TDriverInfo;
  public
    constructor Create; override;
    destructor Destroy; override;
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); virtual;
    class procedure RegisterDriver(AClass: TClass;
      const AExtension, AName, ADescription: string);
  private
    // Лог
    procedure SetLogEnabled(const Value: Boolean);
    function GetLogEnabled: Boolean;
  protected
    procedure CheckEnabled;
    // Реализация общих методов
    procedure Open; overload; virtual;
    procedure Close; overload; virtual;
    procedure DeviceTest(out ADescription, ADemoModeIsActivated: string);
      overload; virtual;
    function GetParameters: WideString; overload; virtual;
    function GetAdditionalActions: WideString; overload; virtual;
    procedure DoAdditionalAction(const AAction: string); overload; virtual;
  public
    // Экспортируемы общие методы
    [ExportMethAttribute('ПолучитьНомерВерсии', 0)]
    function GetVersion(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
    [ExportMethAttribute('ПолучитьОписание', 7)]
    function GetDescription(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; virtual;
    [ExportMethAttribute('ПолучитьОшибку', 1)]
    function GetLastError(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
    [ExportMethAttribute('Подключить', 1)]
    function Open(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('Отключить', 1)]
    function Close(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('ПолучитьПараметры', 1)]
    function GetParameters(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('УстановитьПараметр', 2)]
    function SetParameter(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
    [ExportMethAttribute('ТестУстройства', 2)]
    function DeviceTest(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('ПолучитьДополнительныеДействия', 1)]
    function GetAdditionalActions(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    [ExportMethAttribute('ВыполнитьДополнительноеДействие', 1)]
    function DoAdditionalAction(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  public
    // Дополнительные экспортируемые методы
    [AdditionalActionAttribute('Просмотр лога')]
    procedure ViewLog;
    [AdditionalActionAttribute('Справка')]
    procedure ShowHelp;
  public
    property Enabled: Boolean read FEnabled;
  public
    // Экспортируемые общие параметры
    [ExportPropAttribute('ЛогВключен', 'Вести лог', 'False', False)]
    property LogEnabled: Boolean read GetLogEnabled write SetLogEnabled;
  end;

implementation

uses uVInfo, Common.Log, ufmLog, uEquipmentErrors;

resourcestring
  RsParameters = 'Параметры';
  RsHelp = 'Справка';

function RttiTypeToParamType(ARttiType: TRttiType): TParamType.TValue;
begin
  case ARttiType.TypeKind of
    tkInteger, tkFloat, tkInt64:
      Result := ptNumber;
    tkChar, tkString, tkWChar, tkLString, tkWString, tkUString:
      Result := ptString;
    tkEnumeration:
      begin
        if ARttiType.ToString = 'Boolean' then
          Result := ptBoolean
        else
          Result := ptUnknown
      end;
  else
    Result := ptUnknown;
  end;
end;

{ TCommonDriver }

procedure TCommonDriver.CheckEnabled;
begin
  if not Enabled then
    raise EquException.Create(ERR_DeviceDisabled, S_ERR_DeviceDisabled);
end;


function TCommonDriver.Close(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
begin
  try
    Close;
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

procedure TCommonDriver.Close;
begin
  FEnabled := False;
end;

constructor TCommonDriver.Create;
begin
  inherited;
  UpdateDriverInfo(@DriverInfo);
end;

destructor TCommonDriver.Destroy;
begin
  Close;
  inherited;
end;

function TCommonDriver.DeviceTest(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LDescription, LDemoModeIsActivated: string;
begin
  try
    DeviceTest(LDescription, LDemoModeIsActivated);

    V8SetWString(@Params[1], LDescription);
    V8SetWString(@Params[2], LDemoModeIsActivated);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

procedure TCommonDriver.DoAdditionalAction(const AAction: string);
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
  LAttribute: TCustomAttribute;
  LFound: Boolean;
begin
  LFound := False;

  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(self.ClassType);
    for LMethod in LType.GetMethods do
      for LAttribute in LMethod.GetAttributes do
        if LAttribute is AdditionalActionAttribute then
          if LMethod.Name = AAction then
          begin
            LFound := True;
            LMethod.Invoke(self, []);
            Break;
          end;
  finally
    LCtx.Free;
  end;

  if not LFound then
    raise Exception.Create(ERR_ACTIONNOTFOUND);
end;

function TCommonDriver.DoAdditionalAction(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    DoAdditionalAction(V8AsWString(@Params[1]));
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

procedure TCommonDriver.DeviceTest(out ADescription,
  ADemoModeIsActivated: string);
begin
  ADescription := '';
  ADemoModeIsActivated := '';

  try
    try
      Open;
      ADescription := DriverInfo.Description;
    finally
      Close;
    end;
  except
    ADescription := Exception(ExceptObject).Message;
  end;
end;

function TCommonDriver.GetAdditionalActions(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    V8SetWString(@Params[1], GetAdditionalActions);
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TCommonDriver.GetAdditionalActions: WideString;
var
  LDoc: IXMLDocument;
  LNode, LAction: IXMLNode;
  LCtx: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
  LAttribute: TCustomAttribute;
begin
  LDoc := NewXMLDocument;
  LNode := LDoc.AddChild('Actions');

  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(self.ClassType);
    for LMethod in LType.GetMethods do
      for LAttribute in LMethod.GetAttributes do
        if LAttribute is AdditionalActionAttribute then
          with AdditionalActionAttribute(LAttribute) do
          begin
            LAction := LNode.AddChild('Action');
            LAction.Attributes['Name'] := LMethod.Name;
            LAction.Attributes['Caption'] := Caption;
          end;
  finally
    LCtx.Free;
  end;

  Result := LDoc.Xml.Text;
end;

function TCommonDriver.GetDescription(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    V8SetWString(@Params[1], DriverInfo.Name);
    V8SetWString(@Params[2], DriverInfo.Description);
    V8SetWString(@Params[3], TEquipmentType.Name[DriverInfo.EquipmentType]);
    V8SetInt(@Params[4], INTERFACE_REVISION);
    V8SetBool(@Params[5], DriverInfo.IntegrationLibrary);
    V8SetBool(@Params[6], DriverInfo.MainDriverInstalled);
    V8SetWString(@Params[7], DriverInfo.DownloadURL);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TCommonDriver.GetLastError(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
begin
  V8SetInt(RetValue, LastResult.GetIntResult);
  V8SetWString(@Params[1], LastResult.ErrorDescription);

  Result := True;
end;

function TCommonDriver.GetLogEnabled: Boolean;
begin
  Result := TLog.Level > llNone;
end;

function TCommonDriver.GetParameters: WideString;
var
  LDoc: IXMLDocument;
  LNode, LParam: IXMLNode;
  LResource: TResourceStream;
  LCtx: TRttiContext;
  LType: TRttiType;
  LProperty: TRttiProperty;
  LAttribute: TCustomAttribute;
begin
  LDoc := NewXMLDocument;

  // Заполним параметры из xml файла 'Parameters' в ресурсах, если он есть
  if (FindResource(hInstance, PChar(RESOURCENAME_PARAMS), RT_RCDATA) <> 0) then
  begin
    LResource := TResourceStream.Create(hInstance, RESOURCENAME_PARAMS,
      RT_RCDATA);
    try
      LDoc.LoadFromStream(LResource);
    finally
      LResource.Free;
    end;
  end
  else
  // Заполним по-умолчанию. По списку свойств. Хоть что-то...
  begin
    LNode := LDoc.AddChild('Settings').AddChild('Page');
    LNode.Attributes['Caption'] := RsParameters;

    LCtx := TRttiContext.Create;
    try
      LType := LCtx.GetType(self.ClassType);
      for LProperty in LType.GetProperties do
        for LAttribute in LProperty.GetAttributes do
          if LAttribute is ExportPropAttribute then
            with ExportPropAttribute(LAttribute) do
            begin
              LParam := LNode.AddChild('Parameter');
              LParam.Attributes['Name'] := LProperty.Name;
              LParam.Attributes['Caption'] := Caption;
              LParam.Attributes['TypeValue'] := TParamType.Name
                [RttiTypeToParamType(LProperty.PropertyType)];
              LParam.Attributes['DefaultValue'] := DefValue;
              LParam.Attributes['ReadOnly'] := ReadOnly;
            end;
    finally
      LCtx.Free;
    end;
  end;

  Result := LDoc.Xml.Text;
end;

function TCommonDriver.GetParameters(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    V8SetWString(@Params[1], GetParameters);
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TCommonDriver.GetVersion(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
begin
  V8SetWString(RetValue, GetFileVerStr);
  Result := True;
end;

procedure TCommonDriver.Open;
begin
  FEnabled := True;
end;

function TCommonDriver.Open(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
begin
  try
    Open;
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

class procedure TCommonDriver.RegisterDriver(AClass: TClass;
  const AExtension, AName, ADescription: string);
begin
  inherited RegisterDriver(AClass, AExtension);

  DriverInfo.Name := AName;
  DriverInfo.Description := ADescription;
  UpdateDriverInfo(@DriverInfo);
end;

class procedure TCommonDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  DriverInfo.Clear;
  DriverInfo.DownloadURL := DEF_DOWNLOADURL;
end;

procedure TCommonDriver.ViewLog;
begin
  with TfrmLog.Create(nil) do
    try
      ShowModal;
    finally
      Free;
    end;
end;

procedure TCommonDriver.SetLogEnabled(const Value: Boolean);
begin
  if Value then
    TLog.Level := llDebug
  else
    TLog.Level := llNone;
end;

function TCommonDriver.SetParameter(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
begin
  try
    PropertySet(V8AsWString(@Params[1]), @Params[2]);
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

procedure TCommonDriver.ShowHelp;
begin
  TMarkdownRenderer.Render(DEF_HELPFILENAME, RsHelp);
end;

{ TEquipmentType }

class function TEquipmentType.GetName(AValue: TEquipmentType.TValue): string;
begin
  case AValue of
    etScanner:
      Result := 'СканерШтрихкода';
    etMCR:
      Result := 'СчитывательМагнитныхКарт';
    etFR:
      Result := 'ФискальныйРегистратор';
    etReceiptPrinter:
      Result := 'ПринтерЧеков';
    etLabelPrinter:
      Result := 'ПринтерЭтикеток';
    etCustomerDisplay:
      Result := 'ДисплейПокупателя';
    etDataCollectionTerminal:
      Result := 'ТерминалСбораДанных';
    etAcquiringTerminal:
      Result := 'ЭквайринговыйТерминал';
    etScale:
      Result := 'ЭлектронныеВесы';
    etPrintingScale:
      Result := 'ВесыСПечатьюЭтикеток';
    etRFIDReader:
      Result := 'СчитывательRFID';
    etECR:
      Result := 'ККТ';
    etVideocamera:
      Result := 'Видеокамера';
    etVideorecorder:
      Result := 'Видеорегистратор';
     etUnknown:
      Result := 'НеизвестныйТипОборудования';
  else
    raise Exception.Create(ERR_ENUMVALUE);
  end;
end;

{ TDriverInfo }

procedure TDriverInfo.Clear;
begin
  EquipmentType := etUnknown;
  InterfaceRevision := INTERFACE_REVISION;
  IntegrationLibrary := False;
  MainDriverInstalled := False;
  DownloadURL := '';
end;

initialization

end.
