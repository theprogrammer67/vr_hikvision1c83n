program Test;

{$R *.dres}

uses
  Vcl.Forms,
  ufmMain in 'ufmMain.pas' {frmMain},
  uMarkdownRenderer in '..\uMarkdownRenderer.pas',
  MarkdownDaringFireball in '..\lib\delphi-markdown\source\MarkdownDaringFireball.pas',
  MarkdownProcessor in '..\lib\delphi-markdown\source\MarkdownProcessor.pas',
  MarkdownCommonMark in '..\lib\delphi-markdown\source\MarkdownCommonMark.pas',
  ufmDocView in '..\ufmDocView.pas' {frmDocView},
  MarkdownHTMLEntities in '..\lib\delphi-markdown\source\MarkdownHTMLEntities.pas',
  Common.WinProcessUtils in '..\lib\equipment\common\cf\Common.WinProcessUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
