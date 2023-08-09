/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера ККТ-online для ревизии интерфейса (версии требований 1С) 3.4
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. STOI 2019
//

unit uEcrDriver;

interface

uses System.SysUtils, uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

type
  TSessionState = (ssClosed = 1, ssOpened = 2, ssExpired = 3);
  TOutputParams = set of (opShiftNumber, opCheckNumber, opShiftClosingCheckNumber, opDateTime, opShiftState,
    opCountersOperationType1, opCountersOperationType2, opCountersOperationType3, opCountersOperationType4,
    opBacklogDocumentsCounter, opCashBalance, opBacklogDocumentFirstNumber, opBacklogDocumentFirstDateTime,
    opFNError, opFNOverflow, opFNFail, opPayments, opCashInOutcome, opKKTShortState);

  TEcrlDriver = class(TCommonDriver)
  private
    procedure SetError(AExceptObject: TObject; const ARetValue: PV8Variant); overload;
  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
    constructor Create; override;
    destructor Destroy; override;
  protected
    // Перегруженные абстрактные методы типа оборудования
    // Получение параметров ККТ
    procedure GetDataKKT(ATableParametersKKT: IXMLDocument); overload; virtual; abstract;
    // Операции с ФН
    procedure OperationFN(AOperationType: Byte;
      AParametersFiscal: IXMLDocument); overload; virtual; abstract;
    // Открытие смены
    procedure OpenShift(InputParameters, OutputParameters: IXMLDocument); overload; virtual; abstract;
    // Закрытие смены
    procedure CloseShift(InputParameters, OutputParameters: IXMLDocument); overload; virtual; abstract;
    // Печать чека
    procedure ProcessCheck(AElectronically: Boolean;
      ACheckPackage, AOutputParameters: IXMLDocument; const AIsCorrection: boolean = false); overload; virtual; abstract;
    // Печать чека коррекции
    procedure ProcessCorrectionCheck(ACheckCorrectionPackage, AOutputParameters: IXMLDocument); overload; virtual; abstract;
    // Печать текстового документа
    procedure PrintTextDocument(ADocumentPackage: IXMLDocument); overload; virtual; abstract;
    // Внесение/Выемка
    procedure CashInOutcome(AInputParameters: IXMLDocument;
      const AAmount: Currency); overload; virtual; abstract;
    // Отчет без гашения
    procedure PrintXReport(AInputParameters: IXMLDocument); overload; virtual; abstract;
    // Получение статуса
    procedure GetCurrentStatus(AInputParameters, AOutputParameters: IXMLDocument); overload; virtual; abstract;
    // Отчет о текущем состоянии расчетов
    procedure ReportCurrentStatusOfSettlements(AInputParameters,
      AOutputParameters: IXMLDocument); overload; virtual; abstract;
    // Открыть ящик
    procedure OpenCashDrawer; overload; virtual; abstract;
    // Получение ширины строки
    procedure GetLineLength(out ALineLength: Int64); overload; virtual; abstract;
    // Печать копии чека
    procedure PrintCheckCopy(const ACheckNumber: string); overload; virtual; abstract;
    // Открыть сессию регистрации контрольных марок
    procedure OpenSessionRegistrationKM; overload; virtual; abstract;
    // Закрыть сессию регистрации контрольных марок
    procedure CloseSessionRegistrationKM; overload; virtual; abstract;
    // Формирование запроса проверки кода маркировки
    procedure RequestKM(AInputParameters, AOutputParameters: IXMLDocument); overload; virtual; abstract;
    // Формирование результатов проверки кода маркировки
    procedure GetProcessingKMResult(AOutputParameters: IXMLDocument; out ARequestStatus: Integer); overload; virtual; abstract;
    // Подтверждение выбытия проверенного ранее КМ
    procedure ConfirmKM(const AGUID: string; const AConfirmationType: Integer); overload; virtual; abstract;
    // Установка даты и времени
    procedure SetDateTime(const ADateTime: string); overload; virtual; abstract;
    // Получение даты и времени
    procedure GetDateTime(out ADateTime: string); overload; virtual; abstract;
    // Получение данных по документу
    procedure GetDocumentInformation(const ADocNumber: Integer; AOutputParameters: IXMLDocument); overload; virtual; abstract;
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
    [ExportMethAttribute('ОткрытьСмену', 3)]
    function OpenShift(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Закрытие смены
    [ExportMethAttribute('ЗакрытьСмену', 3)]
    function CloseShift(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Печать чека
    [ExportMethAttribute('СформироватьЧек', 4)]
    function ProcessCheck(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Печать чека коррекции
    [ExportMethAttribute('СформироватьЧекКоррекции', 3)]
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
    [ExportMethAttribute('ПолучитьТекущееСостояние', 3)]
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
    // Печать копии чека (PrintCheckCopy)
    [ExportMethAttribute('НапечататьКопиюЧека', 2)]
    function PrintCheckCopy(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Открыть сессию регистрации контрольных марок
    [ExportMethAttribute('ОткрытьСессиюРегистрацииКМ', 1)]
    function OpenSessionRegistrationKM(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Закрыть сессию регистрации контрольных марок
    [ExportMethAttribute('ЗакрытьСессиюРегистрацииКМ', 1)]
    function CloseSessionRegistrationKM(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Формирование запроса проверки кода маркировки
    [ExportMethAttribute('ЗапросКМ', 3)]
    function RequestKM(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Формирование результатов проверки кода маркировки
    [ExportMethAttribute('ПолучитьРезультатыЗапросаКМ', 3)]
    function GetProcessingKMResult(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Подтверждение выбытия проверенного ранее КМ
    [ExportMethAttribute('ПодтвердитьКМ', 3)]
    function ConfirmKM(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Установка даты и времени
    [ExportMethAttribute('УстановитьДатуВремя', 2)]
    function SetDateTime(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Получение  даты и времени
    [ExportMethAttribute('ПолучитьДатуВремя', 2)]
    function GetDateTime(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Получение данных по документу
    [ExportMethAttribute('ПолучитьИнформациюПоДокументу', 3)]
    function GetDocumentInformation(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  public
    // Экспортируемые параметры
  end;

implementation
uses uCommonUtils, uXMLDialog, uEquipmentErrors;

{ TEcrlDriver }

function TEcrlDriver.CashInOutcome(RetValue: PV8Variant; Params: PV8ParamArray;
  const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters: IXMLDocument;
  LAmount: Currency;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    {$IF Defined(DEBUG) and not(Defined(EDS))}
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

function TEcrlDriver.CloseSessionRegistrationKM(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    CloseSessionRegistrationKM;

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
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    {$IF Defined(DEBUG) and not(Defined(EDS))}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}
    LOutputParameters := NewXMLDocument;
    CloseShift(LInputParameters, LOutputParameters);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.ConfirmKM(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    ConfirmKM(V8AsWString(@Params[2]), V8AsInt(@Params[3]));
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

constructor TEcrlDriver.Create;
begin
  inherited;
  {$IF Defined(DEBUG) and not(Defined(EDS))}
  if not Assigned(fmXmlDialog) then
    fmXmlDialog := TfmXmlDialog.Create(nil);
  {$ENDIF}
end;

destructor TEcrlDriver.Destroy;
begin
  {$IF Defined(DEBUG) and not(Defined(EDS))}
  FreeAndNil(fmXmlDialog);
  {$ENDIF}
  inherited;
end;

function TEcrlDriver.GetCurrentStatus(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters, LOutputParameters: IXMLDocument;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    {$IF Defined(DEBUG) and not(Defined(EDS))}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}

    LOutputParameters := NewXMLDocument;
    GetCurrentStatus(LInputParameters, LOutputParameters);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);
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
    CheckEnabled(V8AsWString(@Params[1]));
    LTableParametersKKT := NewXMLDocument;
    GetDataKKT(LTableParametersKKT);
    V8SetWString(@Params[2], LTableParametersKKT.Xml.Text);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.GetDateTime(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LDateTime: string;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    GetDateTime(LDateTime);
    V8SetWString(@Params[2], LDateTime);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.GetDocumentInformation(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LOutputParameters: IXMLDocument;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    LOutputParameters := NewXMLDocument;
    GetDocumentInformation(V8AsInt(@Params[2]), LOutputParameters);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);

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
    CheckEnabled(V8AsWString(@Params[1]));
    GetLineLength(LLineLength);
    V8SetInt(@Params[2], LLineLength);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.GetProcessingKMResult(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LOutputParameters: IXMLDocument;
  LRequestStatus: Integer;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    LOutputParameters := NewXMLDocument;
    GetProcessingKMResult(LOutputParameters, LRequestStatus);
    V8SetWString(@Params[2], LOutputParameters.Xml.Text);
    V8SetInt(@Params[3], LRequestStatus);

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
    CheckEnabled(V8AsWString(@Params[1]));
    OpenCashDrawer;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.OpenSessionRegistrationKM(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    OpenSessionRegistrationKM;

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
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    {$IF Defined(DEBUG) and not(Defined(EDS))}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}
    LOutputParameters := NewXMLDocument;
    OpenShift(LInputParameters, LOutputParameters);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);

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
    CheckEnabled(V8AsWString(@Params[1]));
    LOperationType := V8AsInt(@Params[2]);
    {$IF Defined(DEBUG) and not(Defined(EDS))}
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

function TEcrlDriver.PrintCheckCopy(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    PrintCheckCopy(V8AsWString(@Params[2]));
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
    CheckEnabled(V8AsWString(@Params[1]));
    {$IF Defined(DEBUG) and not(Defined(EDS))}
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
    CheckEnabled(V8AsWString(@Params[1]));
    {$IF Defined(DEBUG) and not(Defined(EDS))}
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
  LCheckPackage, LOutputParameters: IXMLDocument;
  LElectronically: Boolean;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    LElectronically := V8AsBool(@Params[2]);
    {$IF Defined(DEBUG) and not(Defined(EDS))}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[3]);
      fmXmlDialog.ShowModal;
      LCheckPackage := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LCheckPackage := LoadXMLData(GetValidXML(V8AsWString(@Params[3])));
    {$ENDIF}
    LOutputParameters := NewXMLDocument;
    ProcessCheck(LElectronically, LCheckPackage, LOutputParameters);
    V8SetWString(@Params[4], LOutputParameters.Xml.Text);

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
  LCheckCorrectionPackage, LOutputParameters: IXMLDocument;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    {$IF Defined(DEBUG) and not(Defined(EDS))}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LCheckCorrectionPackage := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LCheckCorrectionPackage := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}
    LOutputParameters := NewXMLDocument;
    ProcessCorrectionCheck(LCheckCorrectionPackage, LOutputParameters);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);

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
    CheckEnabled(V8AsWString(@Params[1]));
    {$IF Defined(DEBUG) and not(Defined(EDS))}
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

function TEcrlDriver.RequestKM(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters, LOutputParameters: IXMLDocument;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    {$IF Defined(DEBUG) and not(Defined(EDS))}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$ENDIF}

    LOutputParameters := NewXMLDocument;
    RequestKM(LInputParameters, LOutputParameters);
    V8SetWString(@Params[3], LOutputParameters.Xml.Text);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TEcrlDriver.SetDateTime(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LDateTime: string;
begin
  try
    CheckEnabled(V8AsWString(@Params[1]));
    LDateTime := V8AsWString(@Params[2]);
    SetDateTime(LDateTime);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

procedure TEcrlDriver.SetError(AExceptObject: TObject; const ARetValue: PV8Variant);
begin
  if AExceptObject is EquException then
    SetError(AExceptObject, ARetValue, (AExceptObject as EquException).Code)
  else
    SetError(AExceptObject, ARetValue, ERR_Unknown);
end;

class procedure TEcrlDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etECR;
  DriverInfo.IntegrationComponent := false;
end;

end.
