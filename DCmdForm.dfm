object DCmdDialog: TDCmdDialog
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 463
  ClientWidth = 489
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    489
    463)
  PixelsPerInch = 96
  TextHeight = 13
  object Description: TLabel
    Left = 8
    Top = 8
    Width = 473
    Height = 33
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Description'
    ExplicitWidth = 443
  end
  object OptionDescription: TLabel
    Left = 8
    Top = 72
    Width = 443
    Height = 33
    Caption = 'Option Description'
  end
  object ConfigurationTable: TStringGrid
    Left = 8
    Top = 120
    Width = 473
    Height = 129
    Hint = 'double-click to configure argument/option'
    Anchors = [akLeft, akTop, akRight]
    ColCount = 2
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing]
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    OnSelectCell = ConfigurationTableSelectCell
    ColWidths = (
      133
      278)
  end
  object InvokeButton: TButton
    Left = 200
    Top = 255
    Width = 75
    Height = 25
    Caption = 'Invoke'
    TabOrder = 1
    OnClick = InvokeButtonClick
  end
  object Result: TMemo
    Left = 8
    Top = 288
    Width = 473
    Height = 167
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
  end
end
