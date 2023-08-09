unit uImageListCommon;

interface

uses System.Types, Vcl.Graphics, System.Classes, Xml.XMLIntf;

const
  DefImagesXMLNodeName = 'ImageList';

type
  TLabelImage = class
  private
    FID: string;
    FName: string;
    FPath: string;
    FBitMap: TBitMap;
    function GetFileName: string;
    function GetBytes: TByteDynArray;
    procedure SetBytes(Value: TByteDynArray);
  public
    constructor Create(ANameOrPath, AID: string); overload;
    constructor Create(AName, APath, AID: string;
      AData: TByteDynArray); overload;
    destructor Destroy;
    // procedure GetBmpFromString(const S: string);
    property Name: string read FName;
    property Path: string read FPath;
    property ID: string read FID write FID;
    property FileName: string read GetFileName;
    property Bitmap: TBitMap read FBitMap;
    property Bytes: TByteDynArray read GetBytes write SetBytes;
  end;

  TLabelImageList = class(TList)
  private
    function GetImage(Index: Integer): TLabelImage; overload;
    procedure PutImage(Index: Integer; Item: TLabelImage);
    function GetFirstLineNumber(Index: Integer): Integer; overload;
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    function AddImage(AName, APath: string; AData: TByteDynArray)
      : Integer; overload;
    function AddImage(AName, APath, AID: string; AData: TByteDynArray)
      : Integer; overload;
  public
    function AddImage(const ANameOrPath: string): Integer; overload;
    function GetImage(const AName: string): TLabelImage; overload;
    function FindImageByID(const AID: string): TLabelImage;
    function ImageIndexFromID(const AID: string): Integer;

    procedure GetStrings(Strings: TStrings);
    // procedure SaveToXML(var XmlDoc: OleVariant;
    // const NodeName: string = DefXMLNodeName); overload;
    procedure SaveToXML(var XmlDoc: IXMLDocument;
      const NodeName: string = DefImagesXMLNodeName);
    // procedure LoadFromXML(const XmlDoc: OleVariant); overload;
    procedure LoadFromXML(const XmlDoc: IXMLDocument;
      const NodeName: string = DefImagesXMLNodeName);

    property Images[Index: Integer]: TLabelImage read GetImage
      write PutImage; default;
    property FirstLineNumber[Index: Integer]: Integer read GetFirstLineNumber;
  end;

implementation

uses System.SysUtils, uCommonUtils, System.Variants, Soap.EncdDecd;

{ TLabelImage }

constructor TLabelImage.Create(ANameOrPath, AID: string);
begin
  inherited Create;
  FBitMap := TBitMap.Create;
  FID := AID;

  if LastDelimiter(PathDelim + DriveDelim, ANameOrPath) = 0 then
  begin
    FName := ANameOrPath;
    FPath := '';
  end
  else
  begin
    FPath := ExtractFilePath(ANameOrPath);
    FName := ExtractFileName(ANameOrPath);
    if FileExists(ANameOrPath) then
      try
        FBitMap.LoadFromFile(ANameOrPath);
      except
      end;
  end;
end;

constructor TLabelImage.Create(AName, APath, AID: string; AData: TByteDynArray);
begin
  inherited Create;
  FBitMap := TBitMap.Create;

  FName := AName;
  FPath := APath;
  FID := AID;
  Bytes := AData;
end;

destructor TLabelImage.Destroy;
begin
  FreeAndNil(FBitMap);
end;

function TLabelImage.GetBytes: TByteDynArray;
var
  Data: TMemoryStream;
begin
  SetLength(Result, 0);
  if FBitMap = nil then
    Exit;

  Data := TMemoryStream.Create;
  try
    FBitMap.SaveToStream(Data);
    SetLength(Result, Data.Size);
    if Length(Result) = 0 then
      Exit;

    Data.Seek(0, soBeginning);
    Data.Read(Result[0], Data.Size);
  finally
    Data.Free;
  end;
end;

function TLabelImage.GetFileName: string;
begin
  Result := FPath + FName;
end;

procedure TLabelImage.SetBytes(Value: TByteDynArray);
var
  Data: TMemoryStream;
begin
  if (Value = nil) or (Length(Value) = 0) then
    Exit;

  Data := TMemoryStream.Create;
  try
    Data.SetSize(Length(Value));
    Data.Seek(0, soBeginning);
    Data.Write(Value[0], Length(Value));
    Data.Seek(0, soBeginning);
    FBitMap.LoadFromStream(Data);
  finally
    Data.Free;
  end;
end;

// procedure TLabelImage.GetBmpFromString(const S: string);
// var
// Data: TMemoryStream;
// S1: string;
// begin
// Data := TMemoryStream.Create;
// try
// S1 := uCommonUtils.DecodeBase64(S);
// Data.SetSize(Length(S1));
// Data.Seek(0, soBeginning);
// Data.Write(S1[1], Length(S1));
// Data.Seek(0, soBeginning);
// FBitMap.LoadFromStream(Data);
// finally
// Data.Free;
// end;
// end;

{ TLabelImageList }

function TLabelImageList.GetImage(Index: Integer): TLabelImage;
begin
  if (Index >= 0) and (Index < Count) then
    Result := TLabelImage(Get(Index))
  else
    Result := nil;
end;

function TLabelImageList.AddImage(const ANameOrPath: string): Integer;
begin
  Result := inherited Add(TObject(TLabelImage.Create(ANameOrPath,
    IntToStr(Count + 1))));
end;

function TLabelImageList.FindImageByID(const AID: string): TLabelImage;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if CompareText(Images[I].ID, AID) = 0 then
    begin
      Result := Images[I];
      Exit;
    end;
end;

function TLabelImageList.AddImage(AName, APath: string;
  AData: TByteDynArray): Integer;
begin
  Result := AddImage(AName, APath, IntToStr(Count + 1), AData);
end;

function TLabelImageList.AddImage(AName, APath, AID: string;
  AData: TByteDynArray): Integer;
begin
  Result := inherited Add(TObject(TLabelImage.Create(AName, APath, AID,
    AData)));
end;

function TLabelImageList.GetFirstLineNumber(Index: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  if (Index < 0) or (Index >= Count) then
    Exit;

  Result := 1;
  for I := 0 to Index - 1 do
    Result := Result + Images[I].Bitmap.Height;
end;

function TLabelImageList.GetImage(const AName: string): TLabelImage;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if CompareText(Images[I].Name, AName) = 0 then
    begin
      Result := Images[I];
      Exit;
    end;
end;

procedure TLabelImageList.GetStrings(Strings: TStrings);
var
  I: Integer;
begin
  if Strings = nil then
    Exit;
  Strings.Clear;
  for I := 0 to Count - 1 do
    Strings.Add(Images[I].Name);
end;

function TLabelImageList.ImageIndexFromID(const AID: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  if Count = 0 then
    Exit;

  for I := 0 to Count - 1 do
    if AID = Images[I].ID then
    begin
      Result := I;
      Break
    end;
end;

procedure TLabelImageList.LoadFromXML(const XmlDoc: IXMLDocument;
  const NodeName: string);
var
  NodeList: IXMLNodeList;
  Root, Node: IXMLNode;
  I: Integer;
  sName, sPath, sID: string;
  Data: TByteDynArray;
begin
  Clear;
  if (XmlDoc = nil) or (XmlDoc.DocumentElement = nil) then
    Exit;

  NodeList := XmlDoc.ChildNodes;
  if NodeList = nil then
    Exit;

  Root := NodeList.FindNode(NodeName);
  if Root = nil then
  begin
    NodeList := XmlDoc.DocumentElement.ChildNodes;
    if NodeList <> nil then
      Root := NodeList.FindNode(NodeName);
  end;

  if Root = nil then
    Exit;

  NodeList := Root.ChildNodes;
  if NodeList.Count = 0 then
    Exit;

  for I := 0 to NodeList.Count - 1 do
  begin
    Node := NodeList[I];
    sName := VarToStrDef(Node.GetAttribute('Name'), '');
    sPath := VarToStrDef(Node.GetAttribute('Path'), '');
    sID := VarToStrDef(Node.GetAttribute('ID'), IntToStr(I));
    Data := TByteDynArray(DecodeBase64(Node.NodeValue));
    AddImage(sName, sPath, sID, Data);
  end;
end;

// procedure TLabelImageList.LoadFromXML(const XmlDoc: OleVariant);
// var
// oNodeList, oNode: OleVariant;
// I: Integer;
// sName, sPath, sID: string;
// Data: TByteDynArray;
// begin
// Clear;
// if VarIsClear(XmlDoc) then
// Exit;
//
// oNodeList := XmlDoc.documentElement.ChildNodes;
// if oNodeList.Length = 0 then
// Exit;
//
// for I := 0 to oNodeList.Length - 1 do
// begin
// oNode := oNodeList.Item[I];
// sName := VarToStrDef(oNode.GetAttribute('Name'), '');
// sPath := VarToStrDef(oNode.GetAttribute('Path'), '');
// sID := VarToStrDef(oNode.GetAttribute('ID'), IntToStr(I));
// Data := oNode.nodeTypedValue;
// AddImage(sName, sPath, sID, Data);
// end;
// end;

procedure TLabelImageList.Notify(Ptr: Pointer; Action: TListNotification);
var
  P: TLabelImage;
begin
  inherited;
  P := TLabelImage(Ptr);
  if (Action = lnDeleted) and (P <> nil) then
    FreeAndNil(P);
end;

procedure TLabelImageList.PutImage(Index: Integer; Item: TLabelImage);
begin
  inherited Put(Index, TObject(Item));
end;

procedure TLabelImageList.SaveToXML(var XmlDoc: IXMLDocument;
  const NodeName: string);
var
  I: Integer;
  Item, Root: IXMLNode;
  NodeList: IXMLNodeList;
  BinaryData: TByteDynArray;
  sID: string;
begin
  if XmlDoc = nil then
    Exit;

  if Length(NodeName) = 0 then
    Root := XmlDoc.DocumentElement
  else
  begin
    Root := nil;
    NodeList := XmlDoc.ChildNodes;
    if NodeList <> nil then
      Root := NodeList.FindNode(NodeName);

    if Root = nil then
    begin
      if XmlDoc.DocumentElement <> nil then
        Root := XmlDoc.DocumentElement.AddChild(NodeName)
      else
        Root := XmlDoc.AddChild(NodeName);
    end;
  end;

  Root.setAttribute('Count', IntToStr(Count));
  try
    for I := 0 to Count - 1 do
    begin
      Item := Root.AddChild('Image');
      Item.setAttribute('Name', Images[I].Name);
      Item.setAttribute('Path', Images[I].Path);
      if Length(Images[I].ID) = 0 then
        sID := IntToStr(I)
      else
        sID := Images[I].ID;
      Item.setAttribute('ID', sID);
      BinaryData := Images[I].Bytes;
      Item.NodeValue := EncodeBase64(@BinaryData[0], Length(BinaryData));
    end;
  finally
    SetLength(BinaryData, 0);
  end;
end;

end.
