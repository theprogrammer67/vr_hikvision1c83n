unit uXmlDialog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfmXmlDialog = class(TForm)
    Panel1: TPanel;
    mXml: TMemo;
    btnOK: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmXmlDialog: TfmXmlDialog;

implementation

{$R *.dfm}

end.
