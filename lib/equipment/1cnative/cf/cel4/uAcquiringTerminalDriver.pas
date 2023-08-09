/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера ЭТ для ревизии интерфейса (версии требований 1С) 4.0
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. STOI 2023
//

unit uAcquiringTerminalDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

const
  CUT_TAG = '[cut]';
  INTERFACE_REVISION = 4000;

type
  TTerminalParams = record
  public
    PrintSlipOnTerminal: Boolean;
    ShortSlip: Boolean;
    CashWithdrawal: Boolean;
    ElectronicCertificates: Boolean;
    PartialCancellation: Boolean;
    ConsumerPresentedQR: Boolean;
    ListCardTransactions: Boolean;
  public
    procedure Clear;
  end;

  TCardOperation = record
    MerchantNumber: Int64;
    CardNumber: string;
    CardNumberHash: string;
    Amount: Currency;
    AmountCash: Currency;
    ElectronicCertificateAmount: Currency;
    ReturnElectronicCertificate: Currency;
    TypeOperation: string;
    AuthorizationCode: string;
    RRNCode: string;
    OperationDate: string;
    OperationTime: string;
  public
    procedure Clear;
  end;

  TCardOperations = TArray<TCardOperation>;

  TTransactParams = record
  public
    MerchantNumber: Int64;
    ConsumerPresentedQR: string;
    Amount: Currency;
    AmountCash: Currency;
    CardNumber: string;
    ReceiptNumber: string;
    RRNCode: string;
    AuthorizationCode: string;
    Slip: string;
    AmountOriginalTransaction: Currency;
    BasketID: string;
    ElectronicCertificateAmount: Currency;
    OwnFundsAmount: Currency;
    OperationStatus: Integer;
  public
    procedure Clear;
  end;

  PTransactParams = ^TTransactParams;

  TAcquiringTerminalDriver = class(TCommonDriver)
  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
  protected
    function GetInterfaceRevision: Integer; override;
    function GetTerminalId: string; virtual; abstract;
  protected
    // Перегруженные абстрактные методы типа оборудования
    // Параметры терминала
    function GetTerminalParameters: TTerminalParams; virtual; abstract;
    // Оплата покупки
    procedure PayByPaymentCard(AParams: PTransactParams); overload;
      virtual; abstract;
    // Возврат покупки
    procedure ReturnPaymantByPaymantCard(AParams: PTransactParams); overload;
      virtual; abstract;
    // Отмена покупки
    procedure CancelPaymentByPaymentCard(AParams: PTransactParams); overload;
      virtual; abstract;
    // Преавторизация
    procedure AuthorisationByPaymentCard(AParams: PTransactParams)overload;
      virtual; abstract;
    // Подтверждение преавторизации
    procedure AuthConfirmationByPaymentCard(AParams: PTransactParams); overload;
      virtual; abstract;
    // Отмена преавторизации
    procedure CancelAuthorisationByPaymentCard(AParams: PTransactParams);
      overload; virtual; abstract;
    // Выдача наличных
    procedure PayByPaymentCardWithCashWithdrawal(AParams: PTransactParams);
      overload; virtual; abstract;
    // Получить параметры карты
    procedure GetCardParametrs(AFromLastOperation: Boolean;
      var AConsumerPresentedQR, ACardNumber, ACardNumberHash,
      APaymentAccountReference, ACardType: string; var AIsOwnCard: Integer);
      overload; virtual; abstract;
    // Оплата покупки электронным сертификатом
    procedure PayElectronicCertificate(AParams: PTransactParams); overload;
      virtual; abstract;
    // Возврат покупки электронным сертификатом
    procedure ReturnElectronicCertificate(AParams: PTransactParams); overload;
      virtual; abstract;
    // Аварийная отмена
    procedure EmergencyReversal; overload; virtual; abstract;
    // Операции по картам
    procedure GetOperationByCards(var AAOperations: TCardOperations); overload;
      virtual; abstract;
    // Сверка итогов
    procedure Settelment(out AReceiptText: string); overload; virtual; abstract;
  public
    // Экспортируемые методы типа оборудования
    // Параметры терминала
    [ExportMethAttribute('ПараметрыТерминала', 2)]
    function TerminalParameters(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Оплата покупки
    [ExportMethAttribute('ОплатитьПлатежнойКартой', 9)]
    function PayByPaymentCard(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Возврат покупки
    [ExportMethAttribute('ВернутьПлатежПоПлатежнойКарте', 9)]
    function ReturnPaymantByPaymantCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Отмена покупки
    [ExportMethAttribute('ОтменитьПлатежПоПлатежнойКарте', 10)]
    function CancelPaymentByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Преавторизация
    [ExportMethAttribute('ПреавторизацияПоПлатежнойКарте', 9)]
    function AuthorisationByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Подтверждение преавторизации
    [ExportMethAttribute('ЗавершитьПреавторизациюПоПлатежнойКарте', 9)]
    function AuthConfirmationByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Отмена преавторизации
    [ExportMethAttribute('ОтменитьПреавторизациюПоПлатежнойКарте', 9)]
    function CancelAuthorisationByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Выдача наличных
    [ExportMethAttribute('ОплатитьПлатежнойКартойCВыдачейНаличных', 10)]
    function PayByPaymentCardWithCashWithdrawal(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Параметры карты
    [ExportMethAttribute('ПолучитьПараметрыКарты', 8)]
    function GetCardParametrs(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Оплата покупки электронным сертификатом
    [ExportMethAttribute('ОплатитьЭлектроннымСертификатом', 12)]
    function PayElectronicCertificate(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Возврат покупки электронным сертификатом
    [ExportMethAttribute('ВернутьЭлектроннымСертификатом', 12)]
    function ReturnElectronicCertificate(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Отмена последней
    [ExportMethAttribute('АварийнаяОтменаОперации', 1)]
    function EmergencyReversal(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Операции по картам
    [ExportMethAttribute('ПолучитьОперацииПоКартам ', 2)]
    function GetOperationByCards(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Сверка итогов
    [ExportMethAttribute('ИтогиДняПоКартам', 2)]
    function Settelment(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  end;

implementation

{ TAcquiringTerminalDriver }

function TAcquiringTerminalDriver.AuthConfirmationByPaymentCard
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LParams: TTransactParams;
begin
  try
    LParams.Clear;

    LParams.MerchantNumber := V8AsInt64(@Params[2]);
    LParams.ConsumerPresentedQR := V8AsWString(@Params[3]);
    LParams.Amount := V8AsDouble(@Params[4]);
    LParams.CardNumber := V8AsWString(@Params[5]);
    LParams.ReceiptNumber := V8AsWString(@Params[6]);
    try
      AuthConfirmationByPaymentCard(@LParams);
    finally
      V8SetWString(@Params[5], LParams.CardNumber);
      V8SetWString(@Params[6], LParams.ReceiptNumber);
      V8SetWString(@Params[9], LParams.Slip);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.AuthorisationByPaymentCard
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LParams: TTransactParams;
begin
  try
    LParams.Clear;

    LParams.MerchantNumber := V8AsInt64(@Params[2]);
    LParams.ConsumerPresentedQR := V8AsWString(@Params[3]);
    LParams.Amount := V8AsDouble(@Params[4]);
    LParams.CardNumber := V8AsWString(@Params[5]);
    LParams.ReceiptNumber := V8AsWString(@Params[6]);

    try
      AuthorisationByPaymentCard(@LParams);
    finally
      V8SetWString(@Params[5], LParams.CardNumber);
      V8SetWString(@Params[6], LParams.ReceiptNumber);
      V8SetWString(@Params[7], LParams.RRNCode);
      V8SetWString(@Params[8], LParams.AuthorizationCode);
      V8SetWString(@Params[9], LParams.Slip);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.CancelAuthorisationByPaymentCard
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LParams: TTransactParams;
begin
  try
    LParams.Clear;

    LParams.MerchantNumber := V8AsInt64(@Params[2]);
    LParams.ConsumerPresentedQR := V8AsWString(@Params[3]);
    LParams.Amount := V8AsDouble(@Params[4]);
    LParams.CardNumber := V8AsWString(@Params[5]);
    LParams.ReceiptNumber := V8AsWString(@Params[6]);
    LParams.RRNCode := V8AsWString(@Params[7]);
    LParams.AuthorizationCode := V8AsWString(@Params[8]);
    try
      CancelAuthorisationByPaymentCard(@LParams);
    finally
      V8SetWString(@Params[5], LParams.CardNumber);
      V8SetWString(@Params[6], LParams.ReceiptNumber);
      V8SetWString(@Params[9], LParams.Slip);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.CancelPaymentByPaymentCard
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LParams: TTransactParams;
begin
  try
    LParams.Clear;

    LParams.MerchantNumber := V8AsInt64(@Params[2]);
    LParams.ConsumerPresentedQR := V8AsWString(@Params[3]);
    LParams.Amount := V8AsDouble(@Params[4]);
    LParams.AmountOriginalTransaction := V8AsDouble(@Params[5]);
    LParams.CardNumber := V8AsWString(@Params[6]);
    LParams.ReceiptNumber := V8AsWString(@Params[7]);
    LParams.RRNCode := V8AsWString(@Params[8]);
    LParams.AuthorizationCode := V8AsWString(@Params[9]);
    try
      CancelPaymentByPaymentCard(@LParams);
    finally
      V8SetWString(@Params[6], LParams.CardNumber);
      V8SetWString(@Params[7], LParams.ReceiptNumber);
      V8SetWString(@Params[10], LParams.Slip);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.PayByPaymentCardWithCashWithdrawal
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LParams: TTransactParams;
begin
  try
    LParams.Clear;

    LParams.MerchantNumber := V8AsInt64(@Params[2]);
    LParams.ConsumerPresentedQR := V8AsWString(@Params[3]);
    LParams.Amount := V8AsDouble(@Params[4]);
    LParams.AmountCash := V8AsDouble(@Params[5]);
    try
      PayByPaymentCardWithCashWithdrawal(@LParams);
    finally
      V8SetWString(@Params[6], LParams.CardNumber);
      V8SetWString(@Params[7], LParams.ReceiptNumber);
      V8SetWString(@Params[8], LParams.RRNCode);
      V8SetWString(@Params[9], LParams.AuthorizationCode);
      V8SetWString(@Params[10], LParams.Slip);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.EmergencyReversal(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    EmergencyReversal;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.GetCardParametrs(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LCardNumber, LCardNumberHash, LCardType, LPaymentAccountReference,
    LConsumerPresentedQR: string;
  LFromLastOperation: Boolean;
  LIsOwnCard: Integer;
begin
  try
    LConsumerPresentedQR := V8AsWString(@Params[2]);
    LFromLastOperation := V8AsBool(@Params[3]);
    LCardNumber := '';
    LCardNumberHash := '';
    LPaymentAccountReference := '';
    LCardType := 'Unknown';
    LIsOwnCard := 0;

    try
      GetCardParametrs(LFromLastOperation, LConsumerPresentedQR, LCardNumber,
        LCardNumberHash, LPaymentAccountReference, LCardType, LIsOwnCard);
    finally
      V8SetWString(@Params[4], LCardNumber);
      V8SetWString(@Params[5], LCardNumberHash);
      V8SetWString(@Params[6], LPaymentAccountReference);
      V8SetWString(@Params[7], LCardType);
      V8SetInt(@Params[8], LIsOwnCard);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.GetInterfaceRevision: Integer;
begin
  Result := INTERFACE_REVISION;
end;

function TAcquiringTerminalDriver.GetOperationByCards(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LOperations: TCardOperations;
  I: Integer;
  LDocument: IXMLDocument;
  LRoot, LNode: IXMLNode;
begin
  try
    SetLength(LOperations, 0);

    GetOperationByCards(LOperations);

    LDocument := NewXMLDocument;
    LRoot := LDocument.AddChild('Table');
    for I := Low(LOperations) to High(LOperations) do
    begin
      LNode := LRoot.AddChild('Record');
      LNode.Attributes['MerchantNumber'] := LOperations[I].MerchantNumber;
      LNode.Attributes['CardNumber'] := LOperations[I].CardNumber;
      LNode.Attributes['CardNumberHash'] := LOperations[I].CardNumberHash;
      LNode.Attributes['Amount'] := LOperations[I].Amount;
      LNode.Attributes['AmountCash'] := LOperations[I].AmountCash;
      LNode.Attributes['ElectronicCertificateAmount'] :=
        LOperations[I].ElectronicCertificateAmount;
      LNode.Attributes['ReturnElectronicCertificate'] :=
        LOperations[I].ReturnElectronicCertificate;
      LNode.Attributes['TypeOperation'] := LOperations[I].TypeOperation;
      LNode.Attributes['AuthorizationCode'] := LOperations[I].AuthorizationCode;
      LNode.Attributes['RRNCode'] := LOperations[I].RRNCode;
      LNode.Attributes['OperationDate'] := LOperations[I].OperationDate;
      LNode.Attributes['OperationTime'] := LOperations[I].OperationTime;
    end;

  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.PayByPaymentCard(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LParams: TTransactParams;
begin
  try
    LParams.Clear;

    LParams.MerchantNumber := V8AsInt64(@Params[2]);
    LParams.ConsumerPresentedQR := V8AsWString(@Params[3]);
    LParams.Amount := V8AsDouble(@Params[4]);
    LParams.CardNumber := V8AsWString(@Params[5]);
    LParams.ReceiptNumber := V8AsWString(@Params[6]);
    LParams.RRNCode := V8AsWString(@Params[7]);
    LParams.AuthorizationCode := V8AsWString(@Params[8]);
    try
      PayByPaymentCard(@LParams);
    finally
      V8SetWString(@Params[5], LParams.CardNumber);
      V8SetWString(@Params[6], LParams.ReceiptNumber);
      V8SetWString(@Params[7], LParams.RRNCode);
      V8SetWString(@Params[8], LParams.AuthorizationCode);
      V8SetWString(@Params[9], LParams.Slip);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.PayElectronicCertificate(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LParams: TTransactParams;
begin
  try
    LParams.Clear;

    LParams.MerchantNumber := V8AsInt64(@Params[2]);
    LParams.ConsumerPresentedQR := V8AsWString(@Params[3]);
    LParams.BasketID := V8AsWString(@Params[4]);
    LParams.ElectronicCertificateAmount := V8AsDouble(@Params[5]);
    LParams.OwnFundsAmount := V8AsDouble(@Params[6]);
    try
      PayElectronicCertificate(@LParams);
    finally
      V8SetWString(@Params[4], LParams.BasketID);
      V8SetWString(@Params[7], LParams.CardNumber);
      V8SetWString(@Params[8], LParams.ReceiptNumber);
      V8SetWString(@Params[9], LParams.RRNCode);
      V8SetWString(@Params[10], LParams.AuthorizationCode);
      V8SetInt(@Params[11], LParams.OperationStatus);
      V8SetWString(@Params[12], LParams.Slip);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.ReturnElectronicCertificate
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LParams: TTransactParams;
begin
  try
    LParams.Clear;

    LParams.MerchantNumber := V8AsInt64(@Params[2]);
    LParams.ConsumerPresentedQR := V8AsWString(@Params[3]);
    LParams.BasketID := V8AsWString(@Params[4]);
    LParams.ElectronicCertificateAmount := V8AsDouble(@Params[5]);
    LParams.OwnFundsAmount := V8AsDouble(@Params[6]);
    LParams.CardNumber := V8AsWString(@Params[7]);
    LParams.ReceiptNumber := V8AsWString(@Params[8]);
    LParams.RRNCode := V8AsWString(@Params[9]);
    try
      ReturnElectronicCertificate(@LParams);
    finally
      V8SetWString(@Params[4], LParams.BasketID);
      V8SetWString(@Params[7], LParams.CardNumber);
      V8SetWString(@Params[8], LParams.ReceiptNumber);
      V8SetWString(@Params[9], LParams.RRNCode);
      V8SetWString(@Params[10], LParams.AuthorizationCode);
      V8SetInt(@Params[11], LParams.OperationStatus);
      V8SetWString(@Params[12], LParams.Slip);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.ReturnPaymantByPaymantCard
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LParams: TTransactParams;
begin
  try
    LParams.Clear;

    LParams.MerchantNumber := V8AsInt64(@Params[2]);
    LParams.ConsumerPresentedQR := V8AsWString(@Params[3]);
    LParams.Amount := V8AsDouble(@Params[4]);
    LParams.CardNumber := V8AsWString(@Params[5]);
    LParams.ReceiptNumber := V8AsWString(@Params[6]);
    LParams.RRNCode := V8AsWString(@Params[7]);
    LParams.AuthorizationCode := V8AsWString(@Params[8]);
    try
      ReturnPaymantByPaymantCard(@LParams);
    finally
      V8SetWString(@Params[5], LParams.CardNumber);
      V8SetWString(@Params[6], LParams.ReceiptNumber);
      V8SetWString(@Params[7], LParams.RRNCode);
      V8SetWString(@Params[9], LParams.Slip);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.Settelment(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LReceiptText: string;
begin
  try
    Settelment(LReceiptText);
    V8SetWString(@Params[2], LReceiptText);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.TerminalParameters(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LDocument: IXMLDocument;
  LNode: IXMLNode;
  LParams: TTerminalParams;
begin
  try
    LParams := GetTerminalParameters;

    LDocument := NewXMLDocument;
    LNode := LDocument.AddChild('TerminalParameters');

    LNode.Attributes['TerminalID'] := GetTerminalId;
    LNode.Attributes['PrintSlipOnTerminal'] := LParams.PrintSlipOnTerminal;
    LNode.Attributes['ShortSlip'] := LParams.ShortSlip;
    LNode.Attributes['CashWithdrawal'] := LParams.CashWithdrawal;
    LNode.Attributes['ElectronicCertificates'] :=
      LParams.ElectronicCertificates;
    LNode.Attributes['PartialCancellation'] := LParams.PartialCancellation;
    LNode.Attributes['ConsumerPresentedQR'] := LParams.ConsumerPresentedQR;
    LNode.Attributes['ListCardTransactions'] := LParams.ListCardTransactions;

    V8SetWString(@Params[2], LDocument.Xml.Text);
    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

class procedure TAcquiringTerminalDriver.UpdateDriverInfo
  (ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etAcquiringTerminal;
end;

{ TTransactParams }

procedure TTransactParams.Clear;
begin
  MerchantNumber := 0;
  ConsumerPresentedQR := '';
  Amount := 0;
  AmountCash := 0;
  CardNumber := '';
  ReceiptNumber := '';
  RRNCode := '';
  AuthorizationCode := '';
  Slip := '';
  AmountOriginalTransaction := 0;
  BasketID := '';
  ElectronicCertificateAmount := 0;
  OwnFundsAmount := 0;
  OperationStatus := 0;
end;

{ TerminalParams }

procedure TTerminalParams.Clear;
begin
  PrintSlipOnTerminal := False;
  ShortSlip := False;
  CashWithdrawal := False;
  ElectronicCertificates := False;
  PartialCancellation := False;
  ConsumerPresentedQR := False;
  ListCardTransactions := False;
end;

{ TCardOperation }

procedure TCardOperation.Clear;
begin
  MerchantNumber := 0;
  CardNumber := '';
  CardNumberHash := '';
  Amount := 0;
  AmountCash := 0;
  ElectronicCertificateAmount := 0;
  ReturnElectronicCertificate := 0;
  TypeOperation := '';
  AuthorizationCode := '';
  RRNCode := '';
  OperationDate := '';
  OperationTime := '';
end;

end.
