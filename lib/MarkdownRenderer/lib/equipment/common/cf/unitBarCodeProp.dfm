object frBarCodeProp: TfrBarCodeProp
  Left = 369
  Top = 274
  Hint = #1057#1074#1086#1081#1089#1090#1074#1072' '#1096#1090#1088#1080#1093#1082#1086#1076#1072
  ClientHeight = 302
  ClientWidth = 341
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 146
    Top = 9
    Width = 25
    Height = 13
    Alignment = taRightJustify
    Caption = #1058#1080#1087' :'
  end
  object Label2: TLabel
    Left = 146
    Top = 33
    Width = 25
    Height = 13
    Alignment = taRightJustify
    Caption = #1050#1086#1076' :'
  end
  object Label3: TLabel
    Left = 73
    Top = 57
    Width = 98
    Height = 13
    Alignment = taRightJustify
    Caption = #1059#1079#1082#1080#1081' '#1082' '#1096#1080#1088#1086#1082#1086#1084#1091':'
  end
  object Label4: TLabel
    Left = 84
    Top = 81
    Width = 87
    Height = 13
    Alignment = taRightJustify
    Caption = #1064#1090#1088#1080#1093' '#1082' '#1087#1088#1086#1073#1077#1083#1091':'
  end
  object Label5: TLabel
    Left = 90
    Top = 105
    Width = 81
    Height = 13
    Alignment = taRightJustify
    Caption = #1064#1080#1088#1080#1085#1072' '#1096#1090#1088#1080#1093#1072':'
  end
  object Label6: TLabel
    Left = 49
    Top = 129
    Width = 122
    Height = 13
    Alignment = taRightJustify
    Caption = #1055#1088#1077#1076#1098#1103#1074#1080#1090#1077#1083#1100' '#1096#1090#1088#1080#1093#1086#1074':'
  end
  object Label7: TLabel
    Left = 69
    Top = 154
    Width = 102
    Height = 13
    Alignment = taRightJustify
    Caption = #1055#1086#1076#1085#1072#1073#1086#1088' Code 128:'
  end
  object Label8: TLabel
    Left = 84
    Top = 178
    Width = 87
    Height = 13
    Alignment = taRightJustify
    Caption = #1055#1086#1082#1072#1079#1099#1074#1072#1090#1100' '#1082#1086#1076':'
  end
  object Label9: TLabel
    Left = 4
    Top = 202
    Width = 167
    Height = 13
    Alignment = taRightJustify
    Caption = #1055#1086#1082#1072#1079#1099#1074#1072#1090#1100' '#1086#1093#1088#1072#1085#1085#1099#1077' '#1089#1080#1084#1074#1086#1083#1099':'
  end
  object Label10: TLabel
    Left = 59
    Top = 226
    Width = 112
    Height = 13
    Alignment = taRightJustify
    Caption = #1044#1086#1087#1086#1083#1085#1080#1090#1077#1083#1100#1085#1099#1081' '#1082#1086#1076':'
  end
  object Label11: TLabel
    Left = 32
    Top = 250
    Width = 139
    Height = 13
    Alignment = taRightJustify
    Caption = #1042#1099#1089#1086#1082#1080#1077' '#1086#1093#1088#1072#1085#1085#1099#1077' '#1096#1090#1088#1080#1093#1080':'
  end
  object Label12: TLabel
    Left = 1
    Top = 274
    Width = 170
    Height = 13
    Alignment = taRightJustify
    Caption = #1044#1086#1073#1072#1074#1083#1103#1090#1100' '#1082#1086#1085#1090#1088#1086#1083#1100#1085#1099#1081' '#1089#1080#1084#1074#1086#1083':'
  end
  object cbType: TComboBox
    Left = 180
    Top = 4
    Width = 109
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
    Items.Strings = (
      'UPC A'
      'UPC E'
      'EAN 8'
      'EAN 13'
      'Interleaved 2 of 5'
      'Codabar'
      'Code 11'
      'Code 39'
      'Code 93'
      'Code 128')
  end
  object cbCode: TEdit
    Left = 180
    Top = 29
    Width = 153
    Height = 21
    TabOrder = 1
  end
  object chbShowGuardChars: TCheckBox
    Left = 180
    Top = 200
    Width = 17
    Height = 17
    TabOrder = 2
  end
  object chbTallGuardBars: TCheckBox
    Left = 180
    Top = 249
    Width = 17
    Height = 17
    TabOrder = 3
  end
  object chbShowCode: TCheckBox
    Left = 180
    Top = 176
    Width = 17
    Height = 17
    TabOrder = 4
  end
  object chbAddCheckChar: TCheckBox
    Left = 180
    Top = 274
    Width = 17
    Height = 17
    TabOrder = 5
  end
  object edBarNarrowToWideRatio: TEdit
    Left = 180
    Top = 53
    Width = 41
    Height = 21
    TabOrder = 6
  end
  object edBarToSpaceRatio: TEdit
    Left = 180
    Top = 78
    Width = 41
    Height = 21
    TabOrder = 7
  end
  object chbBearerBars: TCheckBox
    Left = 180
    Top = 127
    Width = 17
    Height = 17
    Caption = 'chbBearerBars'
    TabOrder = 8
  end
  object edSupplementalCode: TEdit
    Left = 180
    Top = 225
    Width = 109
    Height = 21
    TabOrder = 9
  end
  object edBarWidth: TEdit
    Left = 180
    Top = 102
    Width = 41
    Height = 21
    TabOrder = 10
  end
  object cbCode128Subset: TComboBox
    Left = 180
    Top = 151
    Width = 109
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 11
    Items.Strings = (
      'Code A'
      'Code B')
  end
end
