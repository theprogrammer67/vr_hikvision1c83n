/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера дисплея покупателя для ревизии интерфейса (версии требований 1С) 2.X
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
    procedure GetOutputOptions(out ADeviceColumns, ADeviceRows: Int64); overload; virtual; abstract;

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

    // ПолучитьПараметрыВывода
    [ExportMethAttribute('ПолучитьПараметрыВывода', 3)]
    function GetOutputOptions(RetValue: PV8Variant; Params: PV8ParamArray;
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

function TCustomerDisplayDriver.GetOutputOptions(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LDeviceColumns, LDeviceRows: Int64;
begin
  try
    GetOutputOptions(LDeviceColumns, LDeviceRows);
    V8SetInt(@Params[2], LDeviceColumns);
    V8SetInt(@Params[3], LDeviceRows);
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
end;

end.

