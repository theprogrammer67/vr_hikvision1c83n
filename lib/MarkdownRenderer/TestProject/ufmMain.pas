unit ufmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uMarkdownRenderer, Vcl.StdCtrls;

type
  TfrmMain = class(TForm)
    btnShowMarkdown: TButton;
    procedure btnShowMarkdownClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnShowMarkdownClick(Sender: TObject);
var
  LSourceName, LCaption: string;
begin
  LSourceName := 'md';
  LCaption := 'Markdown документ';

  // В ресурсах приложения должен быть zip-архив c именем LSourceName,
  // Содержащий файл markdown-документа с расширением ".md"
  // И файлы изображений, содержащихся в документе (если необходимо)
  if TMarkdownRenderer.SourceExist(LSourceName) then
    TMarkdownRenderer.Render(LSourceName, LCaption);
end;

end.
