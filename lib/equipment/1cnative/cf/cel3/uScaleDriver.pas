/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера весов для ревизии интерфейса (версии требований 1С) 3.0
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. 2019
//

unit uScaleDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

type
  TScaleDriver = class(TCommonDriver)
  protected
    procedure Calibrate(const ATareWeight: Double); overload; virtual; abstract;
    procedure GetWeight(out AWeight: Double); overload; virtual; abstract;

  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;

  public
    // Установить вес тары
    [ExportMethAttribute('УстановитьВесТары', 2)]
    function Calibrate(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    // Получить вес
    [ExportMethAttribute('ПолучитьВес', 2)]
    function GetWeight(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  end;

implementation

uses
  Variants, SysUtils, uCommonUtils, uEquipmentErrors;

function TScaleDriver.GetWeight(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LWeight: Double;
begin
  try
    GetWeight(LWeight);
    V8SetDouble(@Params[2], LWeight);

    SetSuccess(RetValue);
  except
    on E : EquException do
      SetError(ExceptObject, RetValue, E.Code);
    else
      SetError(ExceptObject, RetValue, ERR_Unknown);
  end;

  Result := True;
end;

class procedure TScaleDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etScale;
  DriverInfo.IntegrationComponent := false;
end;

function TScaleDriver.Calibrate(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LTareWeight: Double;
begin
  try
    LTareWeight := V8AsDouble(@Params[2]);
    Calibrate(LTareWeight);

    SetSuccess(RetValue);
  except
    on E : EquException do
      SetError(ExceptObject, RetValue, E.Code);
    else
      SetError(ExceptObject, RetValue, ERR_Unknown);
  end;

  Result := True;
end;

end.

