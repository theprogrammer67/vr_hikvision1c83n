unit uVInfo;

interface

uses
  // VCL
  Windows, SysUtils;

type
  { TVersionInfo }

  TVersionInfo = record
    // MajorVersion: WORD;
    // MinorVersion: WORD;
    // ProductRelease: WORD;
    // ProductBuild: WORD;
    case Integer of
      0:
        (ProductBuild, ProductRelease, MinorVersion, MajorVersion : Word);
      1:
        (All: array [1 .. 4] of Word);
      2:
        (LS, MS: LongInt);
      3:
        (Vr: Int64);
  end;

function GetFileVerStr(const FileName: string = ''): string;
function GetFileVer(const FileName: string = ''): TVersionInfo;
function StrToFileVer(const strVersion: string): TVersionInfo;
function CompareFileVer(const Ver1, Ver2: TVersionInfo): Integer;

implementation

uses StrUtils, Math;

function GetModuleFileNameStr: string;
var
  Buffer: array [0 .. MAX_PATH] of Char;
begin
  FillChar(Buffer, MAX_PATH, #0);
  GetModuleFileName(hInstance, Buffer, MAX_PATH);
  Result := Buffer;
end;


function GetFileVer(const FileName: string = ''): TVersionInfo;
var
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
  FName: string;
begin
  Result.MajorVersion := 0;
  Result.MinorVersion := 0;
  Result.ProductRelease := 0;
  Result.ProductBuild := 0;
  if Length(FileName) = 0 then
    FName := GetModuleFileNameStr
  else
    FName := FileName;

  VerInfoSize := GetFileVersionInfoSize(PChar(FName), Dummy);
  if VerInfoSize = 0 then
    Exit;
  GetMem(VerInfo, VerInfoSize);
  try
    Windows.GetFileVersionInfo(PChar(FName), 0, VerInfoSize, VerInfo);
    if VerInfo = nil then
      Exit;
    VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
    with VerValue^ do
    begin
      Result.MajorVersion := dwFileVersionMS shr 16;
      Result.MinorVersion := dwFileVersionMS and $FFFF;
      Result.ProductRelease := dwFileVersionLS shr 16;
      Result.ProductBuild := dwFileVersionLS and $FFFF;
    end;
  finally
    FreeMem(VerInfo, VerInfoSize);
  end;
end;

function GetFileVerStr(const FileName: string = ''): string;
var
  vi: TVersionInfo;
begin
  vi := GetFileVer(FileName);
  Result := Format('%d.%d.%d.%d', [vi.MajorVersion, vi.MinorVersion,
    vi.ProductRelease, vi.ProductBuild]);
end;

function StrToFileVer(const strVersion: string): TVersionInfo;
var
  POld, PNew: Integer;
begin
  POld := Pos('.', strVersion);
  if POld = 0 then
    Exit;
  Result.MajorVersion := StrToIntDef(LeftStr(strVersion, POld - 1), 0);

  PNew := PosEx('.', strVersion, POld + 1);
  if PNew = 0 then
    Exit;
  Result.MinorVersion := StrToIntDef(MidStr(strVersion, POld + 1,
    PNew - POld - 1), 0);
  POld := PNew;

  PNew := PosEx('.', strVersion, POld + 1);
  if PNew = 0 then
    Exit;
  Result.ProductRelease := StrToIntDef(MidStr(strVersion, POld + 1,
    PNew - POld - 1), 0);
  POld := PNew;

  Result.ProductBuild :=
    StrToIntDef(RightStr(strVersion, Length(strVersion) - POld), 0);
end;

function CompareFileVer(const Ver1, Ver2: TVersionInfo): Integer;
begin
  Result := CompareValue(Ver1.Vr, Ver2.Vr);
end;

end.
