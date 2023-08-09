/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера ККТ-online для ревизии интерфейса (версии требований 1С) 2.4
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. STOI 2019
//

unit uEcrDriver;

interface

uses System.SysUtils, uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

resourcestring
  RsErrDayOpened = 'Смена открыта';
  RsErrDayClosed = 'Смена закрыта';
  RsErrDayExpired = 'Длительность смены превысила 24 часа';
  RsErrTaxValueOutOfRange = 'Налоговая группа вне допустимого диапазона';
  RsErrTaxValueCombined = 'Недопустимо сочетание налогов 20% и 18% в одном документе';
  RsErrCashLack = 'Недостаточно наличности в кассе';
  RsErrEcrNotFiscal = 'ККМ не фискализирована';
  RsErrReceiptEmpty = 'Данные для печати чека отсутствуют';
  RsErrAgentTypeOutOfRange = 'Значение признака агента по предмету расчёта вне допустимого диапазона';
  RsErrParameterMismatch = 'Ошибка входных параметров команды';

type
  TSessionState = (ssClosed = 1, ssOpened = 2, ssExpired = 3);

  TEcrlDriver = class(TCommonDriver)
  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
    constructor Create; override;
    destructor Destroy; override;
  protected
    // Перегруженные абстрактные методы типа оборудования
    // Получение параметров ККТ
    procedure GetDataKKT(ATableParametersKKT: IXMLDocument); overload;
      virtual; abstract;
    // Операции с ФН
    procedure OperationFN(AOperationType: Byte;
      AParametersFiscal: IXMLDocument); overload; virtual; abstract;
    // Открытие смены
    procedure OpenShift(InputParameters, OutputParameters: IXMLDocument;
      out ASessionNumber, ADocumentNumber: Int64); overload; virtual; abstract;
    // Закрытие смены
    procedure CloseShift(InputParameters, OutputParameters: IXMLDocument;
      out ASessionNumber, ADocumentNumber: Int64); overload; virtual; abstract;
    // Печать чека
    procedure ProcessCheck(AElectronically: Boolean;
      ACheckPackage: IXMLDocument; out ACheckNumber, ASessionNumber: Int64;
      out AFiscalSign, AAddressSiteInspections: string); overload;
      virtual; abstract;
    // Печать чека коррекции
    procedure ProcessCorrectionCheck(ACheckCorrectionPackage: IXMLDocument;
      out ACheckNumber, ASessionNumber: Int64;
      out AFiscalSign, AAddressSiteInspections: string); overload;
      virtual; abstract;
    // Печать текстового документа
    procedure PrintTextDocument(ADocumentPackage: IXMLDocument); overload;
      virtual; abstract;
    // Внесение/Выемка
    procedure CashInOutcome(AInputParameters: IXMLDocument;
      const AAmount: Currency); overload; virtual; abstract;
    // Отчет без гашения
    procedure PrintXReport(AInputParameters: IXMLDocument); overload;
      virtual; abstract;
    // Получение статуса
    procedure GetCurrentStatus(out ACheckNumber, ASessionNumber: Int64;
      out ASessionState: TSessionState; AStatusParameters: IXMLDocument);
      overload; virtual; abstract;
    // Отчет о текущем состоянии расчетов
    procedure ReportCurrentStatusOfSettlements(AInputParameters,
      AOutputParameters: IXMLDocument); overload; virtual; abstract;
    // Открыть ящик
    procedure OpenCashDrawer; overload; virtual; abstract;
    // Получение ширины строки
    procedure GetLineLength(out ALineLength: Int64); overload; virtual;
      abstract;
  public
    // Экспортируемые методы типа оборудования
    // Получение параметров ККТ
    [ExportMethAttribute('ПолучитьПараметрыККТ', 2)]
    function GetDataKKT(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Операции с ФН
    [ExportMethAttribute('ОперацияФН', 3)]
    function OperationFN(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Открытие смены
    [ExportMethAttribute('ОткрытьСмену', 5)]
    function OpenShift(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Закрытие смены
    [ExportMethAttribute('ЗакрытьСмену', 5)]
    function CloseShift(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Печать чека
    [ExportMethAttribute('СформироватьЧек', 7)]
    function ProcessCheck(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Печать чека коррекции
    [ExportMethAttribute('СформироватьЧекКоррекции', 6)]
    function ProcessCorrectionCheck(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Печать текстового документа
    [ExportMethAttribute('НапечататьТекстовыйДокумент', 2)]
    function PrintTextDocument(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Внесение/Выемка
    [ExportMethAttribute('НапечататьЧекВнесенияВыемки', 3)]
    function CashInOutcome(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Отчет без гашения
    [ExportMethAttribute('НапечататьОтчетБезГашения', 2)]
    function PrintXReport(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Получение статуса
    [ExportMethAttribute('ПолучитьТекущееСостояние', 5)]
    function GetCurrentStatus(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Отчет о текущем состоянии расчетов
    [ExportMethAttribute('ОтчетОТекущемСостоянииРасчетов', 3)]
    function ReportCurrentStatusOfSettlements(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Открыть ящик
    [ExportMethAttribute('ОткрытьДенежныйЯщик', 1)]
    function OpenCashDrawer(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Получение ширины строки
    [ExportMethAttribute('ПолучитьШиринуСтроки', 2)]
    function GetLineLength(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  public
    // Экспортируемые параметры
  end;

implementation
uses uCommonUtils, uXMLDialog;

{ TEcrlDriver }

function TEcrlDriver.CashInOutcome(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters: IXMLDocument;
  LAmount: Currency;
begin
  try
    {$IFDEF TEST}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}
    LAmount := V8AsDouble(@Params[3]);
    CashInOutcome(LInputParameters, LAmount);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.CloseShift(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters, LOutputParameters: IXMLDocument;
  LSessionNumber, LDocumentNumber: Int64;
begin
  try
    {$IFDEF TEST}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}
    LOutputParameters := NewXMLDocument;
    CloseShift(LInputParameters, LOutputParameters, LSessionNumber,
      LDocumentNumber);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);
    V8SetInt(@Params[4], LSessionNumber);
    V8SetInt(@Params[5], LDocumentNumber);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

constructor TEcrlDriver.Create;
begin
  inherited;
  {$IFDEF TEST}
  if not Assigned(fmXmlDialog) then
    fmXmlDialog := TfmXmlDialog.Create(nil);
  {$ENDIF}
end;

destructor TEcrlDriver.Destroy;
begin
  {$IFDEF TEST}
  FreeAndNil(fmXmlDialog);
  {$ENDIF}
  inherited;
end;

function TEcrlDriver.GetCurrentStatus(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LCheckNumber, LSessionNumber: Int64;
  LSessionState: TSessionState;
  LStatusParameters: IXMLDocument;
begin
  try
    LStatusParameters := NewXMLDocument;
    GetCurrentStatus(LCheckNumber, LSessionNumber, LSessionState,
      LStatusParameters);
    V8SetInt(@Params[2], LCheckNumber);
    V8SetInt(@Params[3], LSessionNumber);
    V8SetInt(@Params[4], Ord(LSessionState));
    V8SetWString(@Params[5], LStatusParameters.Xml.Text);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.GetDataKKT(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LTableParametersKKT: IXMLDocument;
begin
  try
    LTableParametersKKT := NewXMLDocument;
    GetDataKKT(LTableParametersKKT);
    V8SetWString(@Params[2], LTableParametersKKT.Xml.Text);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.GetLineLength(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LLineLength: Int64;
begin
  try
    GetLineLength(LLineLength);
    V8SetInt(@Params[2], LLineLength);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.OpenCashDrawer(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
begin
  try
    OpenCashDrawer;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.OpenShift(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters, LOutputParameters: IXMLDocument;
  LSessionNumber, LDocumentNumber: Int64;
begin
  try
    {$IFDEF TEST}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}
    LOutputParameters := NewXMLDocument;
    OpenShift(LInputParameters, LOutputParameters, LSessionNumber,
      LDocumentNumber);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);
    V8SetInt(@Params[4], LSessionNumber);
    V8SetInt(@Params[5], LDocumentNumber);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.OperationFN(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LOperationType: Byte;
  LParametersFiscal: IXMLDocument;
begin
  try
    LOperationType := V8AsInt(@Params[2]);
    {$IFDEF TEST}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[3]);
      fmXmlDialog.ShowModal;
      LParametersFiscal := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LParametersFiscal := LoadXMLData(GetValidXML(V8AsWString(@Params[3])));
    {$ENDIF}
    OperationFN(LOperationType, LParametersFiscal);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.PrintTextDocument(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LDocumentPackage: IXMLDocument;
begin
  try
    {$IFDEF TEST}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LDocumentPackage := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LDocumentPackage := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}
    PrintTextDocument(LDocumentPackage);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.PrintXReport(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters: IXMLDocument;
begin
  try
    {$IFDEF TEST}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}
    PrintXReport(LInputParameters);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.ProcessCheck(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LCheckPackage: IXMLDocument;
  LElectronically: Boolean;
  LCheckNumber, LSessionNumber: Int64;
  LFiscalSign, LAddressSiteInspections: string;
begin
  try
    LElectronically := V8AsBool(@Params[2]);
    {$IFDEF TEST}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[3]);
      fmXmlDialog.ShowModal;
      LCheckPackage := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LCheckPackage := LoadXMLData(GetValidXML(V8AsWString(@Params[3])));
    {$ENDIF}
    ProcessCheck(LElectronically, LCheckPackage, LCheckNumber, LSessionNumber,
      LFiscalSign, LAddressSiteInspections);
    V8SetInt(@Params[4], LCheckNumber);
    V8SetInt(@Params[5], LSessionNumber);
    V8SetWString(@Params[6], LFiscalSign);
    V8SetWString(@Params[7], LAddressSiteInspections);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.ProcessCorrectionCheck(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LCheckCorrectionPackage: IXMLDocument;
  LCheckNumber, LSessionNumber: Int64;
  LFiscalSign, LAddressSiteInspections: string;
begin
  try
    {$IFDEF TEST}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LCheckCorrectionPackage := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LCheckCorrectionPackage := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}
    ProcessCorrectionCheck(LCheckCorrectionPackage, LCheckNumber,
      LSessionNumber, LFiscalSign, LAddressSiteInspections);
    V8SetInt(@Params[3], LCheckNumber);
    V8SetInt(@Params[4], LSessionNumber);
    V8SetWString(@Params[5], LFiscalSign);
    V8SetWString(@Params[6], LAddressSiteInspections);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.ReportCurrentStatusOfSettlements(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters, LOutputParameters: IXMLDocument;
begin
  try
    {$IFDEF TEST}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}

    LOutputParameters := NewXMLDocument;
    ReportCurrentStatusOfSettlements(LInputParameters, LOutputParameters);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

class procedure TEcrlDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etECR;
end;

end.
