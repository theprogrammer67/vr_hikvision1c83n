unit Common.GetCOMPorts;

interface

uses Winapi.Windows, System.SysUtils, System.StrUtils, System.Classes;

procedure GetComPorts(AList: TStrings; ANameStart: string);

implementation

//ƒостает из строки с нуль-терминированными подстроками следующую нуль-терминированную
//подстроку начина€ с позиции AStartPos, потом устанавливает AStartPos на символ
//следующий за терминирующим #0.
function GetNextSubstring(ABuf: string; var AStartPos: integer): string;
var
  LLastPos: integer;
begin
  if (AStartPos < 1) then
      raise ERangeError.Create('StartPos должен быть больше 0');

  if (AStartPos > Length(ABuf) ) then
      Exit('');

  LLastPos := PosEx(#0, ABuf, AStartPos);
  Result := Copy(ABuf, AStartPos, LLastPos - AStartPos);
  AStartPos := AStartPos + (LLastPos - AStartPos) + 1;
end;

//«аполн€ет список aList наденными в системе COM портами
procedure GetComPorts(AList: TStrings; ANameStart: string);
var
  LBuf: string;
  LRes: integer;
  LErr: integer;
  LBufSize: integer;
  LNameStartPos: integer;
  LName: string;
  LPortNum: Byte;
begin
  LBufSize := 1024 * 5;
  LRes := 0;

  while LRes = 0 do
  begin
    setlength(LBuf, LBufSize);
    SetLastError(ERROR_SUCCESS);
    LRes := QueryDosDevice(nil, @LBuf[1], LBufSize);
    LErr := GetLastError();

    // ¬ариант дл€ двухтонки
    if (LRes <> 0) and (LErr = ERROR_INSUFFICIENT_BUFFER) then
    begin
      LBufSize := LRes;
      LRes := 0;
    end;

    if (LRes = 0) and (LErr = ERROR_INSUFFICIENT_BUFFER) then
      LBufSize := LBufSize + 1024;

    if (LErr <> ERROR_SUCCESS) and (LErr <> ERROR_INSUFFICIENT_BUFFER) then
      raise Exception.Create(SysErrorMessage(LErr));
  end;
  SetLength(LBuf, LRes);

  LNameStartPos := 1;
  LName := GetNextSubstring(LBuf, LNameStartPos);

  AList.BeginUpdate();
  try
    AList.Clear();
    while LName <> '' do
    begin
      if StartsStr(ANameStart, LName) then
      begin
        LPortNum := StrToIntDef(Copy(LName, 4, 3), 0);
        AList.AddObject(LName, TObject(LPortNum));
      end;
      LName := GetNextSubstring(LBuf, LNameStartPos);
    end;
  finally
    AList.EndUpdate();
  end;
end;

end.
