/// /////////////////////////////////////////////////////////////////////////////
//
// ������� ����� �������� �� ��� ������� ���������� (������ ���������� 1�) 3.5
// �������� 1�:���
// 1�-�����, ����� ��������� ����������. STOI 2021
//

unit uAcquiringTerminalDriver_v3004;

interface

uses uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

const
  CUT_TAG = '[cut]';
  INTERFACE_REVISION = 3007;

type
  TerminalParams = record
  public
    PrintSlipOnTerminal: Boolean;
    ShortSlip: Boolean;
    CashWithdrawal: Boolean;
    ElectronicCertificates: Boolean;
  public
    procedure Clear;
  end;

  TTransactParams = record
  public
    MerchantNumber: Int64;
    Amount: Currency;
    CardNumber: string;
    ReceiptNum: string;
    RRN: string;
    AuthCode: string;
    ReceiptText: string;
  public
    procedure Clear;
  end;

  PTransactParams = ^TTransactParams;

  TTransactParamsEc = record
  public
    MerchantNumber: Int64;
    BasketID: string;
    ElectronicCertificateAmount: Currency;
    OwnFundsAmount: Currency;
    CardNumber: string;
    ReceiptNum: string;
    RRN: string;
    AuthCode: string;
    OperationStatus: Integer;
    ReceiptText: string;
  public
    procedure Clear;
  end;

  PTransactParamsEc = ^TTransactParamsEc;

  TAcquiringTerminalDriver = class(TCommonDriver)
  private
    procedure TransParamsFromV8(AParams: PTransactParams;
      AV8Params: PV8ParamArray);
    procedure TransParamsToV8(AParams: PTransactParams;
      AV8Params: PV8ParamArray);
    procedure TransParamsEcFromV8(AParams: PTransactParamsEc;
      AV8Params: PV8ParamArray);
    procedure TransParamsEcToV8(AParams: PTransactParamsEc;
      AV8Params: PV8ParamArray);
  public
    constructor Create; override;
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
  protected
    function GetInterfaceRevision: Integer; override;
  protected
    // ������������� ����������� ������ ���� ������������
    // ������ �������
    procedure PayByPaymentCard(ATransactParams: PTransactParams); overload;
      virtual; abstract;
    // ������� �������
    procedure ReturnPaymantByPaymantCard(ATransactParams: PTransactParams);
      overload; virtual; abstract;
    // ������ �������
    procedure CancelPaymentByPaymentCard(ATransactParams: PTransactParams);
      overload; virtual; abstract;
    // ��������������
    procedure AuthorisationByPaymentCard(ATransactParams: PTransactParams)
      overload; virtual; abstract;
    // ������������� ��������������
    procedure AuthConfirmationByPaymentCard(ATransactParams: PTransactParams);
      overload; virtual; abstract;
    // ������ ��������������
    procedure CancelAuthorisationByPaymentCard(ATransactParams
      : PTransactParams); overload; virtual; abstract;
    // ������ ��������
    procedure CashWithdrawal(ATransactParams: PTransactParams); overload;
      virtual; abstract;
    // �������� ��������� �����
    procedure GetCardParametrs(AFromLastOperation: Boolean;
      var ACardNumber, ACardNumberHash, APaymentAccountReference,
      ACardType: string; var AIsOwnCard: Integer); overload; virtual; abstract;
    // ������ ������� ����������� ������������
    procedure PayElectronicCertificate(ATransactParams: PTransactParamsEc);
      overload; virtual; abstract;
    // ������� ������� ����������� ������������
    procedure ReturnElectronicCertificate(ATransactParams: PTransactParamsEc);
      overload; virtual; abstract;
    // ��������� ������
    procedure EmergencyReversal; overload; virtual; abstract;
    // ������ ������
    procedure Settelment(out AReceiptText: string); overload; virtual; abstract;
  public
    // �������������� ������ ���� ������������
    // ��������� ���������
    [ExportMethAttribute('������������������', 2)]
    function TerminalParameters(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // ������ �������
    [ExportMethAttribute('�����������������������', 8)]
    function PayByPaymentCard(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // ������� �������
    [ExportMethAttribute('�����������������������������', 8)]
    function ReturnPaymantByPaymantCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // ������ �������
    [ExportMethAttribute('������������������������������', 8)]
    function CancelPaymentByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // ��������������
    [ExportMethAttribute('������������������������������', 8)]
    function AuthorisationByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // ������������� ��������������
    [ExportMethAttribute('���������������������������������������', 8)]
    function AuthConfirmationByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // ������ ��������������
    [ExportMethAttribute('��������������������������������������', 8)]
    function CancelAuthorisationByPaymentCard(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // ������ ��������������
    [ExportMethAttribute('��������������', 8)]
    function CashWithdrawal(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // ������ ��������������
    [ExportMethAttribute('����������������������', 7)]
    function GetCardParametrs(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // ������ ������� ����������� ������������
    [ExportMethAttribute('�������������������������������', 11)]
    function PayElectronicCertificate(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // ������� ������� ����������� ������������
    [ExportMethAttribute('������������������������������', 11)]
    function ReturnElectronicCertificate(RetValue: PV8Variant;
      Params: PV8ParamArray; const ParamCount: Integer; var v8: TV8AddInDefBase)
      : Boolean; overload;
    // ������ ���������
    [ExportMethAttribute('�����������������������', 1)]
    function EmergencyReversal(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
    // ������ ������
    [ExportMethAttribute('����������������', 2)]
    function Settelment(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  public
    // ��������� ���������
    TerminalParams: TerminalParams;
  end;

implementation

{ TAcquiringTerminalDriver }

function TAcquiringTerminalDriver.AuthConfirmationByPaymentCard
  (RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LTransactParams: TTransactParams;
begin
  try
    TransParamsFromV8(@LTransactParams, Params);
    try
      AuthConfirmationByPaymentCard(@LTransactParams);
    finally
      TransParamsToV8(@LTransactParams, Params);
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
    TransParamsFromV8(@LTransactParams, Params);
    try
      AuthorisationByPaymentCard(@LTransactParams);
    finally
      TransParamsToV8(@LTransactParams, Params);
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
    TransParamsFromV8(@LTransactParams, Params);
    try
      CancelAuthorisationByPaymentCard(@LTransactParams);
    finally
      TransParamsToV8(@LTransactParams, Params);
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
    TransParamsFromV8(@LTransactParams, Params);
    try
      CancelPaymentByPaymentCard(@LTransactParams);
    finally
      TransParamsToV8(@LTransactParams, Params);
    end;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TAcquiringTerminalDriver.CashWithdrawal(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LTransactParams: TTransactParams;
begin
  try
    TransParamsFromV8(@LTransactParams, Params);
    try
      CashWithdrawal(@LTransactParams);
    finally
      TransParamsToV8(@LTransactParams, Params);
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
  TerminalParams.Clear;
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
  LCardNumber, LCardNumberHash, LCardType, LPaymentAccountReference: string;
  LFromLastOperation: Boolean;
  LIsOwnCard: Integer;
begin
  try
    LFromLastOperation := V8AsBool(@Params[2]);
    LCardNumber := '';
    LCardNumberHash := '';
    LPaymentAccountReference := '';
    LCardType := 'Unknown';
    LIsOwnCard := 0;

    try
      GetCardParametrs(LFromLastOperation, LCardNumber, LCardNumberHash,
        LPaymentAccountReference, LCardType, LIsOwnCard);
    finally
      V8SetWString(@Params[3], LCardNumber);
      V8SetWString(@Params[4], LCardNumberHash);
      V8SetWString(@Params[5], LPaymentAccountReference);
      V8SetWString(@Params[6], LCardType);
      V8SetInt(@Params[7], LIsOwnCard);
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

function TAcquiringTerminalDriver.PayByPaymentCard(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LTransactParams: TTransactParams;
begin
  try
    TransParamsFromV8(@LTransactParams, Params);
    try
      PayByPaymentCard(@LTransactParams);
    finally
      TransParamsToV8(@LTransactParams, Params);
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
  LTransactParams: TTransactParamsEc;
begin
  try
    TransParamsEcFromV8(@LTransactParams, Params);
    try
      PayElectronicCertificate(@LTransactParams);
    finally
      TransParamsEcToV8(@LTransactParams, Params);
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
  LTransactParams: TTransactParamsEc;
begin
  try
    TransParamsEcFromV8(@LTransactParams, Params);
    try
      ReturnElectronicCertificate(@LTransactParams);
    finally
      TransParamsEcToV8(@LTransactParams, Params);
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
  LTransactParams: TTransactParams;
begin
  try
    TransParamsFromV8(@LTransactParams, Params);
    try
      ReturnPaymantByPaymantCard(@LTransactParams);
    finally
      TransParamsToV8(@LTransactParams, Params);
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
begin
  LDocument := NewXMLDocument;
  LNode := LDocument.AddChild('TerminalParameters');

  LNode.Attributes['PrintSlipOnTerminal'] := TerminalParams.PrintSlipOnTerminal;
  LNode.Attributes['ShortSlip'] := TerminalParams.ShortSlip;
  LNode.Attributes['CashWithdrawal'] := TerminalParams.CashWithdrawal;
  LNode.Attributes['ElectronicCertificates'] :=
    TerminalParams.ElectronicCertificates;

  V8SetWString(@Params[2], LDocument.Xml.Text);
  SetSuccess(RetValue);
  Result := True;
end;

procedure TAcquiringTerminalDriver.TransParamsEcFromV8
  (AParams: PTransactParamsEc; AV8Params: PV8ParamArray);
begin
  AParams.Clear;

  AParams.MerchantNumber := V8AsInt64(@AV8Params[2]);
  AParams.BasketID := V8AsWString(@AV8Params[3]);
  AParams.ElectronicCertificateAmount := V8AsDouble(@AV8Params[4]);
  AParams.OwnFundsAmount := V8AsDouble(@AV8Params[5]);
  AParams.CardNumber := V8AsWString(@AV8Params[6]);
  AParams.ReceiptNum := V8AsWString(@AV8Params[7]);
  AParams.RRN := V8AsWString(@AV8Params[8]);
  AParams.AuthCode := V8AsWString(@AV8Params[9]);
  AParams.OperationStatus := V8AsInt(@AV8Params[10]);
  AParams.ReceiptText := '';
end;

procedure TAcquiringTerminalDriver.TransParamsEcToV8(AParams: PTransactParamsEc;
  AV8Params: PV8ParamArray);
begin
  V8SetInt64(@AV8Params[2], AParams.MerchantNumber);
  V8SetWString(@AV8Params[3], AParams.BasketID);
  V8SetDouble(@AV8Params[4], AParams.ElectronicCertificateAmount);
  V8SetDouble(@AV8Params[5], AParams.OwnFundsAmount);
  V8SetWString(@AV8Params[6], AParams.CardNumber);
  V8SetWString(@AV8Params[7], AParams.ReceiptNum);
  V8SetWString(@AV8Params[8], AParams.RRN);
  V8SetWString(@AV8Params[9], AParams.AuthCode);
  V8SetInt(@AV8Params[10], AParams.OperationStatus);
  V8SetWString(@AV8Params[11], AParams.ReceiptText);
end;

procedure TAcquiringTerminalDriver.TransParamsFromV8(AParams: PTransactParams;
  AV8Params: PV8ParamArray);
begin
  AParams.Clear;

  AParams.MerchantNumber := V8AsInt64(@AV8Params[2]);
  AParams.Amount := V8AsDouble(@AV8Params[3]);
  AParams.CardNumber := V8AsWString(@AV8Params[4]);
  AParams.ReceiptNum := V8AsWString(@AV8Params[5]);
  AParams.RRN := V8AsWString(@AV8Params[6]);
  AParams.AuthCode := V8AsWString(@AV8Params[7]);
  AParams.ReceiptText := '';
end;

procedure TAcquiringTerminalDriver.TransParamsToV8(AParams: PTransactParams;
  AV8Params: PV8ParamArray);
begin
  V8SetInt64(@AV8Params[2], AParams.MerchantNumber);
  V8SetDouble(@AV8Params[3], AParams.Amount);
  V8SetWString(@AV8Params[4], AParams.CardNumber);
  V8SetWString(@AV8Params[5], AParams.ReceiptNum);
  V8SetWString(@AV8Params[6], AParams.RRN);
  V8SetWString(@AV8Params[7], AParams.AuthCode);
  V8SetWString(@AV8Params[8], AParams.ReceiptText);
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
  Amount := 0;
  CardNumber := '';
  ReceiptNum := '';
  RRN := '';
  AuthCode := '';
  ReceiptText := '';
end;

{ TerminalParams }

procedure TerminalParams.Clear;
begin
  PrintSlipOnTerminal := False;
  ShortSlip := False;
  CashWithdrawal := False;
  ElectronicCertificates := False;
end;

{ TTransactParamsEc }

procedure TTransactParamsEc.Clear;
begin
  MerchantNumber := 0;
  BasketID := '';
  ElectronicCertificateAmount := 0;
  OwnFundsAmount := 0;
  CardNumber := '';
  ReceiptNum := '';
  RRN := '';
  AuthCode := '';
  OperationStatus := 0;
  ReceiptText := '';
end;

end.
