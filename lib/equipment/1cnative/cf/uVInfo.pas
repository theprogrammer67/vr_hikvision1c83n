unit uVInfo;

interface

uses
  Winapi.Windows, System.SysUtils;

type
  { TVersionInfo }

  TVersionInfo = record
    MajorVersion: WORD;
    MinorVersion: WORD;
    ProductRelease: WORD;
    ProductBuild: WORD;
  end;

function GetFileVerStr(const FileName: string = ''): string;
function GetFileVer(const FileName: string = ''): TVersionInfo;

implementation

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
  if Length(FileName) = 0 then FName := GetModuleFileNameStr
  else FName := FileName;

  VerInfoSize := GetFileVersionInfoSize(PChar(FName), Dummy);
  if VerInfoSize = 0 then Exit;
  GetMem(VerInfo, VerInfoSize);
  try
    Winapi.Windows.GetFileVersionInfo(PChar(FName), 0, VerInfoSize, VerInfo);
    if VerInfo = nil then Exit;
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

end.

