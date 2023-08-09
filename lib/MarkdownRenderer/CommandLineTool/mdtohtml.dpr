program mdtohtml;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  System.IOUtils,
  MarkdownCommonMark in '..\lib\delphi-markdown\source\MarkdownCommonMark.pas',
  MarkdownDaringFireball
    in '..\lib\delphi-markdown\source\MarkdownDaringFireball.pas',
  MarkdownHTMLEntities
    in '..\lib\delphi-markdown\source\MarkdownHTMLEntities.pas',
  MarkdownProcessor in '..\lib\delphi-markdown\source\MarkdownProcessor.pas',
  uMarkdownRenderer in '..\uMarkdownRenderer.pas',
  Common.WinProcessUtils
    in '..\lib\equipment\common\cf\Common.WinProcessUtils.pas';

type
  TConsoleWriter = class
  private
    class var FStdOutHandle: TextFile;
    class var FStdErrHandle: TextFile;
    class procedure InitHandle(var AFileHandle: TextFile; AHandle: Cardinal);
    class procedure Write(const AHandle; const AString: string);
    class procedure FlushHandle(const AHandle);
  public
    class procedure Flush;
    class procedure Init;

    class procedure Info(const AInfo: string);
    class procedure Error(const AError: string);
  end;

resourcestring
  RsHelp = '  mdtohtml.exe source destination [CSS file]';

  { TConsoleWriter }

class procedure TConsoleWriter.Error(const AError: string);
begin
  Write(FStdErrHandle, 'ERROR: ' + StringReplace(AError, '/n', sLineBreak,
    [rfReplaceAll]));
end;

class procedure TConsoleWriter.Flush;
begin
  FlushHandle(FStdOutHandle);
  FlushHandle(FStdErrHandle);
end;

class procedure TConsoleWriter.FlushHandle(const AHandle);
var
  LTextRec: TTextRec;
begin
  LTextRec := TTextRec(AHandle);
  System.Flush(Text(LTextRec));
end;

class procedure TConsoleWriter.Info(const AInfo: string);
begin
  Write(FStdOutHandle, AInfo);
end;

class procedure TConsoleWriter.Init;
begin
  InitHandle(FStdOutHandle, STD_OUTPUT_HANDLE);
  InitHandle(FStdErrHandle, STD_ERROR_HANDLE);
end;

class procedure TConsoleWriter.InitHandle(var AFileHandle: TextFile;
  AHandle: Cardinal);
begin
  Assign(AFileHandle, '');
  Rewrite(AFileHandle);
  TTextRec(AFileHandle).Handle := GetStdHandle(STD_OUTPUT_HANDLE);
end;

class procedure TConsoleWriter.Write(const AHandle; const AString: string);
begin
  Writeln(TextFile(AHandle), AString);
end;

procedure PrintHelp;
begin
  TConsoleWriter.Info('HELP:');
  TConsoleWriter.Info(RsHelp);
  TConsoleWriter.Info('');
end;

function GetAbsPath(const APath: string): string;
begin
  if APath = '' then
    Exit('');

  if not TPath.IsPathRooted(APath) then
    Result := TPath.GetFullPath(APath)
  else
    Result := APath;
end;

var
  LSource, LDestination, LCss: string;

begin
  ExitCode := 0;
  TConsoleWriter.Init;
  try
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    LSource := GetAbsPath(ParamStr(1));
    LDestination := GetAbsPath(ParamStr(2));
    LCss := GetAbsPath(ParamStr(3));

    if (LSource = '') or (LDestination = '') or SameText(LSource, 'help') or
      (FindCmdLineSwitch('?')) then
    begin
      ExitCode := 2;
      PrintHelp;
      Exit;
    end;

    if SameText(TPath.GetExtension(LDestination), '.pdf') then
      TMarkdownRenderer.ConvertToPdf(LSource, LDestination, LCss)
    else
      TMarkdownRenderer.ConvertToHtml(LSource, LDestination, LCss);

    TConsoleWriter.Info('File is successfully converted');
  except
    ExitCode := 1;
    ErrorAddr := nil;
    PrintHelp;
    TConsoleWriter.Error(Exception(ExceptObject).Message);
  end;
  TConsoleWriter.Flush;

end.
