/// /////////////////////////////////////////////////////////////////////////////
//
// ������� ����� �������� ������� ����������  ��� ������� ���������� (������ ���������� 1�) 3.0
// �������� 1�:���
// 1�-�����, ����� ��������� ����������. 2019
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

