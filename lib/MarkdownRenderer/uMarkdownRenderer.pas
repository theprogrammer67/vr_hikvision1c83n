// В ресурсах приложения должен быть zip-архив c именем LSourceName,
// Содержащий файл markdown-документа с расширением ".md",
// Файл стилей с расширением *.css (не обязательно)
// И файлы изображений, содержащихся в документе (если необходимо)

unit uMarkdownRenderer;

interface

uses Winapi.Windows, System.SysUtils, System.Zip, System.IOUtils,
  System.Classes, MarkdownProcessor
{$IFNDEF CONSOLE}
    , ufmDocView
{$ELSE}
    , Common.WinProcessUtils
{$ENDIF}
    ;

type
  TMarkdownRenderer = class
  const
    ZIP_FILENAME = 'md.zip';
    HTML_FILENAME = 'md.html';
    PDF_CONVERTER = 'wkhtmltopdf.exe';
  private
    FSourceName: string;
    FTempDirectory: string;
  private
    function GetFilesFromResource: string;
    procedure UnZipFiles(const AFileName: string);
    function GetFirstFileName(const AExtension: string): string;
    function LoadMDFromFile(const AFileName: string): string;
    function SaveHtml(const AHTMLData, ACSSFile: string;
      const ADestination: string = ''): string;
    function ConvertMarkdownToHtml(const AMDData: string): string;
  public
    constructor Create; overload;
    constructor Create(const ASourceName: string); overload;
    destructor Destroy; override;
  public
    procedure Render(const ACaption: string); overload;
    procedure ConvertToHtml(const ADestination, ACss: string); overload;
    function SourceExist: Boolean; overload;
  public
    class procedure Render(const ASourceName, ACaption: string); overload;
    class procedure ConvertToHtml(const ASource, ADestination,
      ACss: string); overload;
{$IFDEF CONSOLE}
    class procedure ConvertToPdf(const ASource, ADestination,
      ACss: string); overload;
{$ENDIF}
    class function SourceExist(const ASourceName: string): Boolean; overload;
  public
    property SourceName: string read FSourceName write FSourceName;
  end;

implementation

uses MarkdownDaringFireball;

resourcestring
  RsErrConvertorNotFound = 'wkhtmltopdf.exe not found';

  { TMarkdownRenderer }

constructor TMarkdownRenderer.Create;
var
  LGuid: TGUID;
begin
  FSourceName := '';
  CreateGUID(LGuid);
  FTempDirectory := IncludeTrailingPathDelimiter(TPath.GetTempPath) +
    LGuid.ToString;
  TDirectory.CreateDirectory(FTempDirectory);
end;

function TMarkdownRenderer.ConvertMarkdownToHtml(const AMDData: string): string;
var
  LMDProcessor: TMarkdownProcessor;
begin
  try
    LMDProcessor := TMarkdownProcessor.createDialect(mdDaringFireball);
    TMarkdownDaringFireball(LMDProcessor).config.ForceExtendedProfile := True;
    LMDProcessor.UnSafe := True;
    Result := LMDProcessor.process(AMDData);
  finally
    FreeAndNil(LMDProcessor);
  end;
end;

class procedure TMarkdownRenderer.ConvertToHtml(const ASource, ADestination,
  ACss: string);
var
  LRenderer: TMarkdownRenderer;
begin
  if not FileExists(ASource) then
    raise Exception.Create('File not found: ' + ASource);
  if (ACss <> '') and (not FileExists(ACss)) then
    raise Exception.Create('File not found: ' + ACss);

  try
    LRenderer := TMarkdownRenderer.Create(ASource);
    LRenderer.ConvertToHtml(ADestination, ACss);
  finally
    FreeAndNil(LRenderer);
  end;
end;

{$IFDEF CONSOLE}
class procedure TMarkdownRenderer.ConvertToPdf(const ASource, ADestination,
  ACss: string);
var
  LHtmlFile, LPdfConvertorPath: string;
begin
  LPdfConvertorPath := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)))
    + PDF_CONVERTER;
  if not FileExists(LPdfConvertorPath) then
    raise Exception.Create(RsErrConvertorNotFound);

  LHtmlFile := IncludeTrailingPathDelimiter(ExtractFileDir(ASource)) +
    HTML_FILENAME;
  try
    ConvertToHtml(ASource, LHtmlFile, ACss);
    ExecConsoleApp(LPdfConvertorPath, [LHtmlFile, ADestination]);
  finally
    try
      TFile.Delete(LHtmlFile);
    except
    end;
  end;
end;
{$ENDIF}


procedure TMarkdownRenderer.ConvertToHtml(const ADestination, ACss: string);
var
  LMDData: string;
begin
  LMDData := LoadMDFromFile(FSourceName);
  SaveHtml(ConvertMarkdownToHtml(LMDData), ACss, ADestination);
end;

constructor TMarkdownRenderer.Create(const ASourceName: string);
begin
  Create;
  FSourceName := ASourceName;
end;

destructor TMarkdownRenderer.Destroy;
begin
  TDirectory.Delete(FTempDirectory, True);
end;

function TMarkdownRenderer.GetFilesFromResource: string;
var
  LResource: TResourceStream;
begin
  LResource := TResourceStream.Create(hInstance, SourceName, RT_RCDATA);
  try
    Result := IncludeTrailingPathDelimiter(FTempDirectory) + ZIP_FILENAME;
    LResource.SaveToFile(Result);
  finally
    LResource.Free;
  end;
end;

function TMarkdownRenderer.GetFirstFileName(const AExtension: string): string;
var
  LSearchRec: TSearchRec;
  LSearchMask: string;
begin
  Result := '';
  LSearchMask := '*.' + AExtension;
  try
    if FindFirst(TPath.Combine(FTempDirectory, LSearchMask), faAnyFile,
      LSearchRec) = 0 then
      Result := LSearchRec.Name;
  finally
    FindClose(LSearchRec);
  end;
end;

function TMarkdownRenderer.LoadMDFromFile(const AFileName: string): string;
var
  Stream: TStream;
  Size: Integer;
  Buffer: TBytes;
  Encoding: TEncoding;
  LFileName: string;
begin
  Encoding := nil;

  if TPath.IsPathRooted(AFileName) then
    LFileName := AFileName
  else
    LFileName := IncludeTrailingPathDelimiter(FTempDirectory) + AFileName;

  Stream := TFileStream.Create(LFileName, fmOpenRead or fmShareDenyWrite);
  try
    Size := Stream.Size - Stream.Position;
    SetLength(Buffer, Size);
    Stream.Read(Buffer, 0, Size);
    Size := TEncoding.GetBufferEncoding(Buffer, Encoding, TEncoding.UTF8);
    Result := Encoding.GetString(Buffer, Size, Length(Buffer) - Size);
  finally
    Stream.Free;
  end;
end;

class procedure TMarkdownRenderer.Render(const ASourceName, ACaption: string);
var
  LRenderer: TMarkdownRenderer;
begin
  if not SourceExist(ASourceName) then
    raise Exception.Create('File not found: ' + ASourceName);

  try
    LRenderer := TMarkdownRenderer.Create(ASourceName);
    LRenderer.Render(ACaption);
  finally
    FreeAndNil(LRenderer);
  end;
end;

procedure TMarkdownRenderer.Render(const ACaption: string);
var
  LMDData, LZipFile, LHtmlFile, LMDFile: string;
begin
  if not SourceExist then
    raise Exception.Create('File not found: ' + SourceName);

  LZipFile := GetFilesFromResource;
  UnZipFiles(LZipFile);
  LMDFile := GetFirstFileName('md');
  if LMDFile = '' then
    raise Exception.Create('Mardown file not found');
  LMDData := LoadMDFromFile(LMDFile);
  LHtmlFile := SaveHtml(ConvertMarkdownToHtml(LMDData),
    GetFirstFileName('css'));

{$IFNDEF CONSOLE}
  with TfrmDocView.Create(LHtmlFile, ACaption) do
    try
      ShowModal;
    finally
      Free;
    end;
{$ENDIF}
end;

function TMarkdownRenderer.SaveHtml(const AHTMLData, ACSSFile: string;
  const ADestination: string): string;

  function MakeHtmlPage: string;
  begin
    if ACSSFile = '' then
      Exit(AHTMLData);

    Result := '<head>' + sLineBreak + '<link href="' + ACSSFile +
      '" rel="stylesheet">' + sLineBreak + '</head>' + sLineBreak + '<body>' +
      sLineBreak + AHTMLData + sLineBreak + '</body>';
    Result := '<!DOCTYPE html>' + sLineBreak + '<html>' + sLineBreak + Result +
      sLineBreak + '</html>';
  end;

var
  Stream: TStream;
  Buffer, Preamble: TBytes;
  Encoding: TEncoding;
begin
  if ADestination = '' then
    Result := IncludeTrailingPathDelimiter(FTempDirectory) + HTML_FILENAME
  else
    Result := ADestination;

  Stream := TFileStream.Create(Result, fmCreate);
  try
    Encoding := TEncoding.UTF8;
    Buffer := Encoding.GetBytes(MakeHtmlPage);
    Preamble := Encoding.GetPreamble;
    if Length(Preamble) > 0 then
      Stream.WriteBuffer(Preamble, Length(Preamble));
    Stream.WriteBuffer(Buffer, Length(Buffer));
  finally
    Stream.Free;
  end;
end;

class function TMarkdownRenderer.SourceExist(const ASourceName: string)
  : Boolean;
begin
  if ASourceName.IsEmpty then
    Exit(False);
  Result := FindResource(hInstance, PChar(ASourceName), RT_RCDATA) <> 0;
end;

function TMarkdownRenderer.SourceExist: Boolean;
begin
  Result := SourceExist(SourceName);
end;

procedure TMarkdownRenderer.UnZipFiles(const AFileName: string);
begin
  TZipFile.ExtractZipFile(AFileName, FTempDirectory);
end;

end.
