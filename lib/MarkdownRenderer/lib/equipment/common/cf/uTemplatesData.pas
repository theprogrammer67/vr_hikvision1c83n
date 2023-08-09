unit uTemplatesData;

interface

uses Classes, Variants;

type
  TDataSectParam = class
  public
    Name: string;
    Value: Variant;

    constructor Create(const ParamName: string; ParamValue: Variant);
    destructor Destroy; override;
  end;

  TDataSectParams = class(TList)
  private
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    function Get(Index: Integer): TDataSectParam;
    procedure Put(Index: Integer; const Value: TDataSectParam);
  public
    function Add(const ParamName: string; ParamValue: Variant)
      : TDataSectParam; overload;
    function AsVarArray: Variant;

    property Items[Index: Integer]: TDataSectParam read Get write Put; default;
  end;

  TDataSection = class
  private
    FParams: TDataSectParams;

    function GetParam(Index: Integer): TDataSectParam;
    procedure PutParam(Index: Integer; const Value: TDataSectParam);
    function GetIsEmpty: Boolean;
  public
    Name: string;

    constructor Create(const SectName: string);
    destructor Destroy; override;

    procedure AddParam(const ParamName: string; ParamValue: Variant);
    procedure AddParams(Names: array of string; Values: array of Variant);
    function ParamsAsVarArray: Variant;

    property Params[Index: Integer]: TDataSectParam read GetParam
      write PutParam;
    property IsEmpty: Boolean read GetIsEmpty;
  end;

  TDataSections = class(TList)
  private
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    function Get(Index: Integer): TDataSection;
    procedure Put(Index: Integer; const Value: TDataSection);
  public
    function Add(const SectName: string): TDataSection; overload;
    procedure Add(var Section: TDataSection); overload;
    function Add(const SectName: string; Names: array of string;
      Values: array of Variant): TDataSection; overload;
    function AsVarArray: Variant;
    // procedure Delete(Section: TDataSection);

    property Items[Index: Integer]: TDataSection read Get write Put; default;
  end;

function GetTemplateParamsArray(const TemplateSections: OleVariant): OleVariant;

implementation

uses uTemplateDocCommon;

function GetTemplateParamsArray(const TemplateSections: OleVariant): OleVariant;
var
  SectInd, CompStrInd, CompFldInd, FieldInd: Integer;
  SectArr, CompStrArr, CompFldArr, FldArr: OleVariant;
  IsParam: Boolean;
  DataSections: TDataSections;
  DataSection: TDataSection;
  EmptySection: Boolean;
  FldValue: OleVariant;
  FieldType: TFieldType;
begin
  VarClear(Result);
  if VarIsClear(TemplateSections) or (not VarIsArray(TemplateSections)) then
    Exit;

  DataSections := TDataSections.Create;
  try
    for SectInd := VarArrayLowBound(TemplateSections, 2)
      to VarArrayHighBound(TemplateSections, 2) do
    begin
      DataSection := DataSections.Add(TemplateSections[0, SectInd]);
      EmptySection := True;

      CompStrArr := TemplateSections[3, SectInd];
      if VarIsClear(CompStrArr) or (not VarIsArray(CompStrArr)) then
        Continue;

      for CompStrInd := VarArrayLowBound(CompStrArr, 2)
        to VarArrayHighBound(CompStrArr, 2) do
      begin
        CompFldArr := CompStrArr[3, CompStrInd];
        if VarIsClear(CompFldArr) or (not VarIsArray(CompFldArr)) then
          Continue;

        for CompFldInd := VarArrayLowBound(CompFldArr, 2)
          to VarArrayHighBound(CompFldArr, 2) do
        begin
          FldArr := CompFldArr[11, CompFldInd];
          if VarIsClear(FldArr) or (not VarIsArray(FldArr)) then
            Continue;

          for FieldInd := VarArrayLowBound(FldArr, 2)
            to VarArrayHighBound(FldArr, 2) do
          begin
            EmptySection := False;

            IsParam := FldArr[5, FieldInd];
            if not IsParam then
              Continue;

            FieldType := TFieldType(VarToIntDef(FldArr[3, FieldInd], 0));
            FldValue := GetFldValueAsType(FldArr[8, FieldInd], FieldType);
            DataSection.AddParam(FldArr[0, FieldInd], FldValue);
          end;
        end;
      end;

      if EmptySection then
        DataSections.Remove(DataSection);
    end;

    Result := DataSections.AsVarArray;
  finally
    DataSections.Free;
  end;
end;

{ TSections }

function TDataSections.Add(const SectName: string): TDataSection;
begin
  Result := TDataSection.Create(SectName);
  inherited Add(Result);
end;

procedure TDataSections.Add(var Section: TDataSection);
begin
  inherited Add(Section);
end;

function TDataSections.Add(const SectName: string; Names: array of string;
  Values: array of Variant): TDataSection;
var
  Section: TDataSection;
begin
  Section := TDataSection.Create(SectName);
  Section.AddParams(Names, Values);
  Add(Section);

  Result := Section;
end;

function TDataSections.AsVarArray: Variant;
var
  I: Integer;
begin
  Result := VarArrayCreate([0, 1, 0, Count - 1], varVariant);
  for I := 0 to Count - 1 do
  begin
    Result[0, I] := Items[I].Name;
    Result[1, I] := Items[I].ParamsAsVarArray;
  end;
end;

function TDataSections.Get(Index: Integer): TDataSection;
begin
  Result := TDataSection(inherited Get(Index));
end;

procedure TDataSections.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then
    TDataSection(Ptr).Free;
end;

procedure TDataSections.Put(Index: Integer; const Value: TDataSection);
begin
  inherited Put(Index, Pointer(Value));
end;

{ TSection }

procedure TDataSection.AddParam(const ParamName: string; ParamValue: Variant);
begin
  FParams.Add(ParamName, ParamValue);
end;

procedure TDataSection.AddParams(Names: array of string;
  Values: array of Variant);
var
  I: Integer;
begin
  for I := Low(Names) to High(Names) do
    AddParam(Names[I], Values[I]);
end;

constructor TDataSection.Create(const SectName: string);
begin
  Name := SectName;
  FParams := TDataSectParams.Create;
end;

destructor TDataSection.Destroy;
begin
  FParams.Free;
  inherited;
end;

function TDataSection.GetIsEmpty: Boolean;
begin
  Result := FParams.Count = 0;
end;

function TDataSection.GetParam(Index: Integer): TDataSectParam;
begin
  Result := FParams[Index];
end;

function TDataSection.ParamsAsVarArray: Variant;
begin
  Result := FParams.AsVarArray;
end;

procedure TDataSection.PutParam(Index: Integer; const Value: TDataSectParam);
begin
  FParams[Index] := Value;
end;

{ TSectParam }

constructor TDataSectParam.Create(const ParamName: string; ParamValue: Variant);
begin
  Name := ParamName;
  Value := ParamValue;
end;

destructor TDataSectParam.Destroy;
begin
  VarClear(Value);
  inherited;
end;

{ TSectParams }

function TDataSectParams.Add(const ParamName: string; ParamValue: Variant)
  : TDataSectParam;
begin
  Result := TDataSectParam.Create(ParamName, ParamValue);
  inherited Add(Result);
end;

function TDataSectParams.AsVarArray: Variant;
var
  I: Integer;
begin
  Result := VarArrayCreate([0, 1, 0, Count - 1], varVariant);
  for I := 0 to Count - 1 do
  begin
    Result[0, I] := Items[I].Name;
    Result[1, I] := Items[I].Value;
  end;
end;

function TDataSectParams.Get(Index: Integer): TDataSectParam;
begin
  Result := TDataSectParam(inherited Get(Index));
end;

procedure TDataSectParams.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then
    TDataSectParam(Ptr).Free;
end;

procedure TDataSectParams.Put(Index: Integer; const Value: TDataSectParam);
begin
  inherited Put(Index, Pointer(Value));
end;

end.
