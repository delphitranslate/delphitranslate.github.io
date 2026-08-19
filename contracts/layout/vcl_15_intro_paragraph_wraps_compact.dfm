object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 220
  ClientWidth = 880
  object lblIntro1: TLabel
    WordWrap = False
    Left = 70
    Top = 65
    Width = 760
    Height = 24
    Font.Height = -13
    Caption = 'Select a folder for each slot. Dates use month/day format, for example 04/27.'
  end
  object lblIntro2: TLabel
    WordWrap = False
    Left = 70
    Top = 95
    Width = 760
    Height = 24
    Font.Height = -13
    Caption = 'Slot 1 is the default fallback folder. Slots 2-7 override it during their date windows.'
  end
end
