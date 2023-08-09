unit OXmlSerializeCollection;

interface

uses System.SysUtils, System.Classes, OXmlPDOM;

type
  TXmlSerializeCollectionItem = class(TCollectionItem)
  protected
    FItemTag: string;
  public
    constructor Create(const AItemTag: string); reintroduce;

    function XMLSerialize(Root: PXMLNode): PXMLNode; Virtual;
    procedure XMLDeserialize(Root: PXMLNode); Virtual;
  end;

  TXmlSerializeCollection = class(TCollection)
  protected
    FColletionTag: string;
    FItemTag: string;
  public
    constructor Create(const AColletionTag, AItemTag: string;
      ItemClass: TCollectionItemClass); overload;
    constructor Create(ItemClass: TCollectionItemClass); overload;

    function Add: TXmlSerializeCollectionItem;

    function XMLSerialize(Root: PXMLNode): PXMLNode; Virtual;
    function XMLDeserialize(Root: PXMLNode): PXMLNode; Virtual;
  end;

implementation

{ TXmlSerializeCollection }

function TXmlSerializeCollection.Add: TXmlSerializeCollectionItem;
begin
  Result := TXmlSerializeCollectionItem(inherited Add);
  Result.FItemTag := FItemTag;
end;

constructor TXmlSerializeCollection.Create(const AColletionTag,
  AItemTag: string; ItemClass: TCollectionItemClass);
begin
  inherited Create(ItemClass);
  FColletionTag := AColletionTag;
  FItemTag := AItemTag;
end;

constructor TXmlSerializeCollection.Create(ItemClass: TCollectionItemClass);
begin
  inherited Create(ItemClass);
end;

function TXmlSerializeCollection.XMLDeserialize(Root: PXMLNode): PXMLNode;
var
  xmlNodes: IXMLNodeList;
  I: Integer;
begin
  Clear;
  Result := Root.selectNode('//' + FColletionTag);
  if Result = nil then
    Exit;

  xmlNodes := Result.selectNodes('./' + FItemTag);
  for I := 0 to xmlNodes.Count - 1 do
    Add.XMLDeserialize(xmlNodes[I]);
end;

function TXmlSerializeCollection.XMLSerialize(Root: PXMLNode): PXMLNode;
var
  I: Integer;
begin
  Result := Root.AddChild(FColletionTag);
  for I := 0 to Count - 1 do
    TXmlSerializeCollectionItem(Items[I]).XMLSerialize(Result);
end;

{ TXmlSerializeCollectionItem }

constructor TXmlSerializeCollectionItem.Create(const AItemTag: string);
begin
  inherited Create(nil);

  FItemTag := AItemTag;
end;

procedure TXmlSerializeCollectionItem.XMLDeserialize(Root: PXMLNode);
begin

end;

function TXmlSerializeCollectionItem.XMLSerialize(Root: PXMLNode): PXMLNode;
begin
  Result := Root.AddChild(FItemTag);
end;

end.
