object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 620
  ClientWidth = 700
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object btnClearOtherDates: TButton
    Left = 182
    Top = 502
    Width = 81
    Height = 42
    Caption = 'Reset Funeral Date Fields'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblTimes: TLabel
    Left = 344
    Top = 539
    Width = 52
    Height = 30
    AutoSize = False
    Caption = 'Start/End Times:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object edtStart: TEdit
    Left = 404
    Top = 536
    Width = 100
    Height = 23
  end
end
