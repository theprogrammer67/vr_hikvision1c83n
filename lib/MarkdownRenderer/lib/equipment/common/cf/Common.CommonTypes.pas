unit Common.CommonTypes;

interface

uses SysUtils, Classes, XMLIntf, uXMLUtils;

type
  TXmlSerializeCollectionItem = class(TCollectionItem)
  protected
    FItemTag: string;
  public
    constructor Create(const AItemTag: string); reintroduce;

    function XMLSerialize(Root: IXMLNode): IXMLNode; Virtual;
    procedure XMLDeserialize(Root: IXMLNode); Virtual;
  end;

  TXmlSerializeCollection = class(TCollection)
  protected
    FColletionTag: string;
    FItemTag: string;
  public
    constructor Create(const AColletionTag, AItemTag: string; ItemClass: TCollectionItemClass); overload;
    constructor Create(ItemClass: TCollectionItemClass); overload;

    function Add: TXmlSerializeCollectionItem;

    function XMLSerialize(Root: IXMLNode): IXMLNode; overload; Virtual;
    function XMLDeserialize(Root: IXMLNode): IXMLNode; overload; Virtual;
    function XMLSerialize(Doc: IXMLDocument): IXMLDocument; overload; Virtual;
    function XMLDeserialize(Doc: IXMLDocument): IXMLDocument; overload; Virtual;
  end;

implementation

{ TXmlSerializeCollection }

function TXmlSerializeCollection.Add: TXmlSerializeCollectionItem;
begin
  Result := TXmlSerializeCollectionItem(inherited Add);
  Result.FItemTag := FItemTag;
end;

constructor TXmlSerializeCollection.Create(const AColletionTag, AItemTag: string;
  ItemClass: TCollectionItemClass);
begin
  inherited Create(ItemClass);
  FColletionTag := AColletionTag;
  FItemTag := AItemTag;
end;

constructor TXmlSerializeCollection.Create(ItemClass: TCollectionItemClass);
begin
  inherited Create(ItemClass);
end;

function TXmlSerializeCollection.XMLDeserialize(Root: IXMLNode): IXMLNode;
var
  xmlNodes: IXMLNodeList;
  I: Integer;
begin
  Clear;
  Result := selectNode(Root, '//' + FColletionTag);
  if Result = nil then
    Exit;

  xmlNodes := selectNodes(Result, './' + FItemTag);
  for I := 0 to xmlNodes.Count - 1 do
    Add.XMLDeserialize(xmlNodes[I]);
end;

function TXmlSerializeCollection.XMLSerialize(Root: IXMLNode): IXMLNode;
var
  I: Integer;
begin
  Result := Root.AddChild(FColletionTag);
  for I := 0 to Count-1 do
    TXmlSerializeCollectionItem(Items[I]).XMLSerialize(Result);
end;

function TXmlSerializeCollection.XMLDeserialize(
  Doc: IXMLDocument): IXMLDocument;
begin

end;

function TXmlSerializeCollection.XMLSerialize(Doc: IXMLDocument): IXMLDocument;
begin

end;

{ TXmlSerializeCollectionItem }

constructor TXmlSerializeCollectionItem.Create(const AItemTag: string);
begin
  inherited Create(nil);

  FItemTag := AItemTag;
end;

procedure TXmlSerializeCollectionItem.XMLDeserialize(Root: IXMLNode);
begin

end;

function TXmlSerializeCollectionItem.XMLSerialize(Root: IXMLNode): IXMLNode;
begin
  Result := Root.AddChild(FItemTag);
end;

end.
