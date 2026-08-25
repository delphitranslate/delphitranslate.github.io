object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 400
  ClientWidth = 974
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object lblSelDir: TLabel
    Left = 176
    Top = 85
    Width = 577
    Height = 60
    Caption = 'Click the button for any directory box and add the dates.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblDir2: TLabel
    Left = 176
    Top = 160
    Width = 571
    Height = 60
    Caption = 'Random music needs a default directory to be configured.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblAnchor: TLabel
    Left = 176
    Top = 240
    Width = 200
    Height = 17
    Caption = 'Default music directory'
  end
  object btnDirectory1: TButton
    Left = 618
    Top = 270
    Width = 256
    Height = 40
    Caption = 'Select directory one'
  end
  object btnDirectory2: TButton
    Left = 618
    Top = 330
    Width = 256
    Height = 40
    Caption = 'Select directory two'
  end
end
