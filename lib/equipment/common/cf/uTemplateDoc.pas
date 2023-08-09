unit uTemplateDoc;

interface

uses Windows, Classes, Graphics, XMLIntf, System.Types, Vcl.Controls,
  DelphiZXingQRCode,
  uTemplatesData, uTemplateLib, unitBarCode, uImageListCommon,
  uTemplateDocCommon;

type
  TElementType = (eltDocument, eltSection, eltCompString, eltCompField,
    eltField);

  TTemplateDoc = class;
  TTEmplateElementList = class;
  TTemplateElement = class;

  // TNoty = procedure(OldElem, NewElem: TTemplateElement) of object;

  TTemplateElement = class(TPersistent)
  private
    FBitMap: TBitMap;
    FRootElement: TTemplateElement;

    function GetCanvas: TCanvas;
    function GetWidth: Integer;
    procedure SetWidth(const Value: Integer);
    function GetHeight: Integer;
    procedure SetHeight(const Value: Integer);
    function GetXML: string;
    procedure SetXML(const Value: string);
    function GetTemplateDoc: TTemplateDoc;
  protected
    // function IsSelected: Boolean; virtual;
    procedure UpdateRegion; virtual;
    procedure SetNewName(const Prefix: string);
  public
    Parent: TTemplateElement;
    // Document: TTemplateDoc;
    Elements: TTEmplateElementList;
    Level: Integer;
    Region: TRect;

    Name: string;
    Fixed: Boolean;
    Predefined: Boolean;

    CalculatedValue: string;

    constructor Create(AParent: TTemplateElement); virtual;
    destructor Destroy; override;
    procedure Clear; virtual;

    procedure InternalDraw; virtual;
    procedure CalculateElements; virtual;

    function AddChild(var Element: TTemplateElement): Integer;
    procedure DeleteChild(var Element: TTemplateElement);

    procedure LoadFromXML(Node: IXMLNode); virtual;
    procedure SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode); virtual;
    function AsVarArray: Variant; virtual;

    property Canvas: TCanvas read GetCanvas;
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
    property RootElement: TTemplateElement read FRootElement write FRootElement;
    property XML: string read GetXML write SetXML;
    property TemplateDoc: TTemplateDoc read GetTemplateDoc;
  end;

  TTemplateElementClass = class of TTemplateElement;

  TTEmplateElementList = class(TList)
  private
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    function Get(Index: Integer): TTemplateElement;
    procedure Put(Index: Integer; const Value: TTemplateElement);
  public
    Owner: TTemplateElement;
    RootElement: TTemplateElement;

    constructor Create(AElement: TTemplateElement); overload; virtual;
    destructor Destroy; override;

    procedure Clear; override;
    function Add(var Element: TTemplateElement): Integer;
    procedure Delete(var Element: TTemplateElement);
    procedure Exchange(var Elem1, Elem2: TTemplateElement); overload;

    procedure LoadFromXML(Nodes: IXMLNodeList;
      ElemClass: TTemplateElementClass); overload; virtual;
    procedure SaveToXml(const NodeName: string; XMLDoc: IXMLDocument;
      ParentNode: IXMLNode); virtual;

    property Items[Index: Integer]: TTemplateElement read Get
      write Put; default;
  end;

  THorizontalAlign = (haLeft, haRight, haCenter);
  TVerticalAlign = (vaTop, vaBottom, vaCenter);
  TTextPlacement = (tpTransfer, tpTrim, tpReplace);
  TDisplayType = (dtText, dtBarcode, dtImage);

  TField = class(TTemplateElement)
  public
    FieldType: TFieldType;
    Format: AnsiString;
    Value: Variant;
    Prefix: string;
    Postfix: string;
    IsParameter: Boolean;

    constructor Create(AParent: TTemplateElement); override;

    procedure LoadFromXML(FieldNode: IXMLNode); override;
    procedure SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode); override;
  end;

  TCompositeField = class(TTemplateElement)
  private
    FBarcodeObj: TStBarCode;
    FQRCode: TDelphiZXingQRCode;

    procedure SetFontStyle;
    function GetTextFormat(SingleLine: Boolean = False): UINT;
  public
    Resizable: Boolean;
    FieldLength: Integer;
    HorizontalAlign: THorizontalAlign;
    VerticalAlign: TVerticalAlign;
    TextPlacement: TTextPlacement;
    FontSize: Integer;
    Bold: Boolean;
    Italic: Boolean;
    Underline: Boolean;
    Inversion: Boolean;
    DisplayType: TDisplayType;

    ActualLength: Integer;
    ActualHeight: Integer;

    constructor Create(AParent: TTemplateElement); override;
    destructor Destroy; override;

    procedure CalculateElements; override;
    procedure InternalDraw; override;
    procedure UpdateRegion; override;

    procedure LoadFromXML(ComplsiteFieldNode: IXMLNode); override;
    procedure SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode); override;
    function AsVarArray: Variant; virtual;
  end;

  TCompositeString = class(TTemplateElement)
  public
    MinRows: Integer;
    MaxRows: Integer;
    PrintEmptyData: Boolean;

    constructor Create(AParent: TTemplateElement); override;

    procedure CalculateElements; override;
    procedure InternalDraw; override;
    procedure UpdateRegion; override;

    procedure LoadFromXML(CompositeStringNode: IXMLNode); override;
    procedure SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode); override;
  end;

  TTemplateSection = class(TTemplateElement)
  public
    constructor Create(AParent: TTemplateElement); override;

    procedure UpdateRegion; override;
    procedure CalculateElements; override;
    procedure InternalDraw; override;
    procedure LoadFromXML(TemplateSectionNode: IXMLNode); override;
    procedure SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode); override;
  end;

  TTemplateDoc = class(TTemplateElement)
  private
    // FFullFileName: string;
    //
    FDescription: string;
    FNumber: Integer;

    FExternalCanvas: TCanvas;
    FExternalControl: TControl;
    FFont: TFont;
    FLineLen: Integer;
    FSelected: TTemplateElement;
    FLineWidth: Integer;
    FLineHeight: Integer;
    FSymbWidth: Integer;
    FBarcodeType: Integer;

    FMargin: Integer;
    FPadding: Integer;

    FLabelImages: TLabelImageList;

    FOnChangeView: TNotifyEvent;

    procedure SetSelected(const Value: TTemplateElement);
    procedure SetLineLen(const Value: Integer);
    procedure DrawFrameSelected(OldElem, NewElem: TTemplateElement);
    procedure UpdateRegion; override;
    procedure CalculateElements; override;
  public
    constructor Create(ACanvas: TCanvas; AControl: TControl = nil); overload;
    destructor Destroy; override;
    procedure Clear; override;

    procedure InternalDraw; override;
    procedure DrawDocument(Internal: Boolean = False);
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromXML(XMLDoc: IXMLDocument);
    procedure SaveToFile(const FileName: string);
    procedure SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode); override;
    // procedure OnClick(X, Y: Integer);
    function GetElement(X, Y: Integer): TTemplateElement;
    procedure MoveElement(var Src, Dest: TTemplateElement);
    procedure ExchangeElements(var Elem1, Elem2: TTemplateElement);
    procedure DeleteElement(var Elem: TTemplateElement);
    procedure AddElement(var Parent, Elem: TTemplateElement);

    function GetTemplateParamsArray: OleVariant;
    function GetXMLString: string;

    // procedure Test;
    // property FullFileName: string read FFullFileName write FFullFileName;
    property Description: string read FDescription write FDescription;
    property Number: Integer read FNumber write FNumber;

    property LineLen: Integer read FLineLen write SetLineLen;
    property Selected: TTemplateElement read FSelected write SetSelected;
    property LineWidth: Integer read FLineWidth write FLineWidth;
    property SymbHeight: Integer read FLineHeight write FLineHeight;
    property SymbWidth: Integer read FSymbWidth write FSymbWidth;
    property Margin: Integer read FMargin;
    property Padding: Integer read FPadding;
    property OnChangeView: TNotifyEvent read FOnChangeView write FOnChangeView;
    property LabelImages: TLabelImageList read FLabelImages;
    property BarcodeType: Integer read FBarcodeType write FBarcodeType;
  end;

  TPredefinedData = class(TTemplateElement)
  private
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromXML(XMLDoc: IXMLDocument);
    procedure LoadFromFile(FileName: string);
    procedure SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode); override;
  end;

const
  DefLineLen = 42;
  TemplateElementClasses: array [0 .. 4] of TTemplateElementClass =
    (TTemplateDoc, TTemplateSection, TCompositeString, TCompositeField, TField);

implementation

uses XMLDoc, System.SysUtils, System.Variants;

{ TTemplateDoc }

procedure TTemplateDoc.AddElement(var Parent, Elem: TTemplateElement);
begin
  Parent.AddChild(Elem);
end;

constructor TTemplateDoc.Create(ACanvas: TCanvas; AControl: TControl);
begin
  FExternalCanvas := ACanvas;
  FExternalControl := AControl;
  RootElement := Self;
  inherited Create(Self);

  Level := 0;

  FFont := TFont.Create;
  FFont.Name := 'Courier New';
  FFont.Size := 10;
  // FFont.Name := 'Fixedsys';
  FLineLen := DefLineLen;

  // FFullFileName := '';
  Name := DefTemplateName;
  Description := DefTemplateDescription;

  FMargin := 5;
  FPadding := 7;

  FLabelImages := TLabelImageList.Create;
end;

procedure TTemplateDoc.DeleteElement(var Elem: TTemplateElement);
begin
  if Elem.Parent <> nil then
    Elem.Parent.DeleteChild(Elem);
  FreeAndNil(Elem);
end;

destructor TTemplateDoc.Destroy;
begin
  FLabelImages.Free;
  FFont.Free;
  inherited;
end;

procedure TTemplateDoc.DrawDocument(Internal: Boolean);
var
  OldSelected: TTemplateElement;
begin
  if FExternalCanvas = nil then
    Exit;

  OldSelected := Selected;
  Selected := nil;

  if Internal then
  begin
    FExternalCanvas.Font.Assign(FFont);
    SymbHeight := FExternalCanvas.TextHeight('A') + 1;
    SymbWidth := FExternalCanvas.TextWidth('W');
    LineWidth := SymbWidth * LineLen;

    CalculateElements;
    InternalDraw;
    UpdateRegion;

    if Assigned(FOnChangeView) then
      FOnChangeView(Self);
  end
  else if (Elements.Count > 0) then
  begin
    FExternalCanvas.Brush.Color := clWhite;
    FExternalCanvas.FillRect(Rect(FMargin, FMargin, Width + FPadding * 2 +
      FMargin, Height + FPadding * 2 + FMargin));
    FExternalCanvas.Brush.Color := clGray;
    FExternalCanvas.FrameRect(Rect(FMargin - 1, FMargin - 1,
      Width + FPadding * 2 + FMargin + 1, Height + FPadding * 2 + FMargin + 1));

    FExternalCanvas.CopyRect(Rect(FMargin + FPadding, FMargin + FPadding,
      Width + FMargin + FPadding, Height + FMargin + FPadding), Canvas,
      Rect(0, 0, Width, Height));
  end;

  Selected := OldSelected;
  if (FExternalControl <> nil) and (Internal) then
    FExternalControl.Invalidate;
end;

procedure TTemplateDoc.DrawFrameSelected(OldElem, NewElem: TTemplateElement);
  procedure DrawFrame(Elem: TTemplateElement);
  var
    _Elem: TTemplateElement;
  begin
    if Elem = nil then
      Exit;
    if Elem.Level > 3 then
      _Elem := Elem.Parent
    else
      _Elem := Elem;
    if _Elem = nil then
      Exit;

    with _Elem.Region do
      FExternalCanvas.Polyline([Point(Left, Top), Point(Right, Top),
        Point(Right, Bottom), Point(Left, Bottom), Point(Left, Top)]);
  end;

begin
  if FExternalCanvas = nil then
    Exit;

  FExternalCanvas.Pen.Color := clBlue;
  FExternalCanvas.Pen.Mode := pmNotXor;
  DrawFrame(OldElem);
  DrawFrame(NewElem);
  FExternalCanvas.Pen.Color := clBlack;
  FExternalCanvas.Pen.Mode := pmCopy;

  // if FExternalControl <> nil then
  // FExternalControl.Invalidate;
end;

procedure TTemplateDoc.ExchangeElements(var Elem1, Elem2: TTemplateElement);
begin
  if Elem1.Parent <> Elem2.Parent then
    Exit;

  Elem1.Parent.Elements.Exchange(Elem1, Elem2);
end;

function TTemplateDoc.GetElement(X, Y: Integer): TTemplateElement;
var
  I: Integer;
  Elem: TTemplateElement;
begin
  Elem := Self;

  while Elem.Level < 3 do
  begin
    Result := nil;
    for I := 0 to Elem.Elements.Count - 1 do
    begin
      if Elem.Elements[I].Region.Contains(Point(X, Y)) then
      begin
        Result := Elem.Elements[I];
        if Elem.Elements[I].Elements.Count = 0 then
          Exit;

        Break;
      end;
    end;

    if Result = nil then
      Exit;

    Elem := Result;
  end;
end;

function TTemplateDoc.GetTemplateParamsArray: OleVariant;
var
  SectCnt, CompStrCnt, CompFldCnt, FldCnt: Integer;
  ElemSect, ElemCompStr, ElemCompFld: TTemplateElement;
  Fld: TField;
  DataSections: TDataSections;
  DataSection: TDataSection;
  EmptySection: Boolean;
begin
  Result := Unassigned;
  if Elements.Count = 0 then
    Exit;

  DataSections := TDataSections.Create;
  try
    for SectCnt := 0 to Elements.Count - 1 do
    begin
      ElemSect := Elements[SectCnt];
      DataSection := DataSections.Add(ElemSect.Name);
      EmptySection := True;
      for CompStrCnt := 0 to ElemSect.Elements.Count - 1 do
      begin
        ElemCompStr := ElemSect.Elements[CompStrCnt];
        for CompFldCnt := 0 to ElemCompStr.Elements.Count - 1 do
        begin
          ElemCompFld := ElemCompStr.Elements[CompFldCnt];
          for FldCnt := 0 to ElemCompFld.Elements.Count - 1 do
          begin
            EmptySection := False;
            Fld := TField(ElemCompFld.Elements[FldCnt]);
            if Fld.IsParameter then
              DataSection.AddParam(Fld.Name, Fld.Value);
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

function TTemplateDoc.GetXMLString: string;
var
  XMLDoc: IXMLDocument;
begin
  Result := '';

  XMLDoc := TXMLDocument.Create(nil);
  try
    XMLDoc.Active := True;

    SaveToXml(XMLDoc, nil);
    Result := XMLDoc.XML.Text;
  finally
    XMLDoc := nil;
  end;
end;

procedure TTemplateDoc.InternalDraw;
var
  I, Y: Integer;
  R: TRect;
begin
  inherited;

  Y := 0;
  for I := 0 to Elements.Count - 1 do
  begin
    Elements[I].InternalDraw;
    Canvas.CopyRect(Rect(0, Y, Elements[I].Width, Y + Elements[I].Height),
      Elements[I].Canvas, Rect(0, 0, Elements[I].Width, Elements[I].Height));

    Inc(Y, Elements[I].Height);
  end;
end;

procedure TTemplateDoc.LoadFromFile(const FileName: string);
var
  XMLDoc: IXMLDocument;
begin
  // FFullFileName := ExtractFileDir(FileName);

  XMLDoc := TXMLDocument.Create(nil);
  try
    Name := ExtractFileName(FileName);
    XMLDoc.LoadFromFile(FileName);
    XMLDoc.Active := True;

    LoadFromXML(XMLDoc);
  finally
    XMLDoc := nil;
  end;
end;

procedure TTemplateDoc.LoadFromXML(XMLDoc: IXMLDocument);
var
  Node: IXMLNode;
begin
  Selected := nil;

  Node := XMLDoc.DocumentElement.ChildNodes.FindNode('Template');
  if Node = nil then
    raise Exception.Create('Неверная структура шаблона');

  FDescription := VarToStringDef(Node.Attributes['Description'], '');
  FNumber := VarToIntDef(Node.Attributes['Number'], 1);
  FLineLen := VarToIntDef(Node.Attributes['LineLen'], DefLineLen);

  Elements.LoadFromXML(Node.ChildNodes, TTemplateSection);

  FLabelImages.LoadFromXML(XMLDoc, DefImagesXMLNodeName);
end;

procedure TTemplateDoc.MoveElement(var Src, Dest: TTemplateElement);
var
  SrcList, DstList: TTEmplateElementList;
begin
  if (Src.Level - Dest.Level) = 1 then // Меняем родителя
  begin
    SrcList := Src.Parent.Elements;
    DstList := Dest.Elements;

    SrcList.Delete(Src);
    DstList.Add(Src);

    DrawDocument(True);
  end;
end;

procedure TTemplateDoc.SaveToFile(const FileName: string);
var
  XMLDoc: IXMLDocument;
begin
  XMLDoc := TXMLDocument.Create(nil);
  try
    XMLDoc.Active := True;

    SaveToXml(XMLDoc, nil);
    XMLDoc.SaveToFile(FileName);
    // FFullFileName := FileName;
  finally
    XMLDoc := nil;
  end;
end;

procedure TTemplateDoc.SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode);
begin
  XMLDoc.Encoding := 'UTF-16';

  XMLDoc.DocumentElement := XMLDoc.CreateNode('Data', ntElement, '');
  Node := XMLDoc.DocumentElement.AddChild('Template');

  Node.Attributes['Number'] := Number;
  Node.Attributes['Description'] := Description;
  Node.Attributes['LineLen'] := LineLen;

  Elements.SaveToXml('Section', XMLDoc, Node);

  FLabelImages.SaveToXml(XMLDoc);
end;

procedure TTemplateDoc.SetLineLen(const Value: Integer);
begin
  FLineLen := Value;
  DrawDocument(True);
end;

procedure TTemplateDoc.SetSelected(const Value: TTemplateElement);
begin
  DrawFrameSelected(FSelected, Value);
  FSelected := Value;
end;

// procedure TTemplateDoc.Test;
// var
// R: TRect;
// begin
// FExternalCanvas.Pen.Color := clRed;
// FExternalCanvas.Brush.Color := clWhite;
// R := Rect(10, 10, 100, 100);
// FExternalCanvas.FrameRect(R);
// FExternalCanvas.Font.Style := [fsUnderline];
//
// DrawText(FExternalCanvas.Handle, PWideChar('******'), 6, R, 0);
//
// end;

procedure TTemplateDoc.UpdateRegion;
var
  I, Y: Integer;
  Document: TTemplateDoc;
begin
  inherited;

  if (RootElement = nil) or not(RootElement is TTemplateDoc) then
    Exit;
  Document := TTemplateDoc(RootElement);

  Region.Left := Document.Padding + Document.Margin;
  Region.Right := Region.Left + Width;
  Region.Top := Document.Padding + Document.Margin;
  Region.Bottom := Region.Top + Height;

  Y := 0;
  for I := 0 to Elements.Count - 1 do
  begin
    Elements[I].Region.Left := Region.Left;
    Elements[I].Region.Right := Region.Right;
    Elements[I].Region.Top := Y + Region.Top;
    Elements[I].Region.Bottom := Elements[I].Region.Top + Elements[I].Height;

    Elements[I].UpdateRegion;
    Inc(Y, Elements[I].Height);
  end;
end;

procedure TTemplateDoc.CalculateElements;
var
  I, Y: Integer;
begin
  inherited;

  Width := LineLen * SymbWidth;

  Y := 0;
  for I := 0 to Elements.Count - 1 do
  begin
    Elements[I].Width := Width;
    Elements[I].CalculateElements;
    Inc(Y, Elements[I].Height);
  end;

  Height := Y;
end;

procedure TTemplateDoc.Clear;
begin
  inherited;

  FLabelImages.Clear;
  Name := DefTemplateName;
  Description := DefTemplateDescription;

  FSelected := nil;
  DrawDocument(True)
end;

{ TField }

constructor TField.Create(AParent: TTemplateElement);
begin
  inherited;

  SetNewName('Поле');
  FieldType := ftString;
  Format := '';
  IsParameter := False;
  Prefix := '';
  Postfix := '';
  Value := 'Значение поля';
end;

procedure TField.LoadFromXML(FieldNode: IXMLNode);
begin
  inherited;

  FieldType := TFieldType(VarToIntDef(FieldNode.Attributes['Type'], 0));
  Format := VarToStringDef(FieldNode.Attributes['Format'], '');
  Value := GetFldValueAsType(FieldNode.Attributes['Value'], FieldType);
  Prefix := VarToStringDef(FieldNode.Attributes['Prefix'], '');
  Postfix := VarToStringDef(FieldNode.Attributes['Postfix'], '');
  IsParameter := VarToBoolDef(FieldNode.Attributes['IsParameter'], False);
end;

procedure TField.SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode);
begin
  inherited;

  Node.Attributes['Type'] := FieldType;
  Node.Attributes['Format'] := Format;
  Node.Attributes['Value'] := Value;
  Node.Attributes['Prefix'] := Prefix;
  Node.Attributes['Postfix'] := Postfix;
  Node.Attributes['IsParameter'] := IsParameter;
end;

{ TComplsiteField }

function TCompositeField.AsVarArray: Variant;
var
  I: Integer;
begin
  // Result := VarArrayCreate([0, 1, 0, Elements.Count - 1], varVariant);
  // for I := 0 to Elements.Count - 1 do
  // begin
  //
  // end;
end;

procedure TCompositeField.CalculateElements;
var
  I, StrCount: Integer;
  Fld: TField;
  CompStr: TCompositeString;
  Document: TTemplateDoc;
  Image: TLabelImage;
begin
  inherited;

  if (RootElement = nil) or not(RootElement is TTemplateDoc) then
    Exit;
  Document := TTemplateDoc(RootElement);

  CalculatedValue := '';
  for I := 0 to Elements.Count - 1 do
  begin
    Fld := TField(Elements[I]);
    Fld.CalculatedValue := Fld.Prefix + FormatValue(Fld.Value,
      Ord(Fld.FieldType), Fld.Format) + Fld.Postfix;

    CalculatedValue := CalculatedValue + Fld.CalculatedValue;
  end;

  // Вычислим высоту поля
  ActualHeight := 1;
  try
    if (Parent = nil) or not(Parent is TCompositeString) then
      Exit;

    CompStr := TCompositeString(Parent);
    if (CompStr.MaxRows < CompStr.MinRows) or (CompStr.MaxRows = 1) then
      Exit;
    ActualHeight := CompStr.MinRows;
    if CompStr.MinRows = CompStr.MaxRows then
      Exit;

    ActualHeight := GetStrigsCount(CalculatedValue, ActualLength);
    if ActualHeight > CompStr.MaxRows then
      ActualHeight := CompStr.MaxRows
    else if ActualHeight < CompStr.MinRows then
      ActualHeight := CompStr.MinRows;
  finally
    Height := Document.SymbHeight * ActualHeight;
    if FontSize > 0 then
      Height := Height * (Abs(FontSize) + 1)
    else if FontSize < 0 then
      Height := Height div (Abs(FontSize) + 1);

    Width := Document.SymbWidth * ActualLength;

    if DisplayType = dtImage then // Для картинки пересчитаем
    begin
      Image := Document.LabelImages.FindImageByID(CalculatedValue);
      if Image <> nil then
      begin
        Height := Image.Bitmap.Height;
        Width := Document.LineWidth;
      end;
    end
    else if DisplayType = dtBarcode then // Для баркода пересчитаем
    begin
      Width := Document.LineWidth;
      if Document.BarcodeType = 10 then
        Height := Width - (Document.SymbWidth * Def2DBarcodeMargin * 2)
      else
        Height := Document.SymbHeight * Def1DBarcodeHeight;
    end;
  end;
end;

constructor TCompositeField.Create(AParent: TTemplateElement);
begin
  inherited;

  FBarcodeObj := TStBarCode.Create(nil);
  FBarcodeObj.BarcodeType := bcCode128;
  FBarcodeObj.ShowCode := False;
  FBarcodeObj.DPIX := GetDeviceCaps(GetDC(0), LOGPIXELSX);
  FBarcodeObj.DPIY := GetDeviceCaps(GetDC(0), LOGPIXELSY);

  FQRCode := TDelphiZXingQRCode.Create;

  SetNewName('Составное поле');
  FontSize := 0;
  HorizontalAlign := haLeft;
  VerticalAlign := vaTop;
  FieldLength := 10;
  Resizable := True;
  TextPlacement := tpTrim;
end;

destructor TCompositeField.Destroy;
begin
  FQRCode.Free;
  FBarcodeObj.Free;
  inherited;
end;

function TCompositeField.GetTextFormat(SingleLine: Boolean = False): UINT;
begin
  Result := 0;

  if SingleLine then
    Result := Result + DT_SINGLELINE;

  case HorizontalAlign of
    haLeft:
      Result := Result or DT_LEFT;
    haCenter:
      Result := Result or DT_CENTER;
    haRight:
      Result := Result or DT_RIGHT;
  end;

  case VerticalAlign of
    vaTop:
      Result := Result or DT_TOP;
    vaCenter:
      Result := Result or DT_VCENTER;
    vaBottom:
      Result := Result or DT_BOTTOM;
  end;

  case TextPlacement of
    tpTransfer:
      if not SingleLine then
        Result := Result or DT_WORDBREAK or DT_EDITCONTROL;
    tpTrim:
      ;
    tpReplace:
      ;
  end;
end;

procedure TCompositeField.InternalDraw;
var
  R: TRect;
  SingleLine: Boolean;
  LeftMargin: Integer;
  Image: TLabelImage;
  BarcodeType: Integer;
begin
  inherited;
  SingleLine := GetStrigsCount(CalculatedValue, ActualLength) = 1;

  if TemplateDoc <> nil then
    Canvas.Font.Assign(TemplateDoc.FFont);
  Canvas.Brush.Color := clWhite;

  R := Rect(0, 0, Width, Height);
  Canvas.FillRect(R);
  SetFontStyle;

  if DisplayType = dtBarcode then
  begin
    if TemplateDoc <> nil then
      BarcodeType := TemplateDoc.BarcodeType
    else
      BarcodeType := 9;

    if BarcodeType < 10 then // 1D Barcode
    begin
      FBarcodeObj.BarcodeType := TStBarCodeType(BarcodeType);
      FBarcodeObj.Code := CalculatedValue;

      case HorizontalAlign of
        haRight:
          LeftMargin :=
            (Width - Round(FBarcodeObj.GetBarCodeWidth(Canvas, True)));
        haCenter:
          LeftMargin := (Width - Round(FBarcodeObj.GetBarCodeWidth(Canvas,
            True))) div 2;
      else
        LeftMargin := 0;
      end;

      R := Rect(LeftMargin, 0, Width, Height);
      FBarcodeObj.PaintToCanvas(Canvas, R);
    end
    else // QR-Code
    begin
      FQRCode.Data := CalculatedValue;
      if Height < Width then
      begin
        LeftMargin := (Width - Height) div 2;
        R := Rect(LeftMargin, 0, Height + LeftMargin, Height);
      end
      else
        R := Rect(0, 0, Width, Height);
      FQRCode.PaintToCanvas(Canvas, R);
    end;
  end
  else if DisplayType = dtImage then
  begin
    if TemplateDoc <> nil then
    begin
      Image := TemplateDoc.LabelImages.FindImageByID(CalculatedValue);
      if Image <> nil then
      begin
        case HorizontalAlign of
          haRight:
            LeftMargin := (Width - Round(Image.Bitmap.Width));
          haCenter:
            LeftMargin := (Width - Round(Image.Bitmap.Width)) div 2;
        else
          LeftMargin := 0;
        end;

        // Height := Image.Bitmap.Height;
        Canvas.Draw(LeftMargin, 0, Image.Bitmap);
      end;
    end;
  end
  else
    DrawText(Canvas.Handle, PWideChar(CalculatedValue), Length(CalculatedValue),
      R, GetTextFormat(SingleLine));
end;

procedure TCompositeField.LoadFromXML(ComplsiteFieldNode: IXMLNode);
begin
  inherited;

  Resizable := ComplsiteFieldNode.Attributes['Resizable'];
  FieldLength := ComplsiteFieldNode.Attributes['Length'];
  HorizontalAlign := THorizontalAlign(ComplsiteFieldNode.Attributes
    ['HorizontalAlign']);
  VerticalAlign := TVerticalAlign(ComplsiteFieldNode.Attributes
    ['VerticalAlign']);
  TextPlacement := TTextPlacement(ComplsiteFieldNode.Attributes
    ['TextPlacement']);
  FontSize := ComplsiteFieldNode.Attributes['FontSize'];
  Bold := ComplsiteFieldNode.Attributes['Bold'];
  Italic := ComplsiteFieldNode.Attributes['Italic'];
  Underline := ComplsiteFieldNode.Attributes['Underline'];
  Inversion := ComplsiteFieldNode.Attributes['Inversion'];
  DisplayType := TDisplayType
    (VarToIntDef(ComplsiteFieldNode.Attributes['DisplayType'], 0));

  Elements.LoadFromXML(ComplsiteFieldNode.ChildNodes, TField);
end;

procedure TCompositeField.SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode);
begin
  inherited;

  Node.Attributes['Resizable'] := Resizable;
  Node.Attributes['Length'] := FieldLength;
  Node.Attributes['HorizontalAlign'] := HorizontalAlign;
  Node.Attributes['VerticalAlign'] := VerticalAlign;
  Node.Attributes['TextPlacement'] := TextPlacement;
  Node.Attributes['FontSize'] := FontSize;
  Node.Attributes['Bold'] := Bold;
  Node.Attributes['Italic'] := Italic;
  Node.Attributes['Underline'] := Underline;
  Node.Attributes['Inversion'] := Inversion;
  Node.Attributes['DisplayType'] := DisplayType;

  Elements.SaveToXml('Field', XMLDoc, Node);
end;

procedure TCompositeField.SetFontStyle;
var
  FontStyles: TFontStyles;
begin

  FontStyles := [];
  if Bold then
    Include(FontStyles, fsBold);
  if Italic then
    Include(FontStyles, fsItalic);
  if Underline then
    Include(FontStyles, fsUnderline);

  Canvas.Font.Style := FontStyles;
  if FontSize > 0 then
    Canvas.Font.Size := Canvas.Font.Size * (Abs(FontSize) + 1)
  else if FontSize < 0 then
    Canvas.Font.Size := Canvas.Font.Size div (Abs(FontSize) + 1);

  if Inversion then
  begin
    Canvas.Brush.Color := clBlack;
    Canvas.Font.Color := clWhite;
  end;
end;

procedure TCompositeField.UpdateRegion;
begin
  inherited;

end;

{ TCompositeString }

procedure TCompositeString.CalculateElements;
var
  I, TotalFixedLength, TotalAutoLength, RemLength: Integer;
  Fld: TCompositeField;
  Document: TTemplateDoc;
  AutoFldUnt: Double;
begin
  inherited;

  if (RootElement = nil) or not(RootElement is TTemplateDoc) then
    Exit;
  Document := TTemplateDoc(RootElement);

  // Вычислим ширину полей
  TotalFixedLength := 0;
  TotalAutoLength := 0;
  for I := 0 to Elements.Count - 1 do
  begin
    Fld := TCompositeField(Elements[I]);
    if not Fld.Resizable then
    begin
      Fld.ActualLength := Fld.FieldLength;
      Inc(TotalFixedLength, Fld.FieldLength);
    end
    else
      Inc(TotalAutoLength, Fld.FieldLength);
  end;

  RemLength := Abs(Document.LineLen - TotalFixedLength);
  if TotalAutoLength > 0 then
  begin
    AutoFldUnt := RemLength / TotalAutoLength;
    for I := 0 to Elements.Count - 1 do
    begin
      Fld := TCompositeField(Elements[I]);
      if Fld.Resizable then
      begin
        if I < (Elements.Count - 1) then
          Fld.ActualLength := Round(Fld.FieldLength * AutoFldUnt)
        else
          Fld.ActualLength := RemLength;

        Dec(RemLength, Fld.ActualLength);
      end;
    end;
  end;

  // Вычислим высоту полей
  Height := Document.SymbHeight; // !!!
  for I := 0 to Elements.Count - 1 do
  begin
    Elements[I].CalculateElements;
    if Elements[I].Height > Height then
      Height := Elements[I].Height;
  end;
  for I := 0 to Elements.Count - 1 do
    Elements[I].Height := Height;
end;

constructor TCompositeString.Create(AParent: TTemplateElement);
begin
  inherited;

  SetNewName('Составная строка');
  MinRows := 0;
  MaxRows := 1;
  PrintEmptyData := True;
end;

procedure TCompositeString.InternalDraw;
var
  I, X: Integer;
begin
  inherited;

  X := 0;
  for I := 0 to Elements.Count - 1 do
  begin
    Elements[I].InternalDraw;
    Canvas.CopyRect(Rect(X, 0, X + Elements[I].Width, Elements[I].Height),
      Elements[I].Canvas, Rect(0, 0, Elements[I].Width, Elements[I].Height));

    Inc(X, Elements[I].Width);
  end;
end;

procedure TCompositeString.LoadFromXML(CompositeStringNode: IXMLNode);
begin
  inherited;

  MinRows := CompositeStringNode.Attributes['MinRows'];
  MaxRows := CompositeStringNode.Attributes['MaxRows'];
  PrintEmptyData := VarToBoolDef(CompositeStringNode.Attributes
    ['PrintEmptyData'], True);

  Elements.LoadFromXML(CompositeStringNode.ChildNodes, TCompositeField);
end;

procedure TCompositeString.SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode);
begin
  inherited;

  Node.Attributes['MinRows'] := MinRows;
  Node.Attributes['MaxRows'] := MaxRows;
  Node.Attributes['PrintEmptyData'] := PrintEmptyData;

  Elements.SaveToXml('CompositeField', XMLDoc, Node);
end;

procedure TCompositeString.UpdateRegion;
var
  I, X: Integer;
begin
  inherited;

  X := 0;
  for I := 0 to Elements.Count - 1 do
  begin
    Elements[I].Region.Left := X + Region.Left;
    Elements[I].Region.Right := Elements[I].Region.Left + Elements[I].Width;
    Elements[I].Region.Top := Region.Top;
    Elements[I].Region.Bottom := Region.Bottom;

    Elements[I].UpdateRegion;
    Inc(X, Elements[I].Width);
  end;
end;

{ TTemplateSection }

constructor TTemplateSection.Create(AParent: TTemplateElement);
begin
  inherited;

  SetNewName('Секция');
end;

procedure TTemplateSection.InternalDraw;
var
  I, Y: Integer;
begin
  inherited;

  Y := 0;
  for I := 0 to Elements.Count - 1 do
  begin
    Elements[I].InternalDraw;
    Canvas.CopyRect(Rect(0, Y, Elements[I].Width, Y + Elements[I].Height),
      Elements[I].Canvas, Rect(0, 0, Elements[I].Width, Elements[I].Height));

    Inc(Y, Elements[I].Height);
  end;
end;

procedure TTemplateSection.LoadFromXML(TemplateSectionNode: IXMLNode);
begin
  inherited;

  if RootElement is TPredefinedData then
    Elements.LoadFromXML(TemplateSectionNode.ChildNodes, TField)
  else
    Elements.LoadFromXML(TemplateSectionNode.ChildNodes, TCompositeString);
end;

procedure TTemplateSection.SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode);
begin
  inherited;

  if not(RootElement is TPredefinedData) then
    Elements.SaveToXml('CompositeString', XMLDoc, Node)
  else
    Elements.SaveToXml('Field', XMLDoc, Node)
end;

procedure TTemplateSection.UpdateRegion;
var
  I, Y: Integer;
begin
  inherited;

  Y := 0;
  for I := 0 to Elements.Count - 1 do
  begin
    Elements[I].Region.Left := Region.Left;
    Elements[I].Region.Right := Region.Right;
    Elements[I].Region.Top := Y + Region.Top;
    Elements[I].Region.Bottom := Elements[I].Region.Top + Elements[I].Height;

    Elements[I].UpdateRegion;
    Inc(Y, Elements[I].Height);
  end;
end;

procedure TTemplateSection.CalculateElements;
var
  I, Y: Integer;
begin
  inherited;

  Y := 0;
  for I := 0 to Elements.Count - 1 do
  begin
    Elements[I].Width := Width;
    Elements[I].CalculateElements;
    Inc(Y, Elements[I].Height);
  end;

  Height := Y;
end;

{ TTemplateElement }

function TTemplateElement.AddChild(var Element: TTemplateElement): Integer;
begin
  Result := Elements.Add(Element);
end;

function TTemplateElement.AsVarArray: Variant;
begin
  Result := Unassigned;
end;

procedure TTemplateElement.CalculateElements;
begin

end;

procedure TTemplateElement.Clear;
begin
  Elements.Clear;
  CalculatedValue := '';
  Fixed := False;
  Name := '';
  Predefined := False;
  Region.Left := 0;
  Region.Right := 0;
  Region.Top := 0;
  Region.Bottom := 0;
  Width := 0;
  Height := 0;
end;

constructor TTemplateElement.Create(AParent: TTemplateElement);
begin
  FBitMap := TBitMap.Create;
  FBitMap.Monochrome := False;
  FBitMap.PixelFormat := pf8bit;

  Parent := AParent;
  RootElement := AParent.RootElement;

  if (RootElement is TPredefinedData) and (AParent is TTemplateSection) then
    Level := 4
  else
    Level := AParent.Level + 1;

  Elements := TTEmplateElementList.Create(Self);

  SetNewName('Новый элемент');
end;

procedure TTemplateElement.DeleteChild(var Element: TTemplateElement);
begin
  Elements.Delete(Element);
end;

destructor TTemplateElement.Destroy;
begin
  if Elements <> nil then
    FreeAndNil(Elements);

  FreeAndNil(FBitMap);
  inherited;
end;

function TTemplateElement.GetCanvas: TCanvas;
begin
  Result := FBitMap.Canvas;
end;

function TTemplateElement.GetHeight: Integer;
begin
  Result := FBitMap.Height;
end;

function TTemplateElement.GetTemplateDoc: TTemplateDoc;
begin
  if (RootElement <> nil) and (RootElement is TTemplateDoc) then
    Result := TTemplateDoc(RootElement)
  else
    Result := nil;
end;

function TTemplateElement.GetWidth: Integer;
begin
  Result := FBitMap.Width;
end;

function TTemplateElement.GetXML: string;
var
  XMLDoc: IXMLDocument;
begin
  XMLDoc := TXMLDocument.Create(nil);
  try
    XMLDoc.Active := True;

    XMLDoc.DocumentElement := XMLDoc.CreateNode('Data', ntElement, '');
    SaveToXml(XMLDoc, XMLDoc.DocumentElement);

    // XMLDoc.Active := False;
    Result := XMLDoc.XML.Text;
  finally
    XMLDoc := nil;
  end;
end;

procedure TTemplateElement.InternalDraw;
begin
  // Canvas.Font.Assign(RootElement.FFont);
  // // if IsSelected then
  // // Canvas.Brush.Color := clSkyBlue
  // // else
  // Canvas.Brush.Color := clWhite;
end;

// function TTemplateElement.IsSelected: Boolean;
// var
// Elem: TTemplateElement;
// begin
// Result := False;
//
// Elem := Self;
// while (Elem <> nil) and (Elem.Parent <> Elem) do
// begin
// Result := Document.Selected = Elem;
// if Result then
// Exit;
// Elem := Elem.Parent;
// end;
// end;

procedure TTemplateElement.LoadFromXML(Node: IXMLNode);
begin
  if Node = nil then
    Exit;

  Name := VarToStringDef(Node.Attributes['Name'], '');
  Fixed := VarToBoolDef(Node.Attributes['Fixed'], False);
  Predefined := VarToBoolDef(Node.Attributes['Predefined'], False);
end;

procedure TTemplateElement.SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode);
begin
  Node.Attributes['Name'] := Name;
  Node.Attributes['Predefined'] := Predefined;
  Node.Attributes['Fixed'] := Fixed;
end;

procedure TTemplateElement.SetHeight(const Value: Integer);
begin
  FBitMap.Height := Value;
end;

procedure TTemplateElement.SetNewName(const Prefix: string);
begin
  Name := Prefix;
  if Parent <> nil then
    Name := Name + ' ' + IntToStr(Parent.Elements.Count + 1);
end;

procedure TTemplateElement.SetWidth(const Value: Integer);
begin
  FBitMap.Width := Value;
end;

procedure TTemplateElement.SetXML(const Value: string);
var
  XMLDoc: IXMLDocument;
begin
  if Length(Value) = 0 then
    Exit;

  XMLDoc := TXMLDocument.Create(nil);
  try
    XMLDoc.XML.Text := Value;
    XMLDoc.Active := True;

    LoadFromXML(XMLDoc.DocumentElement);
  finally
    XMLDoc := nil;
  end;
end;

procedure TTemplateElement.UpdateRegion;
begin

end;

{ TTEmplateElementList }

procedure TTEmplateElementList.Clear;
var
  I: Integer;
  Elem: TTemplateElement;
begin
  for I := Pred(Count) downto 0 do
  begin
    Elem := Items[I];
    if Elem <> nil then
      FreeAndNil(Elem);
  end;
  inherited;
end;

constructor TTEmplateElementList.Create(AElement: TTemplateElement);
begin
  Owner := AElement;
  RootElement := AElement.RootElement;
end;

function TTEmplateElementList.Add(var Element: TTemplateElement): Integer;
begin
  inherited Add(TObject(Element));
  Element.Parent := Owner;
end;

procedure TTEmplateElementList.Delete(var Element: TTemplateElement);
begin
  inherited Delete(IndexOf(Element));
end;

destructor TTEmplateElementList.Destroy;
begin
  Clear;
  inherited;
end;

procedure TTEmplateElementList.Exchange(var Elem1, Elem2: TTemplateElement);
begin
  inherited Exchange(IndexOf(Elem1), IndexOf(Elem2));
end;

function TTEmplateElementList.Get(Index: Integer): TTemplateElement;
begin
  Result := TTemplateElement(inherited Get(Index));
end;

procedure TTEmplateElementList.LoadFromXML(Nodes: IXMLNodeList;
  ElemClass: TTemplateElementClass);
var
  I: Integer;
  Elem: TTemplateElement;
begin
  inherited;
  Clear;
  if Nodes = nil then
    Exit;

  for I := 0 to Nodes.Count - 1 do
  begin
    Elem := ElemClass.Create(Self.Owner);
    Elem.LoadFromXML(Nodes.Nodes[I]);
    Add(Elem);
  end;
end;

procedure TTEmplateElementList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  inherited;
  // if Action = lnDeleted then
  // TTemplateElement(Ptr).Free;
end;

procedure TTEmplateElementList.Put(Index: Integer;
  const Value: TTemplateElement);
begin
  inherited Put(Index, Pointer(Value));
end;

procedure TTEmplateElementList.SaveToXml(const NodeName: string;
  XMLDoc: IXMLDocument; ParentNode: IXMLNode);
var
  I: Integer;
  Node: IXMLNode;
begin
  for I := 0 to Count - 1 do
  begin
    Node := XMLDoc.CreateNode(NodeName);
    ParentNode.ChildNodes.Add(Node);
    Items[I].SaveToXml(XMLDoc, Node);
  end;
end;

{ TPredefinedData }

constructor TPredefinedData.Create;
begin
  RootElement := Self;
  inherited Create(Self);

  Level := 0;
end;

destructor TPredefinedData.Destroy;
begin

  inherited;
end;

procedure TPredefinedData.LoadFromFile(FileName: string);
var
  XMLDoc: IXMLDocument;
begin
  XMLDoc := TXMLDocument.Create(nil);
  try
    Name := ExtractFileName(FileName);
    XMLDoc.LoadFromFile(FileName);
    XMLDoc.Active := True;

    LoadFromXML(XMLDoc);
  finally
    XMLDoc := nil;
  end;
end;

procedure TPredefinedData.LoadFromXML(XMLDoc: IXMLDocument);
var
  Node: IXMLNode;
begin
  Elements.Clear;
  Node := XMLDoc.DocumentElement.ChildNodes.FindNode('PredefinedData');
  if Node = nil then
    Exit;

  Elements.LoadFromXML(Node.ChildNodes, TTemplateSection);
end;

procedure TPredefinedData.SaveToXml(XMLDoc: IXMLDocument; Node: IXMLNode);
begin
  if Elements.Count = 0 then
    Exit;

  Node := XMLDoc.DocumentElement.AddChild('PredefinedData');

  Elements.SaveToXml('Section', XMLDoc, Node);
end;

end.
