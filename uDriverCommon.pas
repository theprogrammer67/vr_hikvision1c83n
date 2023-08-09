unit uDriverCommon;

interface

uses System.Math, System.SysUtils;

resourcestring
  RsErrPercentValueOutOfRange = 'Значение выходит за границы диапазона 0..100';
  RsErrDeviceDisabled = 'Операция разрешена только для включенного устройства';

procedure CheckPercentValue(AValue: Integer; ANegativeAllow: Boolean);

implementation

procedure CheckPercentValue(AValue: Integer; ANegativeAllow: Boolean);
var
  LValue: Integer;
begin
  LValue := IfThen(ANegativeAllow, Abs(AValue), AValue);
  if not(LValue in [0 .. 100]) then
    raise Exception.Create(RsErrPercentValueOutOfRange);
end;

end.
