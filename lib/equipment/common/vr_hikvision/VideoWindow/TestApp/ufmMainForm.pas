﻿unit ufmMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, uVideoWindow, uCHCNetSDK,
  Vcl.ExtCtrls, Vcl.AppEvnts, Vcl.ComCtrls;

type
  TfrmMainForm = class(TForm)
    appev1: TApplicationEvents;
    pnlVideo: TPanel;
    pnlBottm: TPanel;
    btnPlayStop: TButton;
    lbledtAddress: TLabeledEdit;
    lbledtPort: TLabeledEdit;
    lbledtUser: TLabeledEdit;
    lbledtPassword: TLabeledEdit;
    lbledtChannel: TLabeledEdit;
    btnSetOverlayText: TButton;
    mmoText: TMemo;
    chkPrintText: TCheckBox;
    chkVisible: TCheckBox;
    btnCreateViideoWindow: TButton;
    chkBuiltIn: TCheckBox;
    trckbrBrightness: TTrackBar;
    trckbrTransparency: TTrackBar;
    lblBrightness: TLabel;
    lblTransparency: TLabel;
    pgcPages: TPageControl;
    ts1: TTabSheet;
    ts2: TTabSheet;
    procedure appev1Idle(Sender: TObject; var Done: Boolean);
    procedure btnCreateViideoWindowClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnPlayStopClick(Sender: TObject);
    procedure btnSetOverlayTextClick(Sender: TObject);
    procedure chkPrintTextClick(Sender: TObject);
    procedure chkVisibleClick(Sender: TObject);
    procedure trckbrTransparencyChange(Sender: TObject);
    procedure trckbrBrightnessChange(Sender: TObject);
  private
    FLibHandle: THandle;
//    FUserID: Integer;
    FVideoWindow: TVideoWindow;
    FSDKInited: Boolean;
  private
    procedure Play;
    procedure Stop;
  public
    { Public declarations }
  end;

var
  frmMainForm: TfrmMainForm;

implementation

uses uHikvisionErrors;

function GetModuleFileNameStr: string;
var
  Buffer: array [0 .. MAX_PATH] of Char;
begin
  FillChar(Buffer, MAX_PATH, #0);
  GetModuleFileName(hInstance, Buffer, MAX_PATH);
  Result := Buffer;
end;

function GetModuleDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFileDir(GetModuleFileNameStr));
end;

{$R *.dfm}

procedure TfrmMainForm.appev1Idle(Sender: TObject; var Done: Boolean);
begin
  btnPlayStop.Enabled := Assigned(FVideoWindow);
  btnSetOverlayText.Enabled := Assigned(FVideoWindow);
  btnCreateViideoWindow.Enabled := not Assigned(FVideoWindow);

  if not Assigned(FVideoWindow) then
    Exit;

  if FVideoWindow.IsPlaying then
    btnPlayStop.Caption := 'Stop'
  else
    btnPlayStop.Caption := 'Play';
end;

procedure TfrmMainForm.btnCreateViideoWindowClick(Sender: TObject);
begin
  pnlVideo.Font.Size := 12;
  if chkBuiltIn.Checked then
    FVideoWindow := TVideoWindow.Create(pnlVideo)
  else
    FVideoWindow := TVideoWindow.Create(nil);
  FVideoWindow.Align := alClient;
  FVideoWindow.Enabled := True;
  FVideoWindow.TextPanel.Text := mmoText.Text;
  FVideoWindow.TextPanel.Used := chkPrintText.Checked;
  FVideoWindow.CaptureDir := 'D:\Temp';
  FVideoWindow.Show;

  trckbrBrightness.Position := FVideoWindow.TextPanel.Brightness;
  trckbrTransparency.Position := FVideoWindow.TextPanel.Transparency;
end;

procedure TfrmMainForm.FormDestroy(Sender: TObject);
begin
  if FSDKInited then
    NET_DVR_Cleanup;
  FreeAndNil(FVideoWindow);
  FreeLib(FLibHandle);
end;

procedure TfrmMainForm.Play;
var
  LDeviceInfo: NET_DVR_DEVICEINFO_V30;
begin
  if not Assigned(FVideoWindow) then
    Exit;
  Stop;

  FVideoWindow.Channel := StrToInt(lbledtChannel.Text);

  if not FSDKInited then
  begin
    FSDKInited := NET_DVR_Init;
    if not FSDKInited then
      raise Exception.Create('NET_DVR_Init error!');
  end;

  ZeroMemory(@LDeviceInfo, SizeOf(LDeviceInfo));
  FVideoWindow.UserID := NET_DVR_Login_V30
    (PAnsiChar(AnsiString(lbledtAddress.Text)), StrToInt(lbledtPort.Text),
    PAnsiChar(AnsiString(lbledtUser.Text)),
    PAnsiChar(AnsiString(lbledtPassword.Text)), LDeviceInfo);
  if FVideoWindow.UserID < 0 then
    RaiseLastHVError;

  FVideoWindow.PlayLiveVideo;
end;

procedure TfrmMainForm.Stop;
begin
  if Assigned(FVideoWindow) then
  begin
    FVideoWindow.StopLiveVideo;
    FVideoWindow.Invalidate;
  end;
end;

procedure TfrmMainForm.FormCreate(Sender: TObject);
begin
  FSDKInited := False;
  LoadLib(FLibHandle, GetModuleDirectory);
end;

procedure TfrmMainForm.btnPlayStopClick(Sender: TObject);
begin
  if not Assigned(FVideoWindow) then
    Exit;

  if FVideoWindow.IsPlaying then
    Stop
  else
    Play;
end;

procedure TfrmMainForm.btnSetOverlayTextClick(Sender: TObject);
begin
  if Assigned(FVideoWindow) then
  begin
    FVideoWindow.TextPanel.Text := mmoText.Text;
    FVideoWindow.TextPanel.Used := chkPrintText.Checked;
  end;
end;

procedure TfrmMainForm.chkPrintTextClick(Sender: TObject);
begin
  if Assigned(FVideoWindow) then
    FVideoWindow.TextPanel.Used := chkPrintText.Checked;
end;

procedure TfrmMainForm.chkVisibleClick(Sender: TObject);
begin
  if Assigned(FVideoWindow) then
    FVideoWindow.Visible := chkVisible.Checked;
end;

procedure TfrmMainForm.trckbrTransparencyChange(Sender: TObject);
begin
  if Assigned(FVideoWindow) then
    FVideoWindow.TextPanel.Transparency := trckbrTransparency.Position;
end;

procedure TfrmMainForm.trckbrBrightnessChange(Sender: TObject);
begin
  if Assigned(FVideoWindow) then
    FVideoWindow.TextPanel.Brightness := trckbrBrightness.Position;
end;

end.
