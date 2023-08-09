/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера ТО для ревизии интерфейса (версии требований 1С) 3.2
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. ANTARA 2020
//

unit uCommonDriver;

interface

uses uCustomDriver, v8napi, System.SysUtils, Xml.XMLDoc, Xml.XMLIntf,
  System.Classes, Winapi.Windows, System.Rtti, System.Variants, System.Generics.Collections,
  uMarkdownRenderer;

const
  RESOURCENAME_PARAMS = 'Parameters';
  DEF_DOWNLOADURL = 'https://rarus.ru/';
  DEF_HELPFILENAME = 'help';

const
  ERR_ACTIONNOTFOUND = 'Action not found';

type
  TDictionaryHelpers<TKey, TValue> = class
  public
    class procedure CopyDictionary(ASource, ATarget: TDictionary<TKey, TValue>);
  end;

  TSettings = TDictionary<string, Variant>;

  TEquipmentType = class
  public type
    TValue = (etScanner, etMCR, etFR, etReceiptPrinter, etLabelPrinter,
      etCustomerDisplay, etDataCollectionTerminal, etAcquiringTerminal, etScale,
      etPrintingScale, etRFIDReader, etECR, etVideocamera, etElectronicLock, etUnknown);
  protected
    class function GetName(AValue: TEquipmentType.TValue): string; static;
  public
    class property Name[Index: TEquipmentType.TValue]: string read GetName;
  end;

  TDriverInfo = packed record
    Name: string;
    Description: string;
    EquipmentType: TEquipmentType.TValue;
    IntegrationComponent: Boolean;
    MainDriverInstalled: Boolean;
    DriverVersion: string;
    IntegrationComponentVersion: string;
    DownloadURL: string;
    LogIsEnabled: Boolean;
    LogPath: string;
    procedure Clear;
  end;

  PDriverInfo = ^TDriverInfo;

  TCommonDriver = class(TCustomDriver)
  private
    FEnabled: Boolean;
    FCurrentDeviceID: string;
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
    FSettings: TSettings;
    FListSettings: TObjectDictionary<string, TSettings>;
    procedure CheckEnabled(const ADeviceID: string = '');
    function GetInterfaceRevision: Integer; overload; virtual;
    // Реализация общих методов
    procedure Open; overload; virtual;
    procedure Close; overload; virtual;
    procedure DeviceTest(out ADescription, ADemoModeIsActivated: string);
      overload; virtual;
    function GetParameters: WideString; overload; virtual;
    function GetDescription: WideString; overload; virtual;
    function GetAdditionalActions: WideString; overload; virtual;
    procedure DoAdditionalAction(const AAction: string); overload; virtual;
  public
    // Экспортируемы общие методы
    [ExportMethAttribute('ПолучитьРевизиюИнтерфейса', 0)]
    function GetInterfaceRevision(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload; virtual;
    [ExportMethAttribute('ПолучитьОписание', 1)]
    function GetDescription(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
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

const
  INTERFACE_REVISION = 3002;

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

procedure TCommonDriver.CheckEnabled(const ADeviceID: string);
{$IFDEF Use_DeviceId)}
var
  LSettings: TSettings;
  LKey: string;
{$ENDIF}
begin
{$IFDEF Use_DeviceId)}
  if (Trim(ADeviceID) <> '') and (not FListSettings.ContainsKey(ADeviceID)) then
    raise Exception.Create(
      Format('Экземпляр устройства c идентификатором %s не существует или уже был отключен', [ADeviceID]))
  else
  if (Trim(ADeviceID) = '') then
    raise Exception.Create('Не передан идентификатор устройства');

  if (FCurrentDeviceID <> ADeviceID) then
  begin
    FListSettings.TryGetValue(ADeviceID, LSettings);
    for LKey in LSettings.Keys do
      PropertySet(LKey, LSettings[LKey]);
    FCurrentDeviceID := ADeviceID;
    try
      Close;
      Open;
    except
      FCurrentDeviceID := '';
      raise;
    end;
  end;
{$ELSE}
  if (not Enabled) then
    raise EquException.Create(ERR_DeviceDisabled, S_ERR_DeviceDisabled);
{$ENDIF}
end;

function TCommonDriver.Close(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
begin
  try
{$IFDEF Use_DeviceId)}
    if (Trim(V8AsWString(@Params[1])) = '') then
      raise Exception.Create('Не передан идентификатор устройства');
    if (not FListSettings.ContainsKey((Trim(V8AsWString(@Params[1]))))) then
      TLog.Append('Exception', Format('Экземпляр устройства c идентификатором %s не существует или уже был отключен',
        [(Trim(V8AsWString(@Params[1])))]), mtError)
    else
      FListSettings.Remove(V8AsWString(@Params[1]));
{$ELSE}
    Close;
{$ENDIF}
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
  FSettings := TSettings.Create;
  FListSettings := TObjectDictionary<string, TSettings>.Create([doOwnsValues]);
end;

destructor TCommonDriver.Destroy;
begin
  Close;
  FreeAndNil(FSettings);
  FreeAndNil(FListSettings);

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
    V8SetWString(@Params[1], Exception(ExceptObject).Message);
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
    raise Exception.Create(ADescription);
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

function TCommonDriver.GetDescription: WideString;
var
  LDoc: IXMLDocument;
  LNode: IXMLNode;
begin
  LDoc := NewXMLDocument;
  LNode := LDoc.AddChild('DriverDescription');
  LNode.Attributes['Name'] := DriverInfo.Name;
  LNode.Attributes['Description'] := DriverInfo.Description;
  LNode.Attributes['EquipmentType'] := TEquipmentType.Name
    [DriverInfo.EquipmentType];
  LNode.Attributes['IntegrationComponent'] := DriverInfo.IntegrationComponent;
  LNode.Attributes['MainDriverInstalled'] := DriverInfo.MainDriverInstalled;
  LNode.Attributes['DriverVersion'] := DriverInfo.DriverVersion;
  LNode.Attributes['IntegrationComponentVersion'] :=
    DriverInfo.IntegrationComponentVersion;
  LNode.Attributes['DownloadURL'] := DriverInfo.DownloadURL;
  LNode.Attributes['LogIsEnabled'] := LogEnabled;
  LNode.Attributes['LogPath'] := TLog.GetAbsolutePath(True);
  Result := LDoc.Xml.Text;
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
    V8SetWString(@Params[1], GetDescription);
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

function TCommonDriver.GetInterfaceRevision: Integer;
begin
  Result := INTERFACE_REVISION;
end;

function TCommonDriver.GetInterfaceRevision(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  V8SetInt(RetValue, GetInterfaceRevision);
  Result := True;
end;

procedure TCommonDriver.Open;
begin
  FEnabled := True;
end;

function TCommonDriver.Open(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
{$IFDEF Use_DeviceId)}
var
  LDeviceID: string;
  LSettings: TSettings;
{$ENDIF}
begin
  try
    Open;
{$IFDEF Use_DeviceId)}
    LDeviceID := Copy(TGUID.NewGuid.ToString, 2, 36);
    FCurrentDeviceID := LDeviceID;
    LSettings := TSettings.Create();
    TDictionaryHelpers<string, Variant>.CopyDictionary(FSettings, LSettings);
    FListSettings.AddOrSetValue(LDeviceID, LSettings);
    V8SetWString(@Params[1], LDeviceID);
    FSettings.Clear;
{$ENDIF}
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

  TLog.FileName := AExtension;
end;

class procedure TCommonDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  DriverInfo.Clear;
  DriverInfo.DownloadURL := DEF_DOWNLOADURL;
  DriverInfo.DriverVersion := GetFileVerStr;
  DriverInfo.IntegrationComponentVersion := DriverInfo.DriverVersion;
  DriverInfo.LogIsEnabled := False;
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
{$IFDEF Use_DeviceId)}
    FSettings.TryAdd(V8AsWString(@Params[1]), V8ToVariant(@Params[2]));
{$ENDIF}
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
    etElectronicLock:
      Result := 'ЭлектронныйЗамок';
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
  IntegrationComponent := False;
  MainDriverInstalled := False;
  LogIsEnabled := False;
  DownloadURL := '';
end;

{ TDictionaryHelpers<TKey, TValue> }

class procedure TDictionaryHelpers<TKey, TValue>.CopyDictionary(ASource, ATarget: TDictionary<TKey, TValue>);
var
  LKey: TKey;
begin
  for LKey in ASource.Keys do
    ATarget.Add(LKey, ASource.Items[LKey]);
end;

initialization

end.
