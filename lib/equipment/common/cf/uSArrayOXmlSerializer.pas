unit uSArrayOXmlSerializer;


// ВАЖНО! Настройки формата даты и десятчного разделителя должны быть идентичны!

interface
uses System.SysUtils, OXmlPDOM;

procedure SArraySerialize(const varValue: Variant; Root: PXMLNode);
function SArrayDeserialize(Root: PXMLNode): Variant;

implementation

uses System.Variants;

procedure VarToXML(const varValue: Variant; XMLNode: PXMLNode); forward;

function XMLToVar(const XMLValue: PXMLNode): Variant; forward;
procedure XMLToVarArray(const XMLValue: PXMLNode;
  var varValue: Variant); forward;

function VarToString(const varValue: Variant; out sVarType: string): string;
var
  Vt: Integer;
begin
  Result := '';

  Vt := VarType(varValue) and VarTypeMask;

  case Vt of
    varSmallint, varInteger, varByte:
      begin
        Result := IntToStr(Integer(varValue));
        sVarType := 'N';
      end;
    varSingle, varDouble, varCurrency:
      begin
        Result := FloatToStr(Double(varValue));
        sVarType := 'N';
      end;
    varDate:
      begin
        Result := VarToStr(DateTimeToStr(varValue));
        sVarType := 'D';
      end;
    varOleStr, varString:
      begin
        Result := VarToStr(varValue);
        sVarType := 'S';
      end;
    varBoolean:
      begin
        Result := VarToStr(BoolToStr(varValue, True));
        sVarType := 'B';
      end;
  else
    Result := '';
    sVarType := 'U';
  end;
end;

procedure VarArrayToXML(const varValue: Variant; var XMLNode: PXMLNode);
var
  Row, Col, Rows, Cols, DimCnt: Integer;
  Dims: array of Integer;
begin
  XMLNode.Attributes['t'] := 'A';
  DimCnt := VarArrayDimCount(varValue);
  SetLength(Dims, DimCnt);
  Rows := VarArrayHighBound(varValue, 1) - VarArrayLowBound(varValue, 1) + 1;
  if DimCnt > 1 then
    Cols := VarArrayHighBound(varValue, 2) - VarArrayLowBound(varValue, 2) + 1
  else
    Cols := 0;
  XMLNode.Attributes['r'] := IntToStr(Rows);
  XMLNode.Attributes['c'] := IntToStr(Cols);

  for Row := VarArrayLowBound(varValue, 1) to VarArrayHighBound(varValue, 1) do
  begin
    Dims[0] := Row;
    if DimCnt > 1 then
    begin
      for Col := VarArrayLowBound(varValue, 2) to VarArrayHighBound
        (varValue, 2) do
      begin
        Dims[1] := Col;
        VarToXML(VarArrayGet(varValue, Dims), XMLNode.AddChild('elm'));
        // XMLNode.ChildNodes.Add(VarToXML(VarArrayGet(varValue, Dims)));
      end;
    end
    else
      VarToXML(VarArrayGet(varValue, Dims), XMLNode.AddChild('elm'));
  end;
end;

procedure VarToXML(const varValue: Variant; XMLNode: PXMLNode);
var
  sElmType, sElmValue: string;
begin
  if VarIsArray(varValue) then
    VarArrayToXML(varValue, XMLNode)
  else
  begin
    sElmValue := VarToString(varValue, sElmType);

    XMLNode.Attributes['t'] := sElmType;
    XMLNode.Text := sElmValue;
  end;
end;

function SArrayDeserialize(Root: PXMLNode): Variant;
var
  I, ParamCount: Integer;
  NodeList: TXMLChildNodeList;
begin
  VarClear(Result);

  NodeList := Root.ChildNodes;

  ParamCount := NodeList.Count;
  Result := VarArrayCreate([0, ParamCount - 1], varVariant);

  for I := 0 to ParamCount - 1 do
    Result[I] := XMLToVar(NodeList.Nodes[I]);
end;

function GetValueType(const XMLValue: PXMLNode): Integer;
var
  strValueType: string;
begin
  strValueType := UpperCase(VarToStrDef(XMLValue.Attributes['t'], 'U'));

  if strValueType = 'N' then
    Result := varDouble
  else if strValueType = 'S' then
    Result := varString
  else if strValueType = 'B' then
    Result := varBoolean
  else if strValueType = 'D' then
    Result := varDate
  else if strValueType = 'A' then
    Result := varArray
  else
    Result := varEmpty;

end;

procedure SArraySerialize(const varValue: Variant; Root: PXMLNode);
var
  I: Integer;
begin
  if not VarIsArray(varValue) then
    Exit;

  for I := VarArrayLowBound(varValue, 1) to VarArrayHighBound(varValue, 1) do
    VarToXML(varValue[I], Root.AddChild('elm'));
end;

function XMLToVar(const XMLValue: PXMLNode): Variant;
var
  ValueType: Integer;
begin
  VarClear(Result);

  ValueType := GetValueType(XMLValue);
  case ValueType of
    varArray:
      XMLToVarArray(XMLValue, Result);
    varString:
      Result := XMLValue.Text;
    varDouble:
      Result := StrToFloat(XMLValue.Text);
    varBoolean:
      Result := StrToBool(VarToStr(XMLValue.Text));
    varDate:
      Result := StrToDateTime(XMLValue.Text);
  end;
end;

procedure XMLToVarArray(const XMLValue: PXMLNode; var varValue: Variant);
var
  Row, Col, Rows, Cols: Integer;
  varCols: Variant;
begin
  VarClear(varValue);

  Rows := StrToIntDef(XMLValue.Attributes['r'], 0);
  varCols := XMLValue.Attributes['c'];
  if (not VarIsClear(varCols)) and (not VarIsNull(varCols)) then
    Cols := StrToIntDef(varCols, 0)
  else
    Cols := 0;

  if Rows = 0 then
    Exit;

  if Cols > 0 then
    varValue := VarArrayCreate([0, Rows - 1, 0, Cols - 1], varVariant)
  else
    varValue := VarArrayCreate([0, Rows - 1], varVariant);

  for Row := 0 to Rows - 1 do
  begin
    if Cols > 0 then
    begin
      for Col := 0 to Cols - 1 do
        varValue[Row, Col] :=
          XMLToVar(XMLValue.ChildNodes.Get(Row * Cols + Col));
    end
    else
      varValue[Row] := XMLToVar(XMLValue.ChildNodes.Get(Row));
  end;
end;

end.
