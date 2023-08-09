object fmXmlDialog: TfmXmlDialog
  Left = 0
  Top = 0
  Caption = #1056#1077#1076#1072#1082#1090#1080#1088#1086#1074#1072#1085#1080#1077' '#1074#1093#1086#1076#1085#1086#1075#1086' Xml'
  ClientHeight = 485
  ClientWidth = 1023
  Color = clBtnFace
  DefaultMonitor = dmPrimary
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 444
    Width = 1023
    Height = 41
    Align = alBottom
    TabOrder = 0
    ExplicitWidth = 745
    DesignSize = (
      1023
      41)
    object btnOK: TButton
      Left = 929
      Top = 7
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'OK'
      ModalResult = 1
      TabOrder = 0
      ExplicitLeft = 651
    end
  end
  object mXml: TMemo
    Left = 0
    Top = 0
    Width = 1023
    Height = 444
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 1
    ExplicitWidth = 745
  end
end
