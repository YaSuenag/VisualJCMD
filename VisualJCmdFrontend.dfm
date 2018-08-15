object Main: TMain
  Left = 0
  Top = 0
  Anchors = []
  Caption = 'VisualJCMD'
  ClientHeight = 462
  ClientWidth = 668
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    668
    462)
  PixelsPerInch = 96
  TextHeight = 13
  object VMList: TStringGrid
    Left = 8
    Top = 8
    Width = 265
    Height = 446
    Anchors = [akLeft, akTop, akBottom]
    ColCount = 2
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
    TabOrder = 0
    OnSelectCell = VMListSelectCell
    ColWidths = (
      64
      162)
  end
  object PerfCounterTree: TTreeView
    Left = 279
    Top = 8
    Width = 381
    Height = 201
    Anchors = [akLeft, akTop, akRight]
    Indent = 19
    TabOrder = 1
  end
  object DCmdList: TStringGrid
    Left = 279
    Top = 215
    Width = 381
    Height = 239
    Hint = 'double-click to invoke jcmd'
    Anchors = [akLeft, akTop, akRight, akBottom]
    ColCount = 3
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    OnDblClick = DCmdListDblClick
    ColWidths = (
      96
      69
      187)
  end
end
