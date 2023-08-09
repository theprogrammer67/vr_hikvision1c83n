unit uLabelPrinterDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

type
  TLabelPrinterDriver = class(TCommonDriver)
  private
  protected
  // Перегруженные абстрактные методы типа оборудования
    procedure PrintLabels(AInputParameters: IXMLDocument; const APackageStatus: string); overload; virtual; abstract;
    procedure InitializePrinter; overload; virtual; abstract;

  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
    constructor Create; override;
    destructor Destroy; override;
  public
    // Экспортируемые методы типа оборудования
    // Инициализация Принтера
    [ExportMethAttribute('ИнициализацияПринтера', 1)]
    function InitializePrinter(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    // Печать Этикеток
    [ExportMethAttribute('ПечатьЭтикеток', 3)]
    function PrintLabels(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  end;

implementation
uses
  Variants, SysUtils, uCommonUtils, uXMLDialog, uEquipmentErrors;

{ TLabelPrinterDriver }

constructor TLabelPrinterDriver.Create;
begin
  inherited;
  {$IF Defined(DEBUG_FORM)}
  if not Assigned(fmXmlDialog) then
    fmXmlDialog := TfmXmlDialog.Create(nil);
  {$IFEND}
end;

destructor TLabelPrinterDriver.Destroy;
begin
  {$IF Defined(DEBUG_FORM)}
  FreeAndNil(fmXmlDialog);
  {$IFEND}
  inherited;
end;

function TLabelPrinterDriver.InitializePrinter(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    InitializePrinter;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

function TLabelPrinterDriver.PrintLabels(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters: IXMLDocument;
  LPackageStatus: string;
begin
  try
    {$IF Defined(DEBUG_FORM)}
      fmXmlDialog.mXml.Lines.Text := V8AsWString(@Params[2]);
      fmXmlDialog.ShowModal;
      LInputParameters := LoadXMLData(GetValidXML(fmXmlDialog.mXml.Text));
    {$ELSE}
      LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    {$IFEND}
    LPackageStatus := V8AsWString(@Params[3]);
    PrintLabels(LInputParameters, LPackageStatus);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

class procedure TLabelPrinterDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etLabelPrinter;
end;

end.
