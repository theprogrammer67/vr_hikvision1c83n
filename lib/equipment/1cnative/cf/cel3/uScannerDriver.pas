/// /////////////////////////////////////////////////////////////////////////////
//
// Базовый класс драйвера сканера штрихкодов  для ревизии интерфейса (версии требований 1С) 3.0
// Драйверы 1С:БПО
// 1С-Рарус, Отдел системных разработок. 2019
//

unit uScannerDriver;

interface

uses uCommonDriver, uCustomDriver, v8napi, Winapi.Windows;

type
  TScannerDriver = class(TCommonDriver)
  public
    class procedure UpdateDriverInfo(ADriverInfo: PDriverInfo); override;
  protected

  private

  end;

implementation
uses Variants, SysUtils, uCommonUtils;

class procedure TScannerDriver.UpdateDriverInfo(ADriverInfo: PDriverInfo);
begin
  inherited;
  DriverInfo.EquipmentType := etScanner;
  DriverInfo.IntegrationComponent := false;
end;

end.

