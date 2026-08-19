object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 220
  ClientWidth = 460
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object btnRecalc: TButton
    Left = 24
    Top = 24
    Width = 153
    Height = 57
    Caption = 'Recalculate Dates for Upcoming Year'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object pnlMedia: TPanel
    Left = 24
    Top = 110
    Width = 300
    Height = 90
    object lblMedia: TLabel
      Left = 13
      Top = 3
      Width = 76
      Height = 17
      Caption = 'Media Player'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
end
