unit ufmDocView;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, SHDocVw;

type
  TfrmDocView = class(TForm)
    wbBrowser: TWebBrowser;
  public
    constructor Create(const AHtmlFilePath, ACaption: string); reintroduce;
  end;

implementation

{$R *.dfm}
{ TfrmDocView }

constructor TfrmDocView.Create(const AHtmlFilePath, ACaption: string);
begin
  inherited Create(nil);

  Caption := ACaption;
  wbBrowser.Navigate(AHtmlFilePath);
end;


end.
