/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера весов с печатью этикеток для ревизии интерфейса (версии требований 1С) 3.0
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. 2019
//

unit uScaleOfflineDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi, Xml.XMLDoc, Xml.XMLIntf;

type
  TScaleOfflineDriver = class(TCommonDriver)
  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
  protected

  private

  public
    procedure UploadGoods(AInputParameters: IXMLDocument; const PackageStatus: string); overload; virtual; abstract;
    procedure ClearGoods(); overload; virtual; abstract;

    // Выгрузить товары
    [ExportMethAttribute('ВыгрузитьТовары', 3)]
    function UploadGoods(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;

    // Очистить товары
    [ExportMethAttribute('ОчиститьТовары', 1)]
    function ClearGoods(RetValue: PV8Variant; Params: PV8ParamArray;
      const ParamCount: Integer; var v8: TV8AddInDefBase): Boolean; overload;
  end;

implementation
uses Variants, SysUtils, uCommonUtils, uEquipmentErrors;

{ TScaleOfflineDriver }

function TScaleOfflineDriver.ClearGoods(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
begin
  try
    ClearGoods;

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

class procedure TScaleOfflineDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etPrintingScale;
  DriverInfo.IntegrationComponent := false;
end;

function TScaleOfflineDriver.UploadGoods(RetValue: PV8Variant; Params: PV8ParamArray; const ParamCount: Integer;
  var v8: TV8AddInDefBase): Boolean;
var
  LInputParameters: IXMLDocument;
  LPackageStatus: string;
begin
  try
    LInputParameters := LoadXMLData(GetValidXML(V8AsWString(@Params[2])));
    LPackageStatus := V8AsWString(@Params[3]);
    UploadGoods(LInputParameters, LPackageStatus);

    SetSuccess(RetValue);
  except
    SetError(ExceptObject, RetValue);
  end;

  Result := True;
end;

end.

