/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера дисплея покупателя для ревизии интерфейса (версии требований 1С) 3.X
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. 2022
//

unit uCustomerDisplayDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

type
  TCustomerDisplayDriver = class(TCommonDriver)
  protected

    procedure StringOutputOnCustomerDisplay(const AMessageText: string); overload; virtual; abstract;
    procedure ClearCustomerDisplay; overload; virtual; abstract;
    procedure QRCodeOutputOnCustomerDisplay(const AQRCodeValue, AQRСodePicture: string); overload; virtual; abstract;
    procedure GetCustomerDisplayOptions(out ACustomerDisplayOptions: IXMLDocument); overload; virtual; abstract;

  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;

  public
    // ВывестиСтрокуНаДисплейПокупателя
    [ExportMethAttribute('ВывестиСтрокуНаДисплейПокупателя', 2)]
    function StringOutputOnCustomerDisplay(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    // ОчиститьДисплейПокупателя
    [ExportMethAttribute('ОчиститьДисплейПокупателя', 1)]
    function ClearCustomerDisplay(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    // ВывестиQRКодНаДисплейПокупателя
    [ExportMethAttribute('ВывестиQRКодНаДисплейПокупателя', 3)]
    function QRCodeOutputOnCustomerDisplay(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    // ПолучитьПараметрыДисплеяПокупателя
    [ExportMethAttribute('ПолучитьПараметрыДисплеяПокупателя', 2)]
    function GetCustomerDisplayOptions(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

  end;

implementation

uses
  Variants, SysUtils, uCommonUtils, uEquipmentErrors;

function TCustomerDisplayDriver.StringOutputOnCustomerDisplay(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    StringOutputOnCustomerDisplay(V8AsWString(@Params[2]));
    SetSuccess(RetValue);
  except
    on E : EquException do
      SetError(ExceptObject, RetValue, E.Code);
    else
      SetError(ExceptObject, RetValue, ERR_Unknown);
  end;

  Result := True;
end;

function TCustomerDisplayDriver.ClearCustomerDisplay(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    ClearCustomerDisplay;
    SetSuccess(RetValue);
  except
    on E : EquException do
      SetError(ExceptObject, RetValue, E.Code);
    else
      SetError(ExceptObject, RetValue, ERR_Unknown);
  end;

  Result := True;
end;


function TCustomerDisplayDriver.QRCodeOutputOnCustomerDisplay(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    QRCodeOutputOnCustomerDisplay(V8AsWString(@Params[2]), V8AsWString(@Params[3]));
    SetSuccess(RetValue);
  except
    on E : EquException do
      SetError(ExceptObject, RetValue, E.Code);
    else
      SetError(ExceptObject, RetValue, ERR_Unknown);
  end;

  Result := True;
end;

function TCustomerDisplayDriver.GetCustomerDisplayOptions(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LCustomerDisplayOptions: IXMLDocument;
begin
  try
    LCustomerDisplayOptions := NewXMLDocument;
    GetCustomerDisplayOptions(LCustomerDisplayOptions);
    V8SetWString(@Params[2], LCustomerDisplayOptions.Xml.Text);
    SetSuccess(RetValue);
  except
    on E : EquException do
      SetError(ExceptObject, RetValue, E.Code);
    else
      SetError(ExceptObject, RetValue, ERR_Unknown);
  end;

  Result := True;
end;


class procedure TCustomerDisplayDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etCustomerDisplay;
  DriverInfo.IntegrationComponent := false;
end;

end.

