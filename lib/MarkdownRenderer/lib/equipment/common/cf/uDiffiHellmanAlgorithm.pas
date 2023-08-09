unit uDiffiHellmanAlgorithm;

interface

uses Math, uBigInt;

function CalcOpenKey(A : TFGInt) : TFGInt;
function CalcSecretKey(A, OpenKey : TFGInt) : TFGInt;
function CreateRandomBigInt( const aCount: integer;
                             const aRandomize : boolean = false ): TFGInt;

var
  Diffi_Helman_P: string = '56792365273852378658672037645603895462304560235602895670384670389423498760234986572692345089560349856872398756237856348756702383';
  Diffi_Helman_G: string = '7';

implementation

function CalcSecretKey(A, OpenKey : TFGInt) : TFGInt;
var
  P : TFGInt;
begin
  P.fromString(Diffi_Helman_P);
  FGIntModExp(OpenKey, A, P, Result);
end;

function CalcOpenKey(A : TFGInt) : TFGInt;
var
  P,G : TFGInt;
begin
  P.fromString(Diffi_Helman_P);
  G.fromString(Diffi_Helman_G);
  FGIntModExp(G, A, P, Result);
end;

function CreateRandomBigInt( const aCount: integer;
                             const aRandomize : boolean = false ): TFGInt;
var
  _s : string;
  i  : integer;
begin
  if aRandomize then
    Randomize;

  SetLength( _s , aCount );
  for i := 1 to aCount do
    _s[i] := Char( Ord('0') + Random( 9 ) );

  Result.fromString( _s );
end;

end.
