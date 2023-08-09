unit uTemplateDocCommon;

interface

uses Variants, SysUtils, StrUtils;

const
  DefTemplateName = 'NewDocumentTemplate.xml';
  DefTemplateDescription = 'Новый шаблон документа';

  Def1DBarcodeHeight = 3;
  Def2DBarcodeMargin = 5;

type
  TFieldType = (ftString, ftNumber, ftDate);

function GetFldValueAsType(const Value: Variant; FieldType: TFieldType)
  : Variant;
function GetStrigsCount(const Text: string; StrLength: Cardinal): Integer;
function VarToIntDef(const V: Variant; const ADefault: Integer): Integer;
function VarToDoubleDef(const V: Variant; const ADefault: Double): Double;
function VarToBoolDef(const V: Variant; const ADefault: Boolean): Boolean;
function VarToStringDef(const V: Variant; const ADefault: string): string;
function VarToDateDef(const V: Variant; const ADefault: TDateTime): TDateTime;
function CorrectDecimalSeparator(const Value: string): string;
function StringToDateTime(const S: string): TDateTime;
function FormatValue(Val: OleVariant; ValType: Integer; ValFormat: WideString)
  : WideString;




implementation

uses
  Classes;

const
  // для локальных преобразований из строки в числа и дату/время
  TemplFS: TFormatSettings = ();



function GetFldValueAsType(const Value: Variant; FieldType: TFieldType)
  : Variant;
begin
  case FieldType of
    ftString:
      Result := VarToStr(Value);
    ftNumber:
      begin
        if VarIsStr(Value) then
          Result := StrToFloatDef(Value, 0, TemplFS)
        else
          Result := VarAsType(Value, varDouble);
      end;
    ftDate:
      begin
        if VarIsStr(Value) then
          Result := StringToDateTime(Value)
        else
          Result := VarToDateTime(Value);
      end;
  end;
end;

function GetStrigsCount(const Text: string; StrLength: Cardinal): Integer;
var
  StrPos, AbsPos, SpcPos: Integer;
begin
  Result := 0;
  if Length(Text) = 0 then
    Exit;

  StrPos := 1;
  AbsPos := 1;
  SpcPos := -1;

  while AbsPos <= Length(Text) do
  begin
    if Text[AbsPos] = ' ' then
      SpcPos := AbsPos;

    if (StrPos >= StrLength) or (AbsPos = Length(Text)) then
    begin
      if (SpcPos > 0) and not (AbsPos = Length(Text)) then
      begin
        AbsPos := SpcPos + 1;
        SpcPos := -1;
      end
      else
        AbsPos := AbsPos + 1;
      StrPos := 1;
      Inc(Result);
    end;

    Inc(AbsPos);
    Inc(StrPos);
  end;
end;

function VarToIntDef(const V: Variant; const ADefault: Integer): Integer;
begin
  if (not VarIsNull(V)) and (not VarIsEmpty(V)) then
    Result := V
  else
    Result := ADefault;
end;

function VarToDoubleDef(const V: Variant; const ADefault: Double): Double;
begin
  if (not VarIsNull(V)) and (not VarIsEmpty(V)) then
    Result := V
  else
    Result := ADefault;
end;

function VarToBoolDef(const V: Variant; const ADefault: Boolean): Boolean;
begin
  if (not VarIsNull(V)) and (not VarIsEmpty(V)) then
    Result := V
  else
    Result := ADefault;
end;

function VarToStringDef(const V: Variant; const ADefault: string): string;
begin
  if (not VarIsNull(V)) and (not VarIsEmpty(V)) then
    Result := V
  else
    Result := ADefault;
end;

function VarToDateDef(const V: Variant; const ADefault: TDateTime): TDateTime;
begin
  if (not VarIsNull(V)) and (not VarIsEmpty(V)) then
    Result := V
  else
    Result := ADefault;
end;

function CorrectDecimalSeparator(const Value: string): string;
begin
{$IF CompilerVersion > 20}
  if FormatSettings.DecimalSeparator = '.' then
    Result := StringReplace(Value, ',', FormatSettings.DecimalSeparator,
      [rfReplaceAll])
  else
    Result := StringReplace(Value, '.', FormatSettings.DecimalSeparator,
      [rfReplaceAll]);
{$ELSE}
  if DecimalSeparator = '.' then
    Result := StringReplace(Value, ',', DecimalSeparator,
      [rfReplaceAll])
  else
    Result := StringReplace(Value, '.', DecimalSeparator,
      [rfReplaceAll]);
{$IFEND}
end;

function StringToDateTime(const S: string): TDateTime;
var
  Year, Month, Day: Word;
  Hour, Min, Sec: Word;
begin
  if Length(S) = 0 then
    Result := 0
  else if Pos('.', S) = 0 then // формат 1С
  begin
    Year := StrToInt(LeftStr(S, 4));
    Month := StrToInt(MidStr(S, 5, 2));
    Day := StrToInt(MidStr(S, 7, 2));
    Hour := StrToInt(MidStr(S, 9, 2));
    Min := StrToInt(MidStr(S, 11, 2));
    Sec := StrToInt(MidStr(S, 13, 2));

    Result := EncodeDate(Year, Month, Day) + EncodeTime(Hour, Min, Sec, 0);
  end
  else
    Result := StrToDateTime(S, TemplFS);
end;

function FormatValue(Val: OleVariant; ValType: Integer; ValFormat: WideString)
  : WideString;
var
  S, F: string;
  SL: TStringList;
  ND, NFD: Integer;
  NDS: string;
  NLZ: Boolean;

  function ReplalaceChars(const _F: string; COrig: array of Char;
    CRepl: array of Char): string;
  var
    I, J: Integer;
  begin
    Result := _F;
    for I := 1 to Length(Result) do
    begin
      for J := 0 to High(COrig) do
      begin
        if Result[I] = COrig[J] then
        begin
          Result[I] := CRepl[J];
        end;
      end;
    end;
  end;

begin
  Result := '';
  try
    if ValType = 2 then
      Val := TDateTime(Val);

    Result := VarToWideStr(Val);
      // < Значение форматирования по умолчанию

    if ValType in [1..2] then
    begin
      if ValFormat = '' then
        Exit;
      SL := TStringList.Create;
      try
        SL.Text := StringReplace(ValFormat, ';', sLineBreak, [rfReplaceAll]);
        case ValType of
          // 0: ; // Строка
          1:
            begin // Число
              // Тут нужно приведение к числу?...
              ND := StrToIntDef(SL.Values['ND'], -1);
              if ND = -1 then
                ND := StrToIntDef(SL.Values['ЧЦ'], -1);
              NFD := StrToIntDef(SL.Values['NFD'], -1);
              if NFD = -1 then
                NFD := StrToIntDef(SL.Values['ЧДЦ'], -1);
              NDS := SL.Values['NDS'];
              if NDS = '' then
                NDS := SL.Values['ЧРД'];
              NLZ := SL.IndexOfName('NLZ') <> -1;
              if not NLZ then
                NLZ := SL.IndexOfName('ЧВН') <> -1;

              if (ND > -1) and (NFD > -1) then
                Result := Format('%*.*f', [ND, NFD, Double(Val)])
              else if (ND > -1) then
                Result := Format('%*.0f', [ND, Double(Val)])
              else if (NFD > -1) then
                Result := Format('%0.*f', [NFD, Double(Val)]);

              if NDS <> '' then
{$IF CompilerVersion > 20}
                Result := StringReplace(Result, FormatSettings.DecimalSeparator,
                  NDS, [rfReplaceAll]);
{$ELSE}
                Result := StringReplace(Result, DecimalSeparator,
                  NDS, [rfReplaceAll]);
{$IFEND}
              if NLZ then
                Result := StringReplace(Result, ' ', '0', [rfReplaceAll]);
            end;
          2:
            begin // Дата
              F := SL.Values['DF'];
              if F = '' then
                F := SL.Values['ДФ'];
              if F <> '' then
              begin
                F := ReplalaceChars(F, ['д', 'М', 'к', 'г', 'ч', 'Ч', 'м',
                  'с'],
                  ['d', 'M', 'q', 'y', 'h', 'H', 'n', 's']);
                DateTimeToString(S, F, VarToDateTime(Val), TemplFS);
                Result := S;
              end;
            end;
        end;
      finally
        SL.Free;
      end;
    end;
  except
    S := S;
  end;
end;




initialization
  TemplFS := FormatSettings;
  with TemplFS do begin
    DecimalSeparator := '.';
    DateSeparator := '.';
    TimeSeparator := ':';
    ShortDateFormat := 'dd mm yy';
    LongTimeFormat := 'hh mm ss';
  end;

end.

