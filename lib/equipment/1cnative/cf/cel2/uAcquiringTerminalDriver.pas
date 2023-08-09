////////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера ЭТ для ревизии интерфейса (версии требований 1С) 2.4
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. STOI 2019
//

unit uAcquiringTerminalDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi;

const
  CUT_TAG = '[cut]';

type
  TTransactParams = record
    Amount: Currency;
    PAN: string;
    ReceiptNum: string;
    RRN: string;
    AuthCode: string;
    ReceiptText: string;
    procedure Clear;
  end;

  PTransactParams = ^TTransactParams;

  TAcquiringTerminalDriver = class(TCommonDriver)
  private
    FCurrencyCode: string;
  private
    procedure SetTransactParams(ATransacParams: PTransactParams;
      ASource: PV8ParamArray);
    procedure SetV8Params(AV8Params: PV8ParamArray; ASource: PTransactParams);
  public
    constructor Create; override;
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
  protected
    // Перегруженные абстрактные методы типа оборудования
    // Оплата покупки
    procedure PayByPaymentCard(ATransactParams: PTransactParams); overload;
      virtual; abstract;
    // Возврат покупки
    procedure ReturnPaymantByPaymantCard(ATransactParams: PTransactParams);
      overload; virtual; abstract;
    // Отмена покупки
    procedure CancelPaymentByPaymentCard(ATransactParams: PTransactParams);
      overload; virtual; abstract;
    // Преавторизация
    procedure AuthorisationByPaymentCard(ATransactParams: PTransactParams)
      overload; virtual; abstract;
    // Подтверждение преавторизации
    procedure AuthConfirmationByPaymentCard(ATransactParams: PTransactParams);
      overload; virtual; abstract;
    // Отмена преавторизации
    procedure CancelAuthorisationByPaymentCard(ATransactParams
      : PTransactParams); overload; virtual; abstract;
    // Аварийная отмена
    procedure EmergencyReversal; overload; virtual; abstract;
    // Сверка итогов
    procedure Settelment(out AReceiptText: string); overload; virtual; abstract;
    // Печать на терминале (свойство)
    function PrintSlipOnTerminal: Boolean; overload; virtual; abstract;
  public
    // Экспортируемые методы типа оборудования
    // Оплата покупки
    [ExportMethAttribute('ОплатитьПлатежнойКартой', 7)]
    function PayByPaymentCard(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Возврат покупки
    [ExportMethAttribute('ВернутьПлатежПоПлатежнойКарте', 7)]
    function ReturnPaymantByPaymantCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Отмена покупки
    [ExportMethAttribute('ОтменитьПлатежПоПлатежнойКарте', 7)]
    function CancelPaymentByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Преавторизация
    [ExportMethAttribute('ПреавторизацияПоПлатежнойКарте', 7)]
    function AuthorisationByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Подтверждение преавторизации
    [ExportMethAttribute('ЗавершитьПреавторизациюПоПлатежнойКарте', 7)]
    function AuthConfirmationByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Отмена преавторизации
    [ExportMethAttribute('ОтменитьПреавторизациюПоПлатежнойКарте', 7)]
    function CancelAuthorisationByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // Отмена последней
    [ExportMethAttribute('АварийнаяОтменаОперации', 1)]
    function EmergencyReversal(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Сверка итогов
    [ExportMethAttribute('ИтогиДняПоКартам', 2)]
    function Settelment(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // Печать на терминале (свойство)
    [ExportMethAttribute('ПечатьКвитанцийНаТерминале', 0)]
    function PrintSlipOnTerminal(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  public
    // Экспортируемые параметры
    [ExportPropAttribute('КодВалюты', 'Код валюты', '643', False)]
    property CurrencyCode: string read FCurrencyCode write FCurrencyCode;
  end;

function MaskCardNumber(const APAN: string): string;

implementation

function MaskCardNumber(const APAN: string): string;
var
  LLength: Integer;
begin
  LLength := Length(APAN);
  if LLength < 5 then
    Exit('');

  if pos('*', APAN) <= 0 then
    Result := StringOfChar('*', LLength - 4) + Copy(APAN, LLength - 3, 4)
  else
    Result := APAN;
end;

{ TAcquiringTerminalDriver }

function TAcquiringTerminalDriver.AuthConfirmationByPaymentCard
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LTransactParams: TTransactParams;
begin
  try
    SetTransactParams(@LTransactParams, Params);
    try
      AuthConfirmationByPaymentCard(@LTransactParams);
    finally
      SetV8Params(Params, @LTransactParams);
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
  LTransactParams: TTransactParams;
begin
  try
    SetTransactParams(@LTransactParams, Params);
    try
      AuthorisationByPaymentCard(@LTransactParams);
    finally
      SetV8Params(Params, @LTransactParams);
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
  LTransactParams: TTransactParams;
begin
  try
    SetTransactParams(@LTransactParams, Params);
    try
      CancelAuthorisationByPaymentCard(@LTransactParams);
    finally
      SetV8Params(Params, @LTransactParams);
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
  LTransactParams: TTransactParams;
begin
  try
    SetTransactParams(@LTransactParams, Params);
    try
      CancelPaymentByPaymentCard(@LTransactParams);
    finally
      SetV8Params(Params, @LTransactParams);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

constructor TAcquiringTerminalDriver.Create;
begin
  inherited;

  FCurrencyCode := '643';
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

procedure TAcquiringTerminalDriver.SetTransactParams(ATransacParams
  : PTransactParams; ASource: PV8ParamArray);
begin
  with ATransacParams^ do
  begin
    Clear;
    PAN := V8AsWString(@ASource[2]);
    Amount := V8AsDouble(@ASource[3]);
    ReceiptNum := V8AsWString(@ASource[4]);
    RRN := V8AsWString(@ASource[5]);
    AuthCode := V8AsWString(@ASource[6]);
    ReceiptText := '';
  end;
end;

function TAcquiringTerminalDriver.PayByPaymentCard(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LTransactParams: TTransactParams;
begin
  try
    SetTransactParams(@LTransactParams, Params);
    try
      PayByPaymentCard(@LTransactParams);
    finally
      SetV8Params(Params, @LTransactParams);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.PrintSlipOnTerminal(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  V8SetBool(RetValue, PrintSlipOnTerminal);
  Result := True;
end;

function TAcquiringTerminalDriver.ReturnPaymantByPaymantCard
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LTransactParams: TTransactParams;
begin
  try
    SetTransactParams(@LTransactParams, Params);
    try
      ReturnPaymantByPaymantCard(@LTransactParams);
    finally
      SetV8Params(Params, @LTransactParams);
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

procedure TAcquiringTerminalDriver.SetV8Params(AV8Params: PV8ParamArray;
  ASource: PTransactParams);
begin
  with ASource^ do
  begin
    V8SetWString(@AV8Params[2], MaskCardNumber(PAN));
    V8SetDouble(@AV8Params[3], Amount);
    V8SetWString(@AV8Params[4], ReceiptNum);
    V8SetWString(@AV8Params[5], RRN);
    V8SetWString(@AV8Params[6], AuthCode);
    V8SetWString(@AV8Params[7], ReceiptText);
  end;
end;

class procedure TAcquiringTerminalDriver.UpdateDriverInfo(
  ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etAcquiringTerminal;
end;

{ TTransactParams }

procedure TTransactParams.Clear;
begin
  Amount := 0;
  PAN := '';
  ReceiptNum := '';
  RRN := '';
  AuthCode := '';
  ReceiptText := '';
end;

end.
