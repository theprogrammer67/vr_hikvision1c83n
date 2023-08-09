unit uSimpleCrypt;

interface

const
  StartKey: Integer = 327; // Start default key
  MultKey: Integer = 55477; // Mult default key
  AddKey: Integer = 12099; // Add default key

function SimpleEncrypt(const InString: AnsiString; Hex: Boolean = False): AnsiString; overload;
function SimpleDecrypt(const InString: AnsiString; Hex: Boolean = False): AnsiString; overload;
{$IF CompilerVersion > 19.0}
function SimpleEncrypt(const InString: string; Hex: Boolean = False): string; overload;
function SimpleDecrypt(const InString: string; Hex: Boolean = False): string; overload;
{$IFEND}

implementation

uses Classes;

function BinStrToHex(const Value: AnsiString): AnsiString;
const
  Convert: array [0 .. 15] of AnsiChar = AnsiString('0123456789ABCDEF');
var
  ValSize, I: Integer;
  Text: PAnsiChar;
begin
  ValSize := Length(Value);

  SetLength(Result, ValSize * 2);
  Text := PAnsiChar(@Result[1]);
  for I := 1 to ValSize do
  begin
    Text[0] := Convert[Byte(Value[I]) shr 4];
    Text[1] := Convert[Byte(Value[I]) and $F];
    Inc(Text, 2);
  end;
end;

function HexToBinStr(const Value: AnsiString): AnsiString;
var
  ResSize: Integer;
begin
  ResSize := Length(Value) div 2;

  SetLength(Result, ResSize);
  HexToBin(PAnsiChar(@Value[1]), PAnsiChar(@Result[1]), ResSize);
end;

function SimpleEncrypt(const InString: AnsiString; Hex: Boolean): AnsiString;
var
  I: Integer;
  _StartKey: Integer;
begin
  Result := '';
  _StartKey := StartKey;

  for I := 1 to Length(InString) do
  begin
    Result := Result + AnsiChar(Byte(InString[I]) xor (_StartKey shr 8));
    _StartKey := (Byte(Result[I]) + _StartKey) * MultKey + AddKey;
  end;

  if Hex then
    Result := BinStrToHex(Result);
end;

{$R-}
{$Q-}

function SimpleDecrypt(const InString: AnsiString; Hex: Boolean): AnsiString;
var
  I: Integer;
  _StartKey: Integer;
  _InString: AnsiString;
begin
  if Hex then
    _InString := HexToBinStr(InString)
  else
    _InString := InString;

  Result := '';
  _StartKey := StartKey;

  for I := 1 to Length(_InString) do
  begin
    Result := Result + AnsiChar(Byte(_InString[I]) xor (_StartKey shr 8));
    _StartKey := (Byte(_InString[I]) + _StartKey) * MultKey + AddKey;
  end;
end;
{$IF CompilerVersion > 19.0}
function SimpleEncrypt(const InString: string; Hex: Boolean = False): string;
begin
  Result := string(SimpleEncrypt(AnsiString(InString), Hex));
end;

function SimpleDecrypt(const InString: string; Hex: Boolean = False): string;
begin
  Result := string(SimpleDecrypt(AnsiString(InString), Hex));
end;
{$IFEND}

{$R+}
{$Q+}

end.
