/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера принтера чеков для ревизии интерфейса (версии требований 1С) 3.4
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. 
//

unit uReceiptPrinterDriver;

interface

uses System.SysUtils, uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

type
  TReceiptPrinter = class(TCommonDriver)
  private
    procedure SetError(AExceptObject: TObject; const ARetValue: PV8Variant); overload;
  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
    constructor Create; override;
    destructor Destroy; override;
  protected
    // Перегруженные абстрактные методы типа оборудования

    // Печать текстового документа
    procedure PrintTextDocument(ADocumentPackage: IXMLDocument); overload; virtual; abstract;
    // Открыть ящик
    procedure OpenCashDrawer; overload; virtual; abstract;
    // Получение ширины строки
    procedure GetLineLength(out ALineLength: Int64); overload; virtual; abstract;
  public
    // Экспортируемые методы типа оборудования
    // Печать текстового документа
    [ExportMethAttribute('НапечататьТекстовыйДокумент', 2)]
    function PrintTextDocument(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
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
uses uCommonUtils, uXMLDialog, uEquipmentErrors;

constructor TReceiptPrinter.Create;
begin
  inherited;
  {$IFDEF DEBUG}
  if not Assigned(fmXmlDialog) then
    fmXmlDialog := TfmXmlDialog.Create(nil);
  {$ENDIF}
end;

destructor TReceiptPrinter.Destroy;
begin
  {$IFDEF DEBUG}
  FreeAndNil(fmXmlDialog);
  {$ENDIF}
  inherited;
end;

function TReceiptPrinter.OpenCashDrawer(RetValue: PV8Variant; Params: PV8ParamArray;
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

function TReceiptPrinter.GetLineLength(RetValue: PV8Variant; Params: PV8ParamArray;
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

function TReceiptPrinter.PrintTextDocument(RetValue: PV8Variant;
  Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LDocumentPackage: IXMLDocument;
begin
  try
    {$IFDEF DEBUG}
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

procedure TReceiptPrinter.SetError(AExceptObject: TObject; const ARetValue: PV8Variant);
begin
  if AExceptObject is EquException then
    SetError(AExceptObject, ARetValue, (AExceptObject as EquException).Code)
  else
    SetError(AExceptObject, ARetValue, ERR_Unknown);
end;

class procedure TReceiptPrinter.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etReceiptPrinter;
  DriverInfo.IntegrationComponent := false;
end;

end.
