library vr_hikvision1c83n;

{$R *.dres}

uses
  System.SysUtils,
  System.Classes,
  uCommonDriver in 'lib\equipment\1cnative\cf\cel2\uCommonDriver.pas',
  uCustomDriver in 'lib\equipment\1cnative\cf\uCustomDriver.pas',
  uVInfo in 'lib\equipment\1cnative\cf\uVInfo.pas',
  v8napi in 'lib\equipment\1cnative\cf\v8napi.pas',
  ufmDocView in 'lib\MarkdownRenderer\ufmDocView.pas' {frmDocView},
  uMarkdownRenderer in 'lib\MarkdownRenderer\uMarkdownRenderer.pas',
  MarkdownProcessor in 'lib\MarkdownRenderer\lib\delphi-markdown\source\MarkdownProcessor.pas',
  MarkdownCommonMark in 'lib\MarkdownRenderer\lib\delphi-markdown\source\MarkdownCommonMark.pas',
  MarkdownDaringFireball in 'lib\MarkdownRenderer\lib\delphi-markdown\source\MarkdownDaringFireball.pas',
  MarkdownHTMLEntities in 'lib\MarkdownRenderer\lib\delphi-markdown\source\MarkdownHTMLEntities.pas',
  uDriver in 'uDriver.pas',
  Common.BaseSecurity in 'lib\equipment\common\cf\Common.BaseSecurity.pas',
  Common.Log in 'lib\equipment\common\cf\Common.Log.pas',
  ufmLog in 'lib\equipment\common\cf\ufmLog.pas' {frmLog},
  uVideoRecorderDriver in 'lib\equipment\1cnative\cf\cel2\uVideoRecorderDriver.pas',
  uCHCNetSDK in 'lib\equipment\common\vr_hikvision\common\uCHCNetSDK.pas',
  uHikvisionErrors in 'lib\equipment\common\vr_hikvision\common\uHikvisionErrors.pas',
  uVideoPanel in 'lib\equipment\common\vr_hikvision\common\uVideoPanel.pas',
  uVideoWindow in 'lib\equipment\common\vr_hikvision\common\uVideoWindow.pas',
  uVideoDevice in 'lib\equipment\common\vr_hikvision\common\uVideoDevice.pas',
  uCommonUtils in 'lib\equipment\common\cf\uCommonUtils.pas',
  uAlphaWindow in 'lib\equipment\common\vr_hikvision\common\uAlphaWindow.pas',
  uDriverVideoWindow in 'uDriverVideoWindow.pas',
  uDriverCommon in 'uDriverCommon.pas',
  uCommonTypes in 'lib\equipment\common\vr_hikvision\common\uCommonTypes.pas',
  uEquipmentErrors in 'lib\equipment\common\cf\uEquipmentErrors.pas';

{$R *.res}

begin
{$IFDEF DEBUG}
  // Для отображения утечек памяти, если они есть
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}

end.
