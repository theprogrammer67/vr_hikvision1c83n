unit uXMLUtils;

interface

uses
  XMLDoc, XMLDom, XMLIntf;

procedure EscapeCharacters(var Text: string);
procedure UnEscapeCharacters(var Text: string);
function selectNode(xnRoot: IXmlNode; const nodePath: WideString): IXmlNode;
function selectNodes(xnRoot: IXmlNode; const nodePath: WideString)
  : IXMLNodeList;
function AddChildNode(xnParent: IXmlNode; const TagName: string;
  NodeValue: OleVariant): IXmlNode;
function NodeValueByAttribure(xmlRoot: IXmlNode;
  const Path, AttrName, AttrValue: string): OleVariant;

implementation

uses SysUtils, Variants;

procedure EscapeCharacters(var Text: string);
var
  I, Code: Integer;
begin
  I := 1;
  while I <= Length(Text) do
  begin
    Code := Ord(Text[I]);
    if ((Code > 31) or (Code in [9, 10, 13])) and (Code <> 35) then
    begin
      Inc(I);
      Continue;
    end;

    Delete(Text, I, 1);
    Insert(Char(35) + IntToHex(Code, 2), Text, I);
    Inc(I, 3);
  end;
end;

procedure UnEscapeCharacters(var Text: string);
var
  I, Code: Integer;
  Ch: Char;
begin
  I := 1;
  while I <= (Length(Text) - 2) do
  begin
    Code := Ord(Text[I]);
    if Code <> 35 then
    begin
      Inc(I);
      Continue;
    end;

    Ch := Char(StrToInt('$' + Copy(Text, I + 1, 2)));
    Delete(Text, I, 3);
    Insert(Ch, Text, I);
    Inc(I);
  end;
end;

function selectNode(xnRoot: IXmlNode; const nodePath: WideString): IXmlNode;
var
  intfSelect: IDomNodeSelect;
  dnResult: IDomNode;
  intfDocAccess: IXmlDocumentAccess;
  doc: TXmlDocument;
begin
  Result := nil;
  if not Assigned(xnRoot) or not Supports(xnRoot.DOMNode, IDomNodeSelect,
    intfSelect) then
    Exit;
  dnResult := intfSelect.selectNode(nodePath);
  if Assigned(dnResult) then
  begin
    if Supports(xnRoot.OwnerDocument, IXmlDocumentAccess, intfDocAccess) then
      doc := intfDocAccess.DocumentObject
    else
      doc := nil;
    Result := TXmlNode.Create(dnResult, nil, doc);
  end;
end;

function selectNodes(xnRoot: IXmlNode; const nodePath: WideString)
  : IXMLNodeList;
var
  intfSelect: IDomNodeSelect;
  intfAccess: IXmlNodeAccess;
  dnlResult: IDomNodeList;
  intfDocAccess: IXmlDocumentAccess;
  doc: TXmlDocument;
  I: Integer;
  dn: IDomNode;
begin
  Result := nil;
  if not Assigned(xnRoot) or not Supports(xnRoot, IXmlNodeAccess, intfAccess) or
    not Supports(xnRoot.DOMNode, IDomNodeSelect, intfSelect) then
    Exit;

  dnlResult := intfSelect.selectNodes(nodePath);
  if Assigned(dnlResult) then
  begin
    Result := TXmlNodeList.Create(intfAccess.GetNodeObject, '', nil);
    if Supports(xnRoot.OwnerDocument, IXmlDocumentAccess, intfDocAccess) then
      doc := intfDocAccess.DocumentObject
    else
      doc := nil;

    for I := 0 to dnlResult.Length - 1 do
    begin
      dn := dnlResult.item[I];
      Result.Add(TXmlNode.Create(dn, nil, doc));
    end;
  end;
end;

function AddChildNode(xnParent: IXmlNode; const TagName: string;
  NodeValue: OleVariant): IXmlNode;
begin
  Result := xnParent.AddChild(TagName);
  Result.NodeValue := NodeValue;
end;

function NodeValueByAttribure(xmlRoot: IXmlNode;
  const Path, AttrName, AttrValue: string): OleVariant;
var
  xmlNode: IXmlNode;
begin
  xmlNode := selectNode(xmlRoot, Path + '[@' + AttrName + '="' +
    AttrValue + '"]');
  if (xmlNode <> nil) and (not VarIsNull(xmlNode.NodeValue)) then
    Result := xmlNode.NodeValue
  else
    Result := '';
end;

end.
