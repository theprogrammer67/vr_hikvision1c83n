unit ufmLog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.ToolWin, Vcl.ComCtrls, Common.Log, Vcl.Buttons;

type
  TfrmLog = class(TForm)
    ctrlbrControl: TControlBar;
    mmoLog: TMemo;
    tlb1: TToolBar;
    cbbLogFiles: TComboBox;
    tmrCheckFile: TTimer;
    btnOpenDir: TSpeedButton;
    procedure btnOpenDirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbbLogFilesChange(Sender: TObject);
    procedure cbbLogFilesDropDown(Sender: TObject);
    procedure tmrCheckFileTimer(Sender: TObject);
  private
    FLogDirectory: string;
    FLogLastWriteTime: TDateTime;
  private
    procedure UpdateFileList;
    procedure UpdateText;
  public
    { Public declarations }
  end;

implementation

uses System.IOUtils, Winapi.ShellAPI;

function GetDataDirectory: string;
begin
  Result := TLog.GetAbsolutePath(True);
end;

{$R *.dfm}

procedure TfrmLog.btnOpenDirClick(Sender: TObject);
begin
  ShellExecute(Handle, 'explore', PChar(GetDataDirectory), '', '', SW_SHOWNORMAL);
end;

procedure TfrmLog.FormCreate(Sender: TObject);
begin
  FLogDirectory := GetDataDirectory;

  UpdateFileList;
  if cbbLogFiles.Items.Count > 0 then
    cbbLogFiles.ItemIndex := cbbLogFiles.Items.Count - 1;
  UpdateText;
end;

procedure TfrmLog.UpdateFileList;
var
  LSearchRec: TSearchRec;
  LExt, LDir: string;
begin
  LDir := FLogDirectory;

  cbbLogFiles.Clear;
  if FindFirst(LDir + '*.*', faAnyFile, LSearchRec) = 0 then
    repeat
      LExt := LowerCase(ExtractFileExt(LSearchRec.Name));
      if (LExt = '.log') then
        cbbLogFiles.Items.Add(LSearchRec.Name);
    until FindNext(LSearchRec) <> 0;
  FindClose(LSearchRec);
end;

procedure TfrmLog.UpdateText;
begin
  if cbbLogFiles.Text <> '' then
  begin
    FLogLastWriteTime := TFile.GetLastWriteTime
      (FLogDirectory + cbbLogFiles.Text);
    mmoLog.Lines.BeginUpdate;
    try
      mmoLog.Lines.LoadFromFile(FLogDirectory + cbbLogFiles.Text,
        TEncoding.UTF8);
    finally
      mmoLog.Lines.EndUpdate;
    end;
  end;
end;

procedure TfrmLog.cbbLogFilesChange(Sender: TObject);
begin
  UpdateText;
end;

procedure TfrmLog.cbbLogFilesDropDown(Sender: TObject);
begin
  UpdateFileList;
end;

procedure TfrmLog.tmrCheckFileTimer(Sender: TObject);
var
  LOldPos: Integer;
begin
  if cbbLogFiles.Text = '' then
    Exit;

  if not FileExists(FLogDirectory + cbbLogFiles.Text) then
    Exit;

  if TFile.GetLastWriteTime(FLogDirectory + cbbLogFiles.Text) <= FLogLastWriteTime
  then
    Exit;

  LOldPos := mmoLog.SelStart;
  UpdateText;
  mmoLog.SelStart := LOldPos;
  mmoLog.Perform(EM_SCROLLCARET, 0, 0);
  mmoLog.SetFocus;
end;

end.
