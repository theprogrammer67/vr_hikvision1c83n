unit TestuCommonUtils;

interface

uses
  Classes,
  TestFramework;

type
  TTestTestuCommonUtils = class(TTestCase)
  private
    const
      DATE_2018_08_24_BEGINNING = 43336;
      DATE_2018_08_24_6hours = 43336.25;
  private
    FOldShortDateFormat: string;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestVarToDate_CorrectDate;
    procedure TestVarToDate_StringDateAndHour;
    procedure TestVarToDate_StringDateAtTheBeginning;
    procedure TestVarToDate_ISOStringDate;
    procedure TestVarToDate_ISOStringDate_6Hours;
  end;

implementation

uses
  SysUtils, Variants,
  uCommonUtils;

{ TTestTestuCommonUtils }

procedure TTestTestuCommonUtils.SetUp;
begin
  inherited;
  FOldShortDateFormat := {$IF CompilerVersion > 21}FormatSettings.{$IFEND}ShortDateFormat;
  {$IF CompilerVersion > 21}FormatSettings.{$IFEND}ShortDateFormat := 'yyy-mm-dd';
end;

procedure TTestTestuCommonUtils.TearDown;
begin
  {$IF CompilerVersion > 21}FormatSettings.{$IFEND}ShortDateFormat := FOldShortDateFormat;
  inherited;
end;

procedure TTestTestuCommonUtils.TestVarToDate_CorrectDate;
var
  LDate: TDateTime;
  LDateResult: TDateTime;
  LDateVar: Variant;
begin
  LDate := DATE_2018_08_24_6hours; // 24.08.2018
  LDateVar := LDate;

  LDateResult := VarToDateDef(LDateVar, 0);
  CheckEquals(DATE_2018_08_24_6hours, LDateResult);
end;

procedure TTestTestuCommonUtils.TestVarToDate_ISOStringDate;
var
  LDate: string;
  LDateResult: TDateTime;
  LDateVar: Variant;
begin
  LDate := '2018-08-24T00:00:00Z';
  LDateVar := LDate;

  {$IF CompilerVersion < 21}
  StartExpectingException(EVariantTypeCastError);
  {$IFEND}
  LDateResult := VarToDateDef(LDateVar, 0);
  CheckEquals(DATE_2018_08_24_BEGINNING, LDateResult);
end;

procedure TTestTestuCommonUtils.TestVarToDate_ISOStringDate_6Hours;
var
  LDate: string;
  LDateResult: TDateTime;
  LDateVar: Variant;
begin
  LDate := '2018-08-24T06:00:00Z';
  LDateVar := LDate;

  {$IF CompilerVersion < 21}
  StartExpectingException(EVariantTypeCastError);
  {$IFEND}
  LDateResult := VarToDateDef(LDateVar, 0);
  CheckEquals(DATE_2018_08_24_6HOURS, LDateResult);
end;

procedure TTestTestuCommonUtils.TestVarToDate_StringDateAndHour;
var
  LDate: string;
  LDateResult: TDateTime;
  LDateVar: Variant;
begin
  LDate := '24.08.2018 6:00';
  LDateVar := LDate;

  LDateResult := VarToDateDef(LDateVar, 0);
  CheckEquals(DATE_2018_08_24_6hours, LDateResult);
end;

procedure TTestTestuCommonUtils.TestVarToDate_StringDateAtTheBeginning;
var
  LDate: string;
  LDateResult: TDateTime;
  LDateVar: Variant;
begin
  LDate := '24.08.2018';
  LDateVar := LDate;

  LDateResult := VarToDateDef(LDateVar, 0);
  CheckEquals(DATE_2018_08_24_BEGINNING, LDateResult);
end;

initialization
  RegisterTest(TTestTestuCommonUtils.Suite);
end.
